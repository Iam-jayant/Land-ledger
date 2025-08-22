// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title EscrowManager
 * @dev Advanced escrow system for secure property transactions
 * @notice Handles multi-party escrow with automatic release mechanisms
 */
contract EscrowManager is AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant LAND_INSPECTOR_ROLE = keccak256("LAND_INSPECTOR_ROLE");
    bytes32 public constant ESCROW_AGENT_ROLE = keccak256("ESCROW_AGENT_ROLE");

    Counters.Counter private _escrowIds;

    // Custom errors
    error EscrowNotFound(uint256 escrowId);
    error UnauthorizedEscrowAccess(address caller, uint256 escrowId);
    error InvalidEscrowStatus(uint256 escrowId, string currentStatus);
    error InsufficientEscrowAmount(uint256 escrowId, uint256 required, uint256 available);
    error EscrowExpired(uint256 escrowId, uint256 expiredAt);
    error InvalidParticipant(address participant);
    error EscrowAlreadyResolved(uint256 escrowId);

    enum EscrowStatus {
        Created,
        Funded,
        SellerApproved,
        InspectorApproved,
        Released,
        Refunded,
        Disputed,
        Expired
    }

    struct Escrow {
        uint256 id;
        uint256 propertyId;
        address buyer;
        address seller;
        address inspector;
        uint256 amount;
        uint256 createdAt;
        uint256 expiresAt;
        EscrowStatus status;
        bool sellerApproval;
        bool inspectorApproval;
        bool buyerConfirmation;
        string terms;
        uint256 releasedAt;
        address releasedBy;
    }

    struct DisputeInfo {
        uint256 escrowId;
        address initiator;
        string reason;
        uint256 createdAt;
        bool resolved;
        address resolver;
        uint256 resolvedAt;
        string resolution;
    }

    // Mappings
    mapping(uint256 => Escrow) public escrows;
    mapping(uint256 => DisputeInfo) public disputes;
    mapping(address => uint256[]) public userEscrows;
    mapping(uint256 => bool) public hasDispute;

    // Constants
    uint256 public constant ESCROW_TIMEOUT = 30 days;
    uint256 public constant DISPUTE_TIMEOUT = 7 days;

    // Events
    event EscrowCreated(
        uint256 indexed escrowId,
        uint256 indexed propertyId,
        address indexed buyer,
        address seller,
        uint256 amount
    );
    event EscrowFunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event SellerApprovalGiven(uint256 indexed escrowId, address indexed seller);
    event InspectorApprovalGiven(uint256 indexed escrowId, address indexed inspector);
    event EscrowReleased(uint256 indexed escrowId, address indexed releasedBy, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event DisputeRaised(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed escrowId, address indexed resolver, string resolution);
    event EscrowExpiredEvent(uint256 indexed escrowId, uint256 expiredAt);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LAND_INSPECTOR_ROLE, msg.sender);
        _grantRole(ESCROW_AGENT_ROLE, msg.sender);
    }

    modifier escrowExists(uint256 escrowId) {
        if (escrows[escrowId].id == 0) {
            revert EscrowNotFound(escrowId);
        }
        _;
    }

    modifier onlyEscrowParticipant(uint256 escrowId) {
        Escrow memory escrow = escrows[escrowId];
        if (msg.sender != escrow.buyer && 
            msg.sender != escrow.seller && 
            msg.sender != escrow.inspector &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedEscrowAccess(msg.sender, escrowId);
        }
        _;
    }

    modifier notExpired(uint256 escrowId) {
        if (block.timestamp > escrows[escrowId].expiresAt) {
            revert EscrowExpired(escrowId, escrows[escrowId].expiresAt);
        }
        _;
    }

    /**
     * @dev Create a new escrow for property transaction
     */
    function createEscrow(
        uint256 _propertyId,
        address _buyer,
        address _seller,
        address _inspector,
        string memory _terms
    ) external onlyRole(ESCROW_AGENT_ROLE) whenNotPaused returns (uint256) {
        if (_buyer == address(0) || _seller == address(0) || _inspector == address(0)) {
            revert InvalidParticipant(address(0));
        }

        _escrowIds.increment();
        uint256 newEscrowId = _escrowIds.current();

        escrows[newEscrowId] = Escrow({
            id: newEscrowId,
            propertyId: _propertyId,
            buyer: _buyer,
            seller: _seller,
            inspector: _inspector,
            amount: 0,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + ESCROW_TIMEOUT,
            status: EscrowStatus.Created,
            sellerApproval: false,
            inspectorApproval: false,
            buyerConfirmation: false,
            terms: _terms,
            releasedAt: 0,
            releasedBy: address(0)
        });

        // Track escrows for each participant
        userEscrows[_buyer].push(newEscrowId);
        userEscrows[_seller].push(newEscrowId);
        userEscrows[_inspector].push(newEscrowId);

        emit EscrowCreated(newEscrowId, _propertyId, _buyer, _seller, 0);
        return newEscrowId;
    }

    /**
     * @dev Fund the escrow with payment
     */
    function fundEscrow(uint256 escrowId) 
        external 
        payable 
        escrowExists(escrowId) 
        nonReentrant 
        notExpired(escrowId)
        whenNotPaused 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.buyer) {
            revert UnauthorizedEscrowAccess(msg.sender, escrowId);
        }
        if (escrow.status != EscrowStatus.Created) {
            revert InvalidEscrowStatus(escrowId, "Not in Created status");
        }
        if (msg.value == 0) {
            revert InsufficientEscrowAmount(escrowId, 1, 0);
        }

        escrow.amount = msg.value;
        escrow.status = EscrowStatus.Funded;
        escrow.buyerConfirmation = true;

        emit EscrowFunded(escrowId, msg.sender, msg.value);
    }

    /**
     * @dev Seller approves the transaction
     */
    function approveAsSeller(uint256 escrowId) 
        external 
        escrowExists(escrowId) 
        notExpired(escrowId)
        whenNotPaused 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.seller) {
            revert UnauthorizedEscrowAccess(msg.sender, escrowId);
        }
        if (escrow.status != EscrowStatus.Funded) {
            revert InvalidEscrowStatus(escrowId, "Not funded");
        }

        escrow.sellerApproval = true;
        escrow.status = EscrowStatus.SellerApproved;

        emit SellerApprovalGiven(escrowId, msg.sender);

        // Check if ready for release
        _checkAndRelease(escrowId);
    }

    /**
     * @dev Inspector approves the transaction
     */
    function approveAsInspector(uint256 escrowId) 
        external 
        escrowExists(escrowId) 
        onlyRole(LAND_INSPECTOR_ROLE)
        notExpired(escrowId)
        whenNotPaused 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.inspector) {
            revert UnauthorizedEscrowAccess(msg.sender, escrowId);
        }
        if (escrow.status == EscrowStatus.Created) {
            revert InvalidEscrowStatus(escrowId, "Not funded");
        }

        escrow.inspectorApproval = true;
        if (escrow.status == EscrowStatus.SellerApproved) {
            escrow.status = EscrowStatus.InspectorApproved;
        }

        emit InspectorApprovalGiven(escrowId, msg.sender);

        // Check if ready for release
        _checkAndRelease(escrowId);
    }

    /**
     * @dev Internal function to check if escrow can be released
     */
    function _checkAndRelease(uint256 escrowId) internal {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.sellerApproval && escrow.inspectorApproval && escrow.buyerConfirmation) {
            _releaseEscrow(escrowId);
        }
    }

    /**
     * @dev Release escrow funds to seller
     */
    function _releaseEscrow(uint256 escrowId) internal {
        Escrow storage escrow = escrows[escrowId];
        
        if (escrow.status == EscrowStatus.Released || escrow.status == EscrowStatus.Refunded) {
            revert EscrowAlreadyResolved(escrowId);
        }

        uint256 amount = escrow.amount;
        escrow.status = EscrowStatus.Released;
        escrow.releasedAt = block.timestamp;
        escrow.releasedBy = msg.sender;

        // Transfer funds to seller
        payable(escrow.seller).transfer(amount);

        emit EscrowReleased(escrowId, msg.sender, amount);
    }

    /**
     * @dev Manually release escrow (admin only)
     */
    function manualRelease(uint256 escrowId) 
        external 
        escrowExists(escrowId) 
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant 
        whenNotPaused 
    {
        _releaseEscrow(escrowId);
    }

    /**
     * @dev Refund escrow to buyer
     */
    function refundEscrow(uint256 escrowId, string memory reason) 
        external 
        escrowExists(escrowId) 
        nonReentrant 
        whenNotPaused 
    {
        Escrow storage escrow = escrows[escrowId];
        
        // Only admin, inspector, or if expired
        bool canRefund = hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                        (msg.sender == escrow.inspector && hasRole(LAND_INSPECTOR_ROLE, msg.sender)) ||
                        block.timestamp > escrow.expiresAt;
        
        if (!canRefund) {
            revert UnauthorizedEscrowAccess(msg.sender, escrowId);
        }
        
        if (escrow.status == EscrowStatus.Released || escrow.status == EscrowStatus.Refunded) {
            revert EscrowAlreadyResolved(escrowId);
        }

        uint256 amount = escrow.amount;
        escrow.status = EscrowStatus.Refunded;
        escrow.releasedAt = block.timestamp;
        escrow.releasedBy = msg.sender;

        // Transfer funds back to buyer
        payable(escrow.buyer).transfer(amount);

        emit EscrowRefunded(escrowId, escrow.buyer, amount);
    }

    /**
     * @dev Raise a dispute
     */
    function raiseDispute(uint256 escrowId, string memory reason) 
        external 
        escrowExists(escrowId) 
        onlyEscrowParticipant(escrowId)
        whenNotPaused 
    {
        if (hasDispute[escrowId]) {
            revert InvalidEscrowStatus(escrowId, "Dispute already exists");
        }

        Escrow storage escrow = escrows[escrowId];
        escrow.status = EscrowStatus.Disputed;
        hasDispute[escrowId] = true;

        disputes[escrowId] = DisputeInfo({
            escrowId: escrowId,
            initiator: msg.sender,
            reason: reason,
            createdAt: block.timestamp,
            resolved: false,
            resolver: address(0),
            resolvedAt: 0,
            resolution: ""
        });

        emit DisputeRaised(escrowId, msg.sender, reason);
    }

    /**
     * @dev Resolve a dispute
     */
    function resolveDispute(
        uint256 escrowId, 
        bool releaseToSeller, 
        string memory resolution
    ) external escrowExists(escrowId) onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (!hasDispute[escrowId]) {
            revert InvalidEscrowStatus(escrowId, "No dispute exists");
        }

        DisputeInfo storage dispute = disputes[escrowId];
        dispute.resolved = true;
        dispute.resolver = msg.sender;
        dispute.resolvedAt = block.timestamp;
        dispute.resolution = resolution;

        if (releaseToSeller) {
            _releaseEscrow(escrowId);
        } else {
            this.refundEscrow(escrowId, "Dispute resolved in favor of buyer");
        }

        emit DisputeResolved(escrowId, msg.sender, resolution);
    }

    /**
     * @dev Handle expired escrows
     */
    function handleExpiredEscrow(uint256 escrowId) 
        external 
        escrowExists(escrowId) 
        whenNotPaused 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (block.timestamp <= escrow.expiresAt) {
            revert InvalidEscrowStatus(escrowId, "Not expired yet");
        }
        if (escrow.status == EscrowStatus.Released || escrow.status == EscrowStatus.Refunded) {
            revert EscrowAlreadyResolved(escrowId);
        }

        escrow.status = EscrowStatus.Expired;
        
        // Auto-refund if funded
        if (escrow.amount > 0) {
            payable(escrow.buyer).transfer(escrow.amount);
            emit EscrowRefunded(escrowId, escrow.buyer, escrow.amount);
        }

        emit EscrowExpiredEvent(escrowId, block.timestamp);
    }

    // View Functions
    function getEscrow(uint256 escrowId) 
        external 
        view 
        escrowExists(escrowId) 
        returns (Escrow memory) 
    {
        return escrows[escrowId];
    }

    function getDispute(uint256 escrowId) 
        external 
        view 
        returns (DisputeInfo memory) 
    {
        return disputes[escrowId];
    }

    function getUserEscrows(address user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userEscrows[user];
    }

    function getEscrowStatus(uint256 escrowId) 
        external 
        view 
        escrowExists(escrowId) 
        returns (EscrowStatus) 
    {
        return escrows[escrowId].status;
    }

    function getTotalEscrows() external view returns (uint256) {
        return _escrowIds.current();
    }

    function isEscrowExpired(uint256 escrowId) 
        external 
        view 
        escrowExists(escrowId) 
        returns (bool) 
    {
        return block.timestamp > escrows[escrowId].expiresAt;
    }

    function getEscrowBalance(uint256 escrowId) 
        external 
        view 
        escrowExists(escrowId) 
        returns (uint256) 
    {
        return escrows[escrowId].amount;
    }

    // Emergency functions
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Emergency withdrawal (only for stuck funds)
    function emergencyWithdraw(uint256 escrowId) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        nonReentrant 
    {
        Escrow storage escrow = escrows[escrowId];
        require(
            escrow.status == EscrowStatus.Expired || 
            block.timestamp > escrow.expiresAt + 90 days,
            "Emergency withdrawal not allowed"
        );

        uint256 amount = escrow.amount;
        escrow.amount = 0;
        escrow.status = EscrowStatus.Refunded;

        payable(escrow.buyer).transfer(amount);
        emit EscrowRefunded(escrowId, escrow.buyer, amount);
    }
}
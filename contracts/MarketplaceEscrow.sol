// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/IMarketplaceEscrow.sol";
import "./interfaces/IPropertyToken.sol";
import "./interfaces/ICompliance.sol";

/**
 * @title MarketplaceEscrow
 * @dev Secure marketplace for property token trading with escrow functionality
 * Handles atomic swaps of tokens for payments with compliance checks
 */
contract MarketplaceEscrow is 
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IMarketplaceEscrow
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DISPUTE_RESOLVER_ROLE = keccak256("DISPUTE_RESOLVER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    // Counters
    CountersUpgradeable.Counter private _listingIdCounter;
    CountersUpgradeable.Counter private _escrowIdCounter;

    // Contract references
    IPropertyToken public propertyToken;
    ICompliance public compliance;

    // Storage
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => Escrow) private _escrows;
    mapping(address => uint256[]) private _ownerListings;
    mapping(address => uint256[]) private _buyerEscrows;
    mapping(address => uint256[]) private _sellerEscrows;
    uint256[] private _activeListings;
    uint256[] private _allListings;
    uint256[] private _allEscrows;

    // Fee configuration
    uint256 private _feePercentage; // Basis points (e.g., 250 = 2.5%)
    address private _feeRecipient;

    // Constants
    uint256 public constant MAX_FEE_PERCENTAGE = 1000; // 10% maximum fee
    uint256 public constant DEFAULT_ESCROW_DURATION = 30 days;
    uint256 public constant MAX_LISTING_DURATION = 365 days;

    // Statistics
    uint256 private _totalVolume;
    uint256 private _completedSales;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     */
    function initialize(
        address _admin,
        address _propertyToken,
        address _compliance,
        uint256 _initialFeePercentage,
        address _initialFeeRecipient
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(DISPUTE_RESOLVER_ROLE, _admin);
        _grantRole(FEE_MANAGER_ROLE, _admin);

        propertyToken = IPropertyToken(_propertyToken);
        compliance = ICompliance(_compliance);

        require(_initialFeePercentage <= MAX_FEE_PERCENTAGE, "MarketplaceEscrow: fee too high");
        _feePercentage = _initialFeePercentage;
        _feeRecipient = _initialFeeRecipient;

        // Start counters from 1
        _listingIdCounter.increment();
        _escrowIdCounter.increment();
    }

    /**
     * @dev List a property for sale
     */
    function listProperty(
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationDays,
        string calldata _description
    ) external override whenNotPaused nonReentrant returns (uint256 listingId) {
        require(propertyToken.ownerOf(_tokenId) == msg.sender, "MarketplaceEscrow: not token owner");
        require(_price > 0, "MarketplaceEscrow: price must be greater than zero");
        require(_expirationDays > 0 && _expirationDays <= MAX_LISTING_DURATION / 1 days, "MarketplaceEscrow: invalid expiration");
        require(propertyToken.isApprovedForAll(msg.sender, address(this)) || 
                propertyToken.getApproved(_tokenId) == address(this), "MarketplaceEscrow: not approved");

        listingId = _listingIdCounter.current();
        _listingIdCounter.increment();

        uint256 expirationTimestamp = block.timestamp + (_expirationDays * 1 days);

        _listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingTimestamp: block.timestamp,
            expirationTimestamp: expirationTimestamp,
            status: ListingStatus.Active,
            description: _description,
            isVerified: propertyToken.isPropertyVerified(_tokenId)
        });

        _ownerListings[msg.sender].push(listingId);
        _activeListings.push(listingId);
        _allListings.push(listingId);

        emit PropertyListed(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Remove a property listing
     */
    function delistProperty(uint256 _listingId) external override whenNotPaused {
        Listing storage listing = _listings[_listingId];
        require(listing.seller == msg.sender, "MarketplaceEscrow: not listing owner");
        require(listing.status == ListingStatus.Active, "MarketplaceEscrow: listing not active");

        listing.status = ListingStatus.Cancelled;
        _removeFromActiveListings(_listingId);

        emit PropertyDelisted(_listingId, msg.sender);
    }

    /**
     * @dev Update listing price
     */
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external override whenNotPaused {
        Listing storage listing = _listings[_listingId];
        require(listing.seller == msg.sender, "MarketplaceEscrow: not listing owner");
        require(listing.status == ListingStatus.Active, "MarketplaceEscrow: listing not active");
        require(_newPrice > 0, "MarketplaceEscrow: price must be greater than zero");

        listing.price = _newPrice;
    }

    /**
     * @dev Extend listing expiration
     */
    function extendListing(uint256 _listingId, uint256 _additionalDays) external override whenNotPaused {
        Listing storage listing = _listings[_listingId];
        require(listing.seller == msg.sender, "MarketplaceEscrow: not listing owner");
        require(listing.status == ListingStatus.Active, "MarketplaceEscrow: listing not active");
        require(_additionalDays > 0, "MarketplaceEscrow: additional days must be greater than zero");

        listing.expirationTimestamp += (_additionalDays * 1 days);
    }

    /**
     * @dev Initiate a purchase with escrow
     */
    function initiatePurchase(
        uint256 _listingId,
        string calldata _terms
    ) external payable override whenNotPaused nonReentrant returns (uint256 escrowId) {
        Listing storage listing = _listings[_listingId];
        require(listing.status == ListingStatus.Active, "MarketplaceEscrow: listing not active");
        require(block.timestamp < listing.expirationTimestamp, "MarketplaceEscrow: listing expired");
        require(msg.sender != listing.seller, "MarketplaceEscrow: cannot buy own property");
        require(msg.value >= listing.price, "MarketplaceEscrow: insufficient payment");

        // Check compliance
        (bool canTransfer, string memory reason) = compliance.canTransferToken(listing.seller, msg.sender, listing.tokenId);
        require(canTransfer, string(abi.encodePacked("MarketplaceEscrow: ", reason)));

        escrowId = _escrowIdCounter.current();
        _escrowIdCounter.increment();

        _escrows[escrowId] = Escrow({
            escrowId: escrowId,
            listingId: _listingId,
            tokenId: listing.tokenId,
            buyer: msg.sender,
            seller: listing.seller,
            price: listing.price,
            depositedAmount: msg.value,
            creationTimestamp: block.timestamp,
            completionDeadline: block.timestamp + DEFAULT_ESCROW_DURATION,
            status: EscrowStatus.FundsDeposited,
            terms: _terms,
            disputeRaised: false,
            disputeInitiator: address(0),
            disputeReason: ""
        });

        _buyerEscrows[msg.sender].push(escrowId);
        _sellerEscrows[listing.seller].push(escrowId);
        _allEscrows.push(escrowId);

        // Mark listing as sold
        listing.status = ListingStatus.Sold;
        _removeFromActiveListings(_listingId);

        emit PurchaseInitiated(escrowId, _listingId, msg.sender, listing.price);
        emit FundsDeposited(escrowId, msg.sender, msg.value);
    }

    /**
     * @dev Deposit additional funds to escrow
     */
    function depositFunds(uint256 _escrowId) external payable override whenNotPaused {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.buyer == msg.sender, "MarketplaceEscrow: not escrow buyer");
        require(escrow.status == EscrowStatus.FundsDeposited, "MarketplaceEscrow: invalid escrow status");
        require(msg.value > 0, "MarketplaceEscrow: must deposit funds");

        escrow.depositedAmount += msg.value;

        emit FundsDeposited(_escrowId, msg.sender, msg.value);
    }

    /**
     * @dev Complete the purchase (atomic swap)
     */
    function completePurchase(uint256 _escrowId) external override whenNotPaused nonReentrant {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.status == EscrowStatus.FundsDeposited, "MarketplaceEscrow: invalid escrow status");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "MarketplaceEscrow: not authorized");
        require(block.timestamp <= escrow.completionDeadline, "MarketplaceEscrow: escrow expired");
        require(escrow.depositedAmount >= escrow.price, "MarketplaceEscrow: insufficient funds");

        // Final compliance check
        require(compliance.validateTokenTransfer(escrow.seller, escrow.buyer, escrow.tokenId), 
                "MarketplaceEscrow: transfer not compliant");

        // Calculate fees
        uint256 fee = calculateFee(escrow.price);
        uint256 sellerAmount = escrow.price - fee;
        uint256 refundAmount = escrow.depositedAmount - escrow.price;

        // Transfer the property token
        propertyToken.safeTransferFrom(escrow.seller, escrow.buyer, escrow.tokenId);

        // Transfer payments
        if (sellerAmount > 0) {
            payable(escrow.seller).transfer(sellerAmount);
        }
        if (fee > 0 && _feeRecipient != address(0)) {
            payable(_feeRecipient).transfer(fee);
        }
        if (refundAmount > 0) {
            payable(escrow.buyer).transfer(refundAmount);
        }

        // Update escrow status
        escrow.status = EscrowStatus.Completed;

        // Update statistics
        _totalVolume += escrow.price;
        _completedSales++;

        emit EscrowCompleted(_escrowId, escrow.tokenId, escrow.buyer, escrow.seller, escrow.price);
    }

    /**
     * @dev Cancel a purchase
     */
    function cancelPurchase(uint256 _escrowId, string calldata _reason) external override whenNotPaused nonReentrant {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.status == EscrowStatus.FundsDeposited, "MarketplaceEscrow: invalid escrow status");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller || hasRole(ADMIN_ROLE, msg.sender), 
                "MarketplaceEscrow: not authorized");

        // Refund the buyer
        if (escrow.depositedAmount > 0) {
            payable(escrow.buyer).transfer(escrow.depositedAmount);
        }

        // Reactivate the listing
        Listing storage listing = _listings[escrow.listingId];
        if (listing.status == ListingStatus.Sold && block.timestamp < listing.expirationTimestamp) {
            listing.status = ListingStatus.Active;
            _activeListings.push(escrow.listingId);
        }

        escrow.status = EscrowStatus.Cancelled;

        emit EscrowCancelled(_escrowId, msg.sender, _reason);
    }

    /**
     * @dev Raise a dispute
     */
    function raiseDispute(uint256 _escrowId, string calldata _reason) external override whenNotPaused {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.status == EscrowStatus.FundsDeposited, "MarketplaceEscrow: invalid escrow status");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "MarketplaceEscrow: not authorized");
        require(!escrow.disputeRaised, "MarketplaceEscrow: dispute already raised");

        escrow.disputeRaised = true;
        escrow.disputeInitiator = msg.sender;
        escrow.disputeReason = _reason;
        escrow.status = EscrowStatus.Disputed;

        emit DisputeRaised(_escrowId, msg.sender, _reason);
    }

    /**
     * @dev Resolve a dispute
     */
    function resolveDispute(uint256 _escrowId, bool _buyerWins, string calldata _resolution) 
        external override onlyRole(DISPUTE_RESOLVER_ROLE) whenNotPaused nonReentrant {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.status == EscrowStatus.Disputed, "MarketplaceEscrow: not disputed");

        if (_buyerWins) {
            // Transfer token to buyer and refund any excess
            propertyToken.safeTransferFrom(escrow.seller, escrow.buyer, escrow.tokenId);
            
            uint256 fee = calculateFee(escrow.price);
            uint256 sellerAmount = escrow.price - fee;
            uint256 refundAmount = escrow.depositedAmount - escrow.price;

            if (sellerAmount > 0) {
                payable(escrow.seller).transfer(sellerAmount);
            }
            if (fee > 0 && _feeRecipient != address(0)) {
                payable(_feeRecipient).transfer(fee);
            }
            if (refundAmount > 0) {
                payable(escrow.buyer).transfer(refundAmount);
            }

            escrow.status = EscrowStatus.Completed;
            _totalVolume += escrow.price;
            _completedSales++;
        } else {
            // Refund buyer, seller keeps token
            if (escrow.depositedAmount > 0) {
                payable(escrow.buyer).transfer(escrow.depositedAmount);
            }

            // Reactivate listing if still valid
            Listing storage listing = _listings[escrow.listingId];
            if (block.timestamp < listing.expirationTimestamp) {
                listing.status = ListingStatus.Active;
                _activeListings.push(escrow.listingId);
            }

            escrow.status = EscrowStatus.Cancelled;
        }

        emit DisputeResolved(_escrowId, msg.sender, _buyerWins);
    }

    /**
     * @dev Get listing details
     */
    function getListing(uint256 _listingId) external view override returns (Listing memory) {
        return _listings[_listingId];
    }

    /**
     * @dev Get escrow details
     */
    function getEscrow(uint256 _escrowId) external view override returns (Escrow memory) {
        return _escrows[_escrowId];
    }

    /**
     * @dev Get active listings
     */
    function getActiveListings() external view override returns (uint256[] memory) {
        return _activeListings;
    }

    /**
     * @dev Get listings by owner
     */
    function getListingsByOwner(address _owner) external view override returns (uint256[] memory) {
        return _ownerListings[_owner];
    }

    /**
     * @dev Get escrows by buyer
     */
    function getEscrowsByBuyer(address _buyer) external view override returns (uint256[] memory) {
        return _buyerEscrows[_buyer];
    }

    /**
     * @dev Get escrows by seller
     */
    function getEscrowsBySeller(address _seller) external view override returns (uint256[] memory) {
        return _sellerEscrows[_seller];
    }

    /**
     * @dev Check if listing is active
     */
    function isListingActive(uint256 _listingId) external view override returns (bool) {
        Listing memory listing = _listings[_listingId];
        return listing.status == ListingStatus.Active && block.timestamp < listing.expirationTimestamp;
    }

    /**
     * @dev Check if escrow is active
     */
    function isEscrowActive(uint256 _escrowId) external view override returns (bool) {
        return _escrows[_escrowId].status == EscrowStatus.FundsDeposited;
    }

    /**
     * @dev Batch list properties
     */
    function batchListProperties(
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        uint256[] calldata _expirationDays,
        string[] calldata _descriptions
    ) external override returns (uint256[] memory listingIds) {
        require(_tokenIds.length == _prices.length && 
                _prices.length == _expirationDays.length && 
                _expirationDays.length == _descriptions.length, 
                "MarketplaceEscrow: arrays length mismatch");

        listingIds = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listingIds[i] = this.listProperty(_tokenIds[i], _prices[i], _expirationDays[i], _descriptions[i]);
        }
    }

    /**
     * @dev Batch delist properties
     */
    function batchDelistProperties(uint256[] calldata _listingIds) external override {
        for (uint256 i = 0; i < _listingIds.length; i++) {
            this.delistProperty(_listingIds[i]);
        }
    }

    /**
     * @dev Set fee percentage
     */
    function setFeePercentage(uint256 _newFeePercentage) external override onlyRole(FEE_MANAGER_ROLE) {
        require(_newFeePercentage <= MAX_FEE_PERCENTAGE, "MarketplaceEscrow: fee too high");
        _feePercentage = _newFeePercentage;
        emit FeeUpdated(_newFeePercentage);
    }

    /**
     * @dev Set fee recipient
     */
    function setFeeRecipient(address _newFeeRecipient) external override onlyRole(FEE_MANAGER_ROLE) {
        require(_newFeeRecipient != address(0), "MarketplaceEscrow: invalid fee recipient");
        _feeRecipient = _newFeeRecipient;
        emit FeeRecipientUpdated(_newFeeRecipient);
    }

    /**
     * @dev Get fee percentage
     */
    function getFeePercentage() external view override returns (uint256) {
        return _feePercentage;
    }

    /**
     * @dev Get fee recipient
     */
    function getFeeRecipient() external view override returns (address) {
        return _feeRecipient;
    }

    /**
     * @dev Calculate fee for a price
     */
    function calculateFee(uint256 _price) public view override returns (uint256) {
        return (_price * _feePercentage) / 10000;
    }

    /**
     * @dev Emergency withdraw (admin only)
     */
    function emergencyWithdraw(uint256 _escrowId) external override onlyRole(ADMIN_ROLE) nonReentrant {
        Escrow storage escrow = _escrows[_escrowId];
        require(escrow.depositedAmount > 0, "MarketplaceEscrow: no funds to withdraw");

        uint256 amount = escrow.depositedAmount;
        escrow.depositedAmount = 0;
        escrow.status = EscrowStatus.Cancelled;

        payable(escrow.buyer).transfer(amount);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external override onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external override onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Check if contract is paused
     */
    function isPaused() external view override returns (bool) {
        return paused();
    }

    /**
     * @dev Get total listings
     */
    function getTotalListings() external view override returns (uint256) {
        return _allListings.length;
    }

    /**
     * @dev Get total escrows
     */
    function getTotalEscrows() external view override returns (uint256) {
        return _allEscrows.length;
    }

    /**
     * @dev Get total volume
     */
    function getTotalVolume() external view override returns (uint256) {
        return _totalVolume;
    }

    /**
     * @dev Get average price
     */
    function getAveragePrice() external view override returns (uint256) {
        if (_completedSales == 0) return 0;
        return _totalVolume / _completedSales;
    }

    /**
     * @dev Remove listing from active listings array
     */
    function _removeFromActiveListings(uint256 _listingId) internal {
        for (uint256 i = 0; i < _activeListings.length; i++) {
            if (_activeListings[i] == _listingId) {
                _activeListings[i] = _activeListings[_activeListings.length - 1];
                _activeListings.pop();
                break;
            }
        }
    }

    /**
     * @dev Required by UUPSUpgradeable
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    /**
     * @dev Get contract version
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {
        revert("MarketplaceEscrow: direct payments not allowed");
    }
}
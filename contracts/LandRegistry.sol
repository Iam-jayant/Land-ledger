// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title LandRegistry
 * @dev Advanced blockchain-based land registry system for India
 * @notice This contract manages property registration, verification, and ownership transfers
 */
contract LandRegistry is AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // Role definitions
    bytes32 public constant LAND_INSPECTOR_ROLE = keccak256("LAND_INSPECTOR_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");

    // Counters for IDs
    Counters.Counter private _propertyIds;
    Counters.Counter private _requestIds;
    Counters.Counter private _inspectorIds;

    // Custom errors for gas efficiency
    error UnauthorizedAccess(address caller, string requiredRole);
    error PropertyNotFound(uint256 propertyId);
    error UserNotVerified(address user);
    error PropertyNotVerified(uint256 propertyId);
    error InsufficientPayment(uint256 required, uint256 provided);
    error InvalidPropertyStatus(uint256 propertyId, string status);
    error RequestNotFound(uint256 requestId);
    error AlreadyRegistered(address user);
    error InvalidDocumentHash(string ipfsHash);
    error TransferNotAuthorized(uint256 propertyId, address caller);

    // Enums for better state management
    enum UserStatus { Pending, Verified, Rejected }
    enum PropertyStatus { Pending, Verified, Rejected, Sold }
    enum RequestStatus { Pending, Approved, Rejected, Completed }

    // Structs
    struct Property {
        uint256 id;
        address owner;
        uint256 area;
        string city;
        string state;
        uint256 price;
        string ulpin; // Unique Land Parcel Identification Number (India)
        uint256 surveyNumber;
        string ipfsHash;
        string documentHash;
        PropertyStatus status;
        uint256 createdAt;
        uint256 verifiedAt;
        address verifiedBy;
    }

    struct User {
        address id;
        string name;
        uint256 age;
        string city;
        string aadharNumber;
        string panNumber;
        string email;
        string documentHash;
        UserStatus status;
        uint256 registeredAt;
        uint256 verifiedAt;
        address verifiedBy;
    }

    struct LandInspector {
        uint256 id;
        address inspector;
        string name;
        uint256 age;
        string designation;
        string jurisdiction;
        bool isActive;
        uint256 appointedAt;
    }

    struct PurchaseRequest {
        uint256 id;
        uint256 propertyId;
        address seller;
        address buyer;
        uint256 offerPrice;
        RequestStatus status;
        uint256 createdAt;
        uint256 approvedAt;
        bool paymentReceived;
        uint256 escrowAmount;
    }

    // Mappings
    mapping(uint256 => Property) public properties;
    mapping(address => User) public sellers;
    mapping(address => User) public buyers;
    mapping(uint256 => LandInspector) public inspectors;
    mapping(uint256 => PurchaseRequest) public purchaseRequests;
    
    // Status mappings
    mapping(address => bool) public isRegisteredSeller;
    mapping(address => bool) public isRegisteredBuyer;
    mapping(uint256 => address) public propertyOwner;
    mapping(string => bool) public usedULPINs;
    mapping(string => bool) public usedAadharNumbers;
    mapping(string => bool) public usedPANNumbers;

    // Arrays for enumeration
    address[] public sellersList;
    address[] public buyersList;
    uint256[] public propertiesList;

    // Events
    event UserRegistered(address indexed user, string role, uint256 timestamp);
    event UserVerified(address indexed user, address indexed verifier, UserStatus status);
    event PropertyListed(uint256 indexed propertyId, address indexed owner, string ulpin);
    event PropertyVerified(uint256 indexed propertyId, address indexed verifier, PropertyStatus status);
    event PurchaseRequested(uint256 indexed requestId, uint256 indexed propertyId, address indexed buyer);
    event PurchaseApproved(uint256 indexed requestId, address indexed seller);
    event PaymentReceived(uint256 indexed requestId, uint256 amount, address indexed buyer);
    event OwnershipTransferred(uint256 indexed propertyId, address indexed from, address indexed to);
    event InspectorAppointed(uint256 indexed inspectorId, address indexed inspector, string name);
    event EmergencyPause(address indexed admin, string reason);
    event EmergencyUnpause(address indexed admin);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LAND_INSPECTOR_ROLE, msg.sender);
        
        // Add initial inspector
        _addLandInspector(msg.sender, "Chief Land Inspector", 45, "District Collector", "All Districts");
    }

    // Modifiers
    modifier onlyVerifiedSeller() {
        if (!isRegisteredSeller[msg.sender] || sellers[msg.sender].status != UserStatus.Verified) {
            revert UserNotVerified(msg.sender);
        }
        _;
    }

    modifier onlyVerifiedBuyer() {
        if (!isRegisteredBuyer[msg.sender] || buyers[msg.sender].status != UserStatus.Verified) {
            revert UserNotVerified(msg.sender);
        }
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        if (properties[propertyId].id == 0) {
            revert PropertyNotFound(propertyId);
        }
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        if (propertyOwner[propertyId] != msg.sender) {
            revert TransferNotAuthorized(propertyId, msg.sender);
        }
        _;
    }

    // User Registration Functions
    function registerSeller(
        string memory _name,
        uint256 _age,
        string memory _city,
        string memory _aadharNumber,
        string memory _panNumber,
        string memory _email,
        string memory _documentHash
    ) external whenNotPaused {
        if (isRegisteredSeller[msg.sender]) {
            revert AlreadyRegistered(msg.sender);
        }
        if (usedAadharNumbers[_aadharNumber] || usedPANNumbers[_panNumber]) {
            revert AlreadyRegistered(msg.sender);
        }

        sellers[msg.sender] = User({
            id: msg.sender,
            name: _name,
            age: _age,
            city: _city,
            aadharNumber: _aadharNumber,
            panNumber: _panNumber,
            email: _email,
            documentHash: _documentHash,
            status: UserStatus.Pending,
            registeredAt: block.timestamp,
            verifiedAt: 0,
            verifiedBy: address(0)
        });

        isRegisteredSeller[msg.sender] = true;
        usedAadharNumbers[_aadharNumber] = true;
        usedPANNumbers[_panNumber] = true;
        sellersList.push(msg.sender);

        _grantRole(SELLER_ROLE, msg.sender);

        emit UserRegistered(msg.sender, "SELLER", block.timestamp);
    }

    function registerBuyer(
        string memory _name,
        uint256 _age,
        string memory _city,
        string memory _aadharNumber,
        string memory _panNumber,
        string memory _email,
        string memory _documentHash
    ) external whenNotPaused {
        if (isRegisteredBuyer[msg.sender]) {
            revert AlreadyRegistered(msg.sender);
        }
        if (usedAadharNumbers[_aadharNumber] || usedPANNumbers[_panNumber]) {
            revert AlreadyRegistered(msg.sender);
        }

        buyers[msg.sender] = User({
            id: msg.sender,
            name: _name,
            age: _age,
            city: _city,
            aadharNumber: _aadharNumber,
            panNumber: _panNumber,
            email: _email,
            documentHash: _documentHash,
            status: UserStatus.Pending,
            registeredAt: block.timestamp,
            verifiedAt: 0,
            verifiedBy: address(0)
        });

        isRegisteredBuyer[msg.sender] = true;
        usedAadharNumbers[_aadharNumber] = true;
        usedPANNumbers[_panNumber] = true;
        buyersList.push(msg.sender);

        _grantRole(BUYER_ROLE, msg.sender);

        emit UserRegistered(msg.sender, "BUYER", block.timestamp);
    }

    // Verification Functions
    function verifySeller(address _seller, bool _approve) 
        external 
        onlyRole(LAND_INSPECTOR_ROLE) 
        whenNotPaused 
    {
        if (!isRegisteredSeller[_seller]) {
            revert UnauthorizedAccess(_seller, "SELLER");
        }

        UserStatus newStatus = _approve ? UserStatus.Verified : UserStatus.Rejected;
        sellers[_seller].status = newStatus;
        sellers[_seller].verifiedAt = block.timestamp;
        sellers[_seller].verifiedBy = msg.sender;

        emit UserVerified(_seller, msg.sender, newStatus);
    }

    function verifyBuyer(address _buyer, bool _approve) 
        external 
        onlyRole(LAND_INSPECTOR_ROLE) 
        whenNotPaused 
    {
        if (!isRegisteredBuyer[_buyer]) {
            revert UnauthorizedAccess(_buyer, "BUYER");
        }

        UserStatus newStatus = _approve ? UserStatus.Verified : UserStatus.Rejected;
        buyers[_buyer].status = newStatus;
        buyers[_buyer].verifiedAt = block.timestamp;
        buyers[_buyer].verifiedBy = msg.sender;

        emit UserVerified(_buyer, msg.sender, newStatus);
    }

    // Property Management Functions
    function listProperty(
        uint256 _area,
        string memory _city,
        string memory _state,
        uint256 _price,
        string memory _ulpin,
        uint256 _surveyNumber,
        string memory _ipfsHash,
        string memory _documentHash
    ) external onlyVerifiedSeller whenNotPaused returns (uint256) {
        if (usedULPINs[_ulpin]) {
            revert InvalidPropertyStatus(0, "ULPIN already exists");
        }
        if (bytes(_ipfsHash).length == 0 || bytes(_documentHash).length == 0) {
            revert InvalidDocumentHash(_ipfsHash);
        }

        _propertyIds.increment();
        uint256 newPropertyId = _propertyIds.current();

        properties[newPropertyId] = Property({
            id: newPropertyId,
            owner: msg.sender,
            area: _area,
            city: _city,
            state: _state,
            price: _price,
            ulpin: _ulpin,
            surveyNumber: _surveyNumber,
            ipfsHash: _ipfsHash,
            documentHash: _documentHash,
            status: PropertyStatus.Pending,
            createdAt: block.timestamp,
            verifiedAt: 0,
            verifiedBy: address(0)
        });

        propertyOwner[newPropertyId] = msg.sender;
        usedULPINs[_ulpin] = true;
        propertiesList.push(newPropertyId);

        emit PropertyListed(newPropertyId, msg.sender, _ulpin);
        return newPropertyId;
    }

    function verifyProperty(uint256 _propertyId, bool _approve) 
        external 
        onlyRole(LAND_INSPECTOR_ROLE) 
        propertyExists(_propertyId) 
        whenNotPaused 
    {
        PropertyStatus newStatus = _approve ? PropertyStatus.Verified : PropertyStatus.Rejected;
        properties[_propertyId].status = newStatus;
        properties[_propertyId].verifiedAt = block.timestamp;
        properties[_propertyId].verifiedBy = msg.sender;

        emit PropertyVerified(_propertyId, msg.sender, newStatus);
    }

    // Purchase Request Functions
    function requestPurchase(uint256 _propertyId, uint256 _offerPrice) 
        external 
        onlyVerifiedBuyer 
        propertyExists(_propertyId) 
        whenNotPaused 
        returns (uint256) 
    {
        if (properties[_propertyId].status != PropertyStatus.Verified) {
            revert PropertyNotVerified(_propertyId);
        }
        if (propertyOwner[_propertyId] == msg.sender) {
            revert TransferNotAuthorized(_propertyId, msg.sender);
        }

        _requestIds.increment();
        uint256 newRequestId = _requestIds.current();

        purchaseRequests[newRequestId] = PurchaseRequest({
            id: newRequestId,
            propertyId: _propertyId,
            seller: propertyOwner[_propertyId],
            buyer: msg.sender,
            offerPrice: _offerPrice,
            status: RequestStatus.Pending,
            createdAt: block.timestamp,
            approvedAt: 0,
            paymentReceived: false,
            escrowAmount: 0
        });

        emit PurchaseRequested(newRequestId, _propertyId, msg.sender);
        return newRequestId;
    }

    function approvePurchaseRequest(uint256 _requestId) 
        external 
        whenNotPaused 
    {
        if (purchaseRequests[_requestId].id == 0) {
            revert RequestNotFound(_requestId);
        }
        if (purchaseRequests[_requestId].seller != msg.sender) {
            revert UnauthorizedAccess(msg.sender, "SELLER");
        }

        purchaseRequests[_requestId].status = RequestStatus.Approved;
        purchaseRequests[_requestId].approvedAt = block.timestamp;

        emit PurchaseApproved(_requestId, msg.sender);
    }

    // Payment and Transfer Functions
    function makePayment(uint256 _requestId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
    {
        if (purchaseRequests[_requestId].id == 0) {
            revert RequestNotFound(_requestId);
        }
        if (purchaseRequests[_requestId].buyer != msg.sender) {
            revert UnauthorizedAccess(msg.sender, "BUYER");
        }
        if (purchaseRequests[_requestId].status != RequestStatus.Approved) {
            revert InvalidPropertyStatus(_requestId, "Request not approved");
        }
        if (msg.value < purchaseRequests[_requestId].offerPrice) {
            revert InsufficientPayment(purchaseRequests[_requestId].offerPrice, msg.value);
        }

        purchaseRequests[_requestId].paymentReceived = true;
        purchaseRequests[_requestId].escrowAmount = msg.value;

        emit PaymentReceived(_requestId, msg.value, msg.sender);
    }

    function approveOwnershipTransfer(uint256 _requestId) 
        external 
        onlyRole(LAND_INSPECTOR_ROLE) 
        nonReentrant 
        whenNotPaused 
    {
        if (purchaseRequests[_requestId].id == 0) {
            revert RequestNotFound(_requestId);
        }
        if (!purchaseRequests[_requestId].paymentReceived) {
            revert InvalidPropertyStatus(_requestId, "Payment not received");
        }

        PurchaseRequest storage request = purchaseRequests[_requestId];
        uint256 propertyId = request.propertyId;
        
        // Transfer ownership
        address previousOwner = propertyOwner[propertyId];
        propertyOwner[propertyId] = request.buyer;
        properties[propertyId].owner = request.buyer;
        properties[propertyId].status = PropertyStatus.Sold;
        
        // Update request status
        request.status = RequestStatus.Completed;
        
        // Transfer payment to seller
        payable(request.seller).transfer(request.escrowAmount);

        emit OwnershipTransferred(propertyId, previousOwner, request.buyer);
    }

    // Inspector Management
    function addLandInspector(
        address _inspector,
        string memory _name,
        uint256 _age,
        string memory _designation,
        string memory _jurisdiction
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addLandInspector(_inspector, _name, _age, _designation, _jurisdiction);
    }

    function _addLandInspector(
        address _inspector,
        string memory _name,
        uint256 _age,
        string memory _designation,
        string memory _jurisdiction
    ) internal {
        _inspectorIds.increment();
        uint256 newInspectorId = _inspectorIds.current();

        inspectors[newInspectorId] = LandInspector({
            id: newInspectorId,
            inspector: _inspector,
            name: _name,
            age: _age,
            designation: _designation,
            jurisdiction: _jurisdiction,
            isActive: true,
            appointedAt: block.timestamp
        });

        _grantRole(LAND_INSPECTOR_ROLE, _inspector);
        emit InspectorAppointed(newInspectorId, _inspector, _name);
    }

    // Emergency Functions
    function pause(string memory reason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        emit EmergencyPause(msg.sender, reason);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit EmergencyUnpause(msg.sender);
    }

    // View Functions
    function getProperty(uint256 _propertyId) 
        external 
        view 
        propertyExists(_propertyId) 
        returns (Property memory) 
    {
        return properties[_propertyId];
    }

    function getPurchaseRequest(uint256 _requestId) 
        external 
        view 
        returns (PurchaseRequest memory) 
    {
        if (purchaseRequests[_requestId].id == 0) {
            revert RequestNotFound(_requestId);
        }
        return purchaseRequests[_requestId];
    }

    function getSellerDetails(address _seller) 
        external 
        view 
        returns (User memory) 
    {
        if (!isRegisteredSeller[_seller]) {
            revert UnauthorizedAccess(_seller, "SELLER");
        }
        return sellers[_seller];
    }

    function getBuyerDetails(address _buyer) 
        external 
        view 
        returns (User memory) 
    {
        if (!isRegisteredBuyer[_buyer]) {
            revert UnauthorizedAccess(_buyer, "BUYER");
        }
        return buyers[_buyer];
    }

    function getAllProperties() external view returns (uint256[] memory) {
        return propertiesList;
    }

    function getAllSellers() external view returns (address[] memory) {
        return sellersList;
    }

    function getAllBuyers() external view returns (address[] memory) {
        return buyersList;
    }

    function getTotalProperties() external view returns (uint256) {
        return _propertyIds.current();
    }

    function getTotalRequests() external view returns (uint256) {
        return _requestIds.current();
    }

    function getTotalInspectors() external view returns (uint256) {
        return _inspectorIds.current();
    }

    // Utility Functions
    function isPropertyVerified(uint256 _propertyId) 
        external 
        view 
        propertyExists(_propertyId) 
        returns (bool) 
    {
        return properties[_propertyId].status == PropertyStatus.Verified;
    }

    function isUserVerified(address _user) external view returns (bool) {
        if (isRegisteredSeller[_user]) {
            return sellers[_user].status == UserStatus.Verified;
        }
        if (isRegisteredBuyer[_user]) {
            return buyers[_user].status == UserStatus.Verified;
        }
        return false;
    }

    function getPropertyOwner(uint256 _propertyId) 
        external 
        view 
        propertyExists(_propertyId) 
        returns (address) 
    {
        return propertyOwner[_propertyId];
    }
}
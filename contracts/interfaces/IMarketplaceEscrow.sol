// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMarketplaceEscrow
 * @dev Interface for the Marketplace Escrow contract
 * Handles secure property transactions with atomic swaps
 */
interface IMarketplaceEscrow {
    // Enums
    enum ListingStatus { Active, Sold, Cancelled, Expired }
    enum EscrowStatus { Created, FundsDeposited, Completed, Cancelled, Disputed }

    // Events
    event PropertyListed(uint256 indexed listingId, uint256 indexed tokenId, address indexed seller, uint256 price);
    event PropertyDelisted(uint256 indexed listingId, address indexed seller);
    event PurchaseInitiated(uint256 indexed escrowId, uint256 indexed listingId, address indexed buyer, uint256 price);
    event FundsDeposited(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId, uint256 indexed tokenId, address indexed buyer, address seller, uint256 price);
    event EscrowCancelled(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeRaised(uint256 indexed escrowId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed escrowId, address indexed resolver, bool buyerWins);
    event FeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);

    // Structs
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 listingTimestamp;
        uint256 expirationTimestamp;
        ListingStatus status;
        string description;
        bool isVerified;
    }

    struct Escrow {
        uint256 escrowId;
        uint256 listingId;
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 price;
        uint256 depositedAmount;
        uint256 creationTimestamp;
        uint256 completionDeadline;
        EscrowStatus status;
        string terms;
        bool disputeRaised;
        address disputeInitiator;
        string disputeReason;
    }

    // Listing Functions
    function listProperty(
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationDays,
        string calldata _description
    ) external returns (uint256 listingId);

    function delistProperty(uint256 _listingId) external;

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external;

    function extendListing(uint256 _listingId, uint256 _additionalDays) external;

    // Purchase Functions
    function initiatePurchase(
        uint256 _listingId,
        string calldata _terms
    ) external payable returns (uint256 escrowId);

    function depositFunds(uint256 _escrowId) external payable;

    function completePurchase(uint256 _escrowId) external;

    function cancelPurchase(uint256 _escrowId, string calldata _reason) external;

    // Dispute Functions
    function raiseDispute(uint256 _escrowId, string calldata _reason) external;

    function resolveDispute(uint256 _escrowId, bool _buyerWins, string calldata _resolution) external;

    // View Functions
    function getListing(uint256 _listingId) external view returns (Listing memory);

    function getEscrow(uint256 _escrowId) external view returns (Escrow memory);

    function getActiveListings() external view returns (uint256[] memory);

    function getListingsByOwner(address _owner) external view returns (uint256[] memory);

    function getEscrowsByBuyer(address _buyer) external view returns (uint256[] memory);

    function getEscrowsBySeller(address _seller) external view returns (uint256[] memory);

    function isListingActive(uint256 _listingId) external view returns (bool);

    function isEscrowActive(uint256 _escrowId) external view returns (bool);

    // Batch Operations
    function batchListProperties(
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        uint256[] calldata _expirationDays,
        string[] calldata _descriptions
    ) external returns (uint256[] memory listingIds);

    function batchDelistProperties(uint256[] calldata _listingIds) external;

    // Fee Management
    function setFeePercentage(uint256 _feePercentage) external;

    function setFeeRecipient(address _feeRecipient) external;

    function getFeePercentage() external view returns (uint256);

    function getFeeRecipient() external view returns (address);

    function calculateFee(uint256 _price) external view returns (uint256);

    // Emergency Functions
    function emergencyWithdraw(uint256 _escrowId) external;

    function pause() external;

    function unpause() external;

    function isPaused() external view returns (bool);

    // Statistics
    function getTotalListings() external view returns (uint256);

    function getTotalEscrows() external view returns (uint256);

    function getTotalVolume() external view returns (uint256);

    function getAveragePrice() external view returns (uint256);
}
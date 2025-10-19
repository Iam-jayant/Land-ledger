// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IPropertyToken
 * @dev Interface for Property Token contract
 * Combines ERC-721 NFT functionality with ERC-3643 compliance
 */
interface IPropertyToken is IERC721 {
    // Events
    event PropertyMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, string spvId);
    event PropertyBurned(uint256 indexed tokenId, address indexed owner);
    event MetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event SPVUpdated(uint256 indexed tokenId, string newSPVId);
    event ComplianceSet(address indexed compliance);
    event IdentityRegistrySet(address indexed identityRegistry);
    event PropertyVerified(uint256 indexed tokenId, address indexed verifier);
    event PropertyUnverified(uint256 indexed tokenId, address indexed verifier);

    // Structs
    struct PropertyData {
        uint256 tokenId;
        string metadataURI;
        string spvRegistryId;
        address currentOwner;
        address originalOwner;
        uint256 mintTimestamp;
        uint256 lastTransferTimestamp;
        bool isVerified;
        address verifier;
        uint256 verificationTimestamp;
    }

    struct PropertyMetadata {
        string name;
        string description;
        string location;
        uint256 propertyType;
        uint256 squareFootage;
        uint256 yearBuilt;
        string jurisdiction;
        string legalDescription;
    }

    // Minting Functions
    function mintProperty(
        address _to,
        string calldata _metadataURI,
        string calldata _spvRegistryId,
        PropertyMetadata calldata _metadata
    ) external returns (uint256 tokenId);

    function batchMintProperties(
        address[] calldata _to,
        string[] calldata _metadataURIs,
        string[] calldata _spvRegistryIds,
        PropertyMetadata[] calldata _metadata
    ) external returns (uint256[] memory tokenIds);

    // Property Management
    function updateMetadata(uint256 _tokenId, string calldata _newMetadataURI) external;

    function updateSPV(uint256 _tokenId, string calldata _newSPVId) external;

    function verifyProperty(uint256 _tokenId) external;

    function unverifyProperty(uint256 _tokenId) external;

    // Property Information
    function getPropertyData(uint256 _tokenId) external view returns (PropertyData memory);

    function getPropertyMetadata(uint256 _tokenId) external view returns (PropertyMetadata memory);

    function isPropertyVerified(uint256 _tokenId) external view returns (bool);

    function getVerifier(uint256 _tokenId) external view returns (address);

    function getSPVRegistryId(uint256 _tokenId) external view returns (string memory);

    // Compliance Integration
    function setCompliance(address _compliance) external;

    function setIdentityRegistry(address _identityRegistry) external;

    function getCompliance() external view returns (address);

    function getIdentityRegistry() external view returns (address);

    // Transfer Validation
    function isTransferable(address _from, address _to, uint256 _tokenId) external view returns (bool, string memory);

    // Batch Operations
    function batchTransfer(
        address[] calldata _to,
        uint256[] calldata _tokenIds
    ) external;

    function batchApprove(
        address[] calldata _to,
        uint256[] calldata _tokenIds
    ) external;

    // Property Statistics
    function totalProperties() external view returns (uint256);

    function propertiesByOwner(address _owner) external view returns (uint256[] memory);

    function verifiedProperties() external view returns (uint256[] memory);

    function propertiesByJurisdiction(string calldata _jurisdiction) external view returns (uint256[] memory);

    // Burning
    function burn(uint256 _tokenId) external;

    function burnBatch(uint256[] calldata _tokenIds) external;

    // Pausing
    function pause() external;

    function unpause() external;

    function isPaused() external view returns (bool);
}
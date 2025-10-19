// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/IPropertyToken.sol";
import "./interfaces/ICompliance.sol";
import "./interfaces/IIdentityRegistry.sol";

/**
 * @title PropertyToken
 * @dev ERC-721 NFT with ERC-3643 compliance for tokenized real estate
 * Each token represents a unique property with compliance checks
 */
contract PropertyToken is 
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPropertyToken
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant METADATA_UPDATER_ROLE = keccak256("METADATA_UPDATER_ROLE");

    // Counters
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Compliance contracts
    ICompliance public compliance;
    IIdentityRegistry public identityRegistry;

    // Storage
    mapping(uint256 => PropertyData) private _properties;
    mapping(uint256 => PropertyMetadata) private _propertyMetadata;
    mapping(address => uint256[]) private _ownerProperties;
    mapping(string => uint256[]) private _jurisdictionProperties;
    uint256[] private _verifiedProperties;
    uint256[] private _allProperties;

    // Property type constants
    uint256 public constant PROPERTY_TYPE_RESIDENTIAL = 1;
    uint256 public constant PROPERTY_TYPE_COMMERCIAL = 2;
    uint256 public constant PROPERTY_TYPE_INDUSTRIAL = 3;
    uint256 public constant PROPERTY_TYPE_LAND = 4;
    uint256 public constant PROPERTY_TYPE_MIXED_USE = 5;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _compliance,
        address _identityRegistry
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(VERIFIER_ROLE, _admin);
        _grantRole(METADATA_UPDATER_ROLE, _admin);

        compliance = ICompliance(_compliance);
        identityRegistry = IIdentityRegistry(_identityRegistry);

        // Start token IDs from 1
        _tokenIdCounter.increment();
    }

    /**
     * @dev Mint a new property token
     */
    function mintProperty(
        address _to,
        string calldata _metadataURI,
        string calldata _spvRegistryId,
        PropertyMetadata calldata _metadata
    ) external override onlyRole(MINTER_ROLE) whenNotPaused returns (uint256 tokenId) {
        require(_to != address(0), "PropertyToken: mint to zero address");
        require(bytes(_metadataURI).length > 0, "PropertyToken: empty metadata URI");
        require(bytes(_spvRegistryId).length > 0, "PropertyToken: empty SPV registry ID");

        // Check compliance before minting
        (bool canMint, string memory reason) = compliance.canTransfer(address(0), _to, 1);
        require(canMint, string(abi.encodePacked("PropertyToken: ", reason)));

        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _metadataURI);

        // Store property data
        _properties[tokenId] = PropertyData({
            tokenId: tokenId,
            metadataURI: _metadataURI,
            spvRegistryId: _spvRegistryId,
            currentOwner: _to,
            originalOwner: _to,
            mintTimestamp: block.timestamp,
            lastTransferTimestamp: block.timestamp,
            isVerified: false,
            verifier: address(0),
            verificationTimestamp: 0
        });

        _propertyMetadata[tokenId] = _metadata;

        // Update tracking arrays
        _ownerProperties[_to].push(tokenId);
        _jurisdictionProperties[_metadata.jurisdiction].push(tokenId);
        _allProperties.push(tokenId);

        emit PropertyMinted(tokenId, _to, _metadataURI, _spvRegistryId);
    }

    /**
     * @dev Batch mint properties
     */
    function batchMintProperties(
        address[] calldata _to,
        string[] calldata _metadataURIs,
        string[] calldata _spvRegistryIds,
        PropertyMetadata[] calldata _metadata
    ) external override onlyRole(MINTER_ROLE) whenNotPaused returns (uint256[] memory tokenIds) {
        require(
            _to.length == _metadataURIs.length &&
            _metadataURIs.length == _spvRegistryIds.length &&
            _spvRegistryIds.length == _metadata.length,
            "PropertyToken: arrays length mismatch"
        );

        tokenIds = new uint256[](_to.length);

        for (uint256 i = 0; i < _to.length; i++) {
            tokenIds[i] = this.mintProperty(_to[i], _metadataURIs[i], _spvRegistryIds[i], _metadata[i]);
        }
    }

    /**
     * @dev Update property metadata
     */
    function updateMetadata(uint256 _tokenId, string calldata _newMetadataURI) external override onlyRole(METADATA_UPDATER_ROLE) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        require(bytes(_newMetadataURI).length > 0, "PropertyToken: empty metadata URI");

        _setTokenURI(_tokenId, _newMetadataURI);
        _properties[_tokenId].metadataURI = _newMetadataURI;

        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Update SPV registry ID
     */
    function updateSPV(uint256 _tokenId, string calldata _newSPVId) external override onlyRole(METADATA_UPDATER_ROLE) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        require(bytes(_newSPVId).length > 0, "PropertyToken: empty SPV ID");

        _properties[_tokenId].spvRegistryId = _newSPVId;

        emit SPVUpdated(_tokenId, _newSPVId);
    }

    /**
     * @dev Verify a property
     */
    function verifyProperty(uint256 _tokenId) external override onlyRole(VERIFIER_ROLE) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        require(!_properties[_tokenId].isVerified, "PropertyToken: property already verified");

        _properties[_tokenId].isVerified = true;
        _properties[_tokenId].verifier = msg.sender;
        _properties[_tokenId].verificationTimestamp = block.timestamp;

        _verifiedProperties.push(_tokenId);

        emit PropertyVerified(_tokenId, msg.sender);
    }

    /**
     * @dev Unverify a property
     */
    function unverifyProperty(uint256 _tokenId) external override onlyRole(VERIFIER_ROLE) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        require(_properties[_tokenId].isVerified, "PropertyToken: property not verified");

        _properties[_tokenId].isVerified = false;
        _properties[_tokenId].verifier = address(0);
        _properties[_tokenId].verificationTimestamp = 0;

        // Remove from verified properties array
        for (uint256 i = 0; i < _verifiedProperties.length; i++) {
            if (_verifiedProperties[i] == _tokenId) {
                _verifiedProperties[i] = _verifiedProperties[_verifiedProperties.length - 1];
                _verifiedProperties.pop();
                break;
            }
        }

        emit PropertyUnverified(_tokenId, msg.sender);
    }

    /**
     * @dev Get property data
     */
    function getPropertyData(uint256 _tokenId) external view override returns (PropertyData memory) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return _properties[_tokenId];
    }

    /**
     * @dev Get property metadata
     */
    function getPropertyMetadata(uint256 _tokenId) external view override returns (PropertyMetadata memory) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return _propertyMetadata[_tokenId];
    }

    /**
     * @dev Check if property is verified
     */
    function isPropertyVerified(uint256 _tokenId) external view override returns (bool) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return _properties[_tokenId].isVerified;
    }

    /**
     * @dev Get property verifier
     */
    function getVerifier(uint256 _tokenId) external view override returns (address) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return _properties[_tokenId].verifier;
    }

    /**
     * @dev Get SPV registry ID
     */
    function getSPVRegistryId(uint256 _tokenId) external view override returns (string memory) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return _properties[_tokenId].spvRegistryId;
    }

    /**
     * @dev Set compliance contract
     */
    function setCompliance(address _compliance) external override onlyRole(ADMIN_ROLE) {
        require(_compliance != address(0), "PropertyToken: invalid compliance address");
        compliance = ICompliance(_compliance);
        emit ComplianceSet(_compliance);
    }

    /**
     * @dev Set identity registry
     */
    function setIdentityRegistry(address _identityRegistry) external override onlyRole(ADMIN_ROLE) {
        require(_identityRegistry != address(0), "PropertyToken: invalid identity registry address");
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistrySet(_identityRegistry);
    }

    /**
     * @dev Get compliance contract
     */
    function getCompliance() external view override returns (address) {
        return address(compliance);
    }

    /**
     * @dev Get identity registry
     */
    function getIdentityRegistry() external view override returns (address) {
        return address(identityRegistry);
    }

    /**
     * @dev Check if token is transferable
     */
    function isTransferable(address _from, address _to, uint256 _tokenId) external view override returns (bool, string memory) {
        require(_exists(_tokenId), "PropertyToken: token does not exist");
        return compliance.canTransferToken(_from, _to, _tokenId);
    }

    /**
     * @dev Batch transfer tokens
     */
    function batchTransfer(
        address[] calldata _to,
        uint256[] calldata _tokenIds
    ) external override {
        require(_to.length == _tokenIds.length, "PropertyToken: arrays length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(msg.sender, _to[i], _tokenIds[i]);
        }
    }

    /**
     * @dev Batch approve tokens
     */
    function batchApprove(
        address[] calldata _to,
        uint256[] calldata _tokenIds
    ) external override {
        require(_to.length == _tokenIds.length, "PropertyToken: arrays length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            approve(_to[i], _tokenIds[i]);
        }
    }

    /**
     * @dev Get total number of properties
     */
    function totalProperties() external view override returns (uint256) {
        return _allProperties.length;
    }

    /**
     * @dev Get properties owned by an address
     */
    function propertiesByOwner(address _owner) external view override returns (uint256[] memory) {
        return _ownerProperties[_owner];
    }

    /**
     * @dev Get all verified properties
     */
    function verifiedProperties() external view override returns (uint256[] memory) {
        return _verifiedProperties;
    }

    /**
     * @dev Get properties by jurisdiction
     */
    function propertiesByJurisdiction(string calldata _jurisdiction) external view override returns (uint256[] memory) {
        return _jurisdictionProperties[_jurisdiction];
    }

    /**
     * @dev Burn a token
     */
    function burn(uint256 _tokenId) public override(ERC721BurnableUpgradeable, IPropertyToken) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "PropertyToken: caller is not owner nor approved");
        
        address owner = ownerOf(_tokenId);
        
        // Remove from tracking arrays
        _removeFromOwnerProperties(owner, _tokenId);
        _removeFromAllProperties(_tokenId);
        
        if (_properties[_tokenId].isVerified) {
            _removeFromVerifiedProperties(_tokenId);
        }
        
        // Clean up storage
        delete _properties[_tokenId];
        delete _propertyMetadata[_tokenId];
        
        super.burn(_tokenId);
        
        emit PropertyBurned(_tokenId, owner);
    }

    /**
     * @dev Batch burn tokens
     */
    function burnBatch(uint256[] calldata _tokenIds) external override {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
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
     * @dev Override transfer functions to include compliance checks
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Skip compliance check for minting and burning
        if (from != address(0) && to != address(0)) {
            require(compliance.validateTokenTransfer(from, to, tokenId), "PropertyToken: transfer not compliant");
        }
    }

    /**
     * @dev Override transfer to update property data
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        // Update property data for transfers (not minting/burning)
        if (from != address(0) && to != address(0)) {
            _properties[tokenId].currentOwner = to;
            _properties[tokenId].lastTransferTimestamp = block.timestamp;

            // Update owner tracking
            _removeFromOwnerProperties(from, tokenId);
            _ownerProperties[to].push(tokenId);
        }
    }

    /**
     * @dev Remove token from owner's property list
     */
    function _removeFromOwnerProperties(address _owner, uint256 _tokenId) internal {
        uint256[] storage ownerProps = _ownerProperties[_owner];
        for (uint256 i = 0; i < ownerProps.length; i++) {
            if (ownerProps[i] == _tokenId) {
                ownerProps[i] = ownerProps[ownerProps.length - 1];
                ownerProps.pop();
                break;
            }
        }
    }

    /**
     * @dev Remove token from all properties list
     */
    function _removeFromAllProperties(uint256 _tokenId) internal {
        for (uint256 i = 0; i < _allProperties.length; i++) {
            if (_allProperties[i] == _tokenId) {
                _allProperties[i] = _allProperties[_allProperties.length - 1];
                _allProperties.pop();
                break;
            }
        }
    }

    /**
     * @dev Remove token from verified properties list
     */
    function _removeFromVerifiedProperties(uint256 _tokenId) internal {
        for (uint256 i = 0; i < _verifiedProperties.length; i++) {
            if (_verifiedProperties[i] == _tokenId) {
                _verifiedProperties[i] = _verifiedProperties[_verifiedProperties.length - 1];
                _verifiedProperties.pop();
                break;
            }
        }
    }

    /**
     * @dev Override required by Solidity
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Override required by Solidity
     */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override required by Solidity
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
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
}
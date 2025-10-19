// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IIdentityRegistry.sol";

/**
 * @title IdentityRegistry
 * @dev Implementation of the Identity Registry for ERC-3643 compliance
 * Manages on-chain identities, KYC claims, and verification status
 */
contract IdentityRegistry is 
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IIdentityRegistry
{
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // Claim Topics (standard ERC-3643 topics)
    uint256 public constant CLAIM_TOPIC_KYC = 1;
    uint256 public constant CLAIM_TOPIC_AML = 2;
    uint256 public constant CLAIM_TOPIC_ACCREDITED_INVESTOR = 3;
    uint256 public constant CLAIM_TOPIC_JURISDICTION = 4;

    // Storage
    mapping(address => Identity) private _identities;
    mapping(address => address) private _userToIdentity;
    mapping(address => mapping(bytes32 => Claim)) private _claims;
    mapping(address => mapping(uint256 => bytes32[])) private _claimsByTopic;
    mapping(uint256 => bool) private _claimTopics;
    mapping(address => bool) private _claimIssuers;
    mapping(address => mapping(uint256 => bool)) private _issuerClaimTopics;

    // Counters
    uint256 private _claimIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     */
    function initialize(address _admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);

        // Initialize default claim topics
        _claimTopics[CLAIM_TOPIC_KYC] = true;
        _claimTopics[CLAIM_TOPIC_AML] = true;
        _claimTopics[CLAIM_TOPIC_ACCREDITED_INVESTOR] = true;
        _claimTopics[CLAIM_TOPIC_JURISDICTION] = true;

        emit ClaimTopicAdded(CLAIM_TOPIC_KYC);
        emit ClaimTopicAdded(CLAIM_TOPIC_AML);
        emit ClaimTopicAdded(CLAIM_TOPIC_ACCREDITED_INVESTOR);
        emit ClaimTopicAdded(CLAIM_TOPIC_JURISDICTION);
    }

    /**
     * @dev Register a new identity for a user
     */
    function registerIdentity(
        address _user,
        address _identity,
        uint256 _country
    ) external override onlyRole(AGENT_ROLE) {
        require(_user != address(0), "IdentityRegistry: invalid user address");
        require(_identity != address(0), "IdentityRegistry: invalid identity address");
        require(_userToIdentity[_user] == address(0), "IdentityRegistry: identity already registered");

        _identities[_identity] = Identity({
            identityAddress: _identity,
            country: _country,
            isVerified: false,
            registrationDate: block.timestamp
        });

        _userToIdentity[_user] = _identity;

        emit IdentityRegistered(_identity, _user, _country);
    }

    /**
     * @dev Delete an identity
     */
    function deleteIdentity(address _user) external override onlyRole(AGENT_ROLE) {
        address identityAddr = _userToIdentity[_user];
        require(identityAddr != address(0), "IdentityRegistry: identity not found");

        delete _identities[identityAddr];
        delete _userToIdentity[_user];

        emit IdentityRemoved(identityAddr, _user);
    }

    /**
     * @dev Set the country for an identity
     */
    function setIdentityCountry(address _user, uint256 _country) external override onlyRole(AGENT_ROLE) {
        address identityAddr = _userToIdentity[_user];
        require(identityAddr != address(0), "IdentityRegistry: identity not found");

        _identities[identityAddr].country = _country;
    }

    /**
     * @dev Check if a user is verified (has required claims)
     */
    function isVerified(address _user) external view override returns (bool) {
        address identityAddr = _userToIdentity[_user];
        if (identityAddr == address(0)) return false;

        // Check if user has KYC claim
        bytes32[] memory kycClaims = _claimsByTopic[identityAddr][CLAIM_TOPIC_KYC];
        if (kycClaims.length == 0) return false;

        // Check if user has AML claim
        bytes32[] memory amlClaims = _claimsByTopic[identityAddr][CLAIM_TOPIC_AML];
        if (amlClaims.length == 0) return false;

        return true;
    }

    /**
     * @dev Get identity address for a user
     */
    function identity(address _user) external view override returns (address) {
        return _userToIdentity[_user];
    }

    /**
     * @dev Get country for a user
     */
    function investorCountry(address _user) external view override returns (uint256) {
        address identityAddr = _userToIdentity[_user];
        if (identityAddr == address(0)) return 0;
        return _identities[identityAddr].country;
    }

    /**
     * @dev Add a claim to an identity
     */
    function addClaim(
        address _identity,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri
    ) external override onlyRole(ISSUER_ROLE) returns (bytes32 claimRequestId) {
        require(_identities[_identity].identityAddress != address(0), "IdentityRegistry: identity not found");
        require(_claimTopics[_topic], "IdentityRegistry: claim topic not allowed");
        require(_claimIssuers[_issuer], "IdentityRegistry: issuer not authorized");
        require(_issuerClaimTopics[_issuer][_topic], "IdentityRegistry: issuer not authorized for topic");

        claimRequestId = keccak256(abi.encodePacked(_identity, _topic, _issuer, _claimIdCounter++));

        _claims[_identity][claimRequestId] = Claim({
            topic: _topic,
            scheme: _scheme,
            issuer: _issuer,
            signature: _signature,
            data: _data,
            uri: _uri
        });

        _claimsByTopic[_identity][_topic].push(claimRequestId);

        emit ClaimAdded(_identity, _topic, _issuer);
    }

    /**
     * @dev Remove a claim from an identity
     */
    function removeClaim(address _identity, bytes32 _claimId) external override onlyRole(ISSUER_ROLE) {
        require(_claims[_identity][_claimId].issuer != address(0), "IdentityRegistry: claim not found");
        require(_claims[_identity][_claimId].issuer == msg.sender, "IdentityRegistry: not claim issuer");

        uint256 topic = _claims[_identity][_claimId].topic;
        address issuer = _claims[_identity][_claimId].issuer;

        delete _claims[_identity][_claimId];

        // Remove from topic array
        bytes32[] storage topicClaims = _claimsByTopic[_identity][topic];
        for (uint256 i = 0; i < topicClaims.length; i++) {
            if (topicClaims[i] == _claimId) {
                topicClaims[i] = topicClaims[topicClaims.length - 1];
                topicClaims.pop();
                break;
            }
        }

        emit ClaimRemoved(_identity, topic, issuer);
    }

    /**
     * @dev Get a specific claim
     */
    function getClaim(address _identity, bytes32 _claimId) external view override returns (Claim memory) {
        return _claims[_identity][_claimId];
    }

    /**
     * @dev Get all claims for a specific topic
     */
    function getClaimsByTopic(address _identity, uint256 _topic) external view override returns (bytes32[] memory) {
        return _claimsByTopic[_identity][_topic];
    }

    /**
     * @dev Add a new claim topic
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyRole(ADMIN_ROLE) {
        require(!_claimTopics[_claimTopic], "IdentityRegistry: claim topic already exists");
        _claimTopics[_claimTopic] = true;
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     * @dev Remove a claim topic
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyRole(ADMIN_ROLE) {
        require(_claimTopics[_claimTopic], "IdentityRegistry: claim topic does not exist");
        delete _claimTopics[_claimTopic];
        emit ClaimTopicRemoved(_claimTopic);
    }

    /**
     * @dev Check if a claim topic is required
     */
    function isClaimTopicRequired(uint256 _claimTopic) external view override returns (bool) {
        return _claimTopics[_claimTopic];
    }

    /**
     * @dev Add a claim issuer
     */
    function addClaimIssuer(address _claimIssuer, uint256[] calldata _claimTopics) external override onlyRole(ADMIN_ROLE) {
        require(_claimIssuer != address(0), "IdentityRegistry: invalid issuer address");
        require(!_claimIssuers[_claimIssuer], "IdentityRegistry: issuer already exists");

        _claimIssuers[_claimIssuer] = true;
        _grantRole(ISSUER_ROLE, _claimIssuer);

        for (uint256 i = 0; i < _claimTopics.length; i++) {
            require(_claimTopics[_claimTopics[i]], "IdentityRegistry: invalid claim topic");
            _issuerClaimTopics[_claimIssuer][_claimTopics[i]] = true;
        }

        emit ClaimIssuerAdded(_claimIssuer, _claimTopics);
    }

    /**
     * @dev Remove a claim issuer
     */
    function removeClaimIssuer(address _claimIssuer) external override onlyRole(ADMIN_ROLE) {
        require(_claimIssuers[_claimIssuer], "IdentityRegistry: issuer does not exist");

        delete _claimIssuers[_claimIssuer];
        _revokeRole(ISSUER_ROLE, _claimIssuer);

        emit ClaimIssuerRemoved(_claimIssuer);
    }

    /**
     * @dev Check if an address is a claim issuer
     */
    function isClaimIssuer(address _claimIssuer) external view override returns (bool) {
        return _claimIssuers[_claimIssuer];
    }

    /**
     * @dev Check if an issuer can issue claims for a specific topic
     */
    function hasClaimTopic(address _claimIssuer, uint256 _claimTopic) external view override returns (bool) {
        return _issuerClaimTopics[_claimIssuer][_claimTopic];
    }

    /**
     * @dev Batch register identities
     */
    function batchRegisterIdentity(
        address[] calldata _users,
        address[] calldata _identities,
        uint256[] calldata _countries
    ) external override onlyRole(AGENT_ROLE) {
        require(
            _users.length == _identities.length && _identities.length == _countries.length,
            "IdentityRegistry: arrays length mismatch"
        );

        for (uint256 i = 0; i < _users.length; i++) {
            if (_userToIdentity[_users[i]] == address(0)) {
                _identities[_identities[i]] = Identity({
                    identityAddress: _identities[i],
                    country: _countries[i],
                    isVerified: false,
                    registrationDate: block.timestamp
                });

                _userToIdentity[_users[i]] = _identities[i];

                emit IdentityRegistered(_identities[i], _users[i], _countries[i]);
            }
        }
    }

    /**
     * @dev Get identity details
     */
    function getIdentity(address _user) external view returns (Identity memory) {
        address identityAddr = _userToIdentity[_user];
        require(identityAddr != address(0), "IdentityRegistry: identity not found");
        return _identities[identityAddr];
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
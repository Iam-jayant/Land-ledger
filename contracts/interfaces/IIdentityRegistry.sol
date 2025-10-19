// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IIdentityRegistry
 * @dev Interface for the Identity Registry contract
 * Manages on-chain identities and claims for ERC-3643 compliance
 */
interface IIdentityRegistry {
    // Events
    event IdentityRegistered(address indexed identity, address indexed user, uint256 indexed country);
    event IdentityRemoved(address indexed identity, address indexed user);
    event ClaimAdded(address indexed identity, uint256 indexed claimTopic, address indexed issuer);
    event ClaimRemoved(address indexed identity, uint256 indexed claimTopic, address indexed issuer);
    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);
    event ClaimIssuerAdded(address indexed claimIssuer, uint256[] claimTopics);
    event ClaimIssuerRemoved(address indexed claimIssuer);

    // Structs
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    struct Identity {
        address identityAddress;
        uint256 country;
        bool isVerified;
        uint256 registrationDate;
    }

    // Identity Management
    function registerIdentity(
        address _user,
        address _identity,
        uint256 _country
    ) external;

    function deleteIdentity(address _user) external;

    function setIdentityCountry(address _user, uint256 _country) external;

    function isVerified(address _user) external view returns (bool);

    function identity(address _user) external view returns (address);

    function investorCountry(address _user) external view returns (uint256);

    // Claim Management
    function addClaim(
        address _identity,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri
    ) external returns (bytes32 claimRequestId);

    function removeClaim(address _identity, bytes32 _claimId) external;

    function getClaim(address _identity, bytes32 _claimId) external view returns (Claim memory);

    function getClaimsByTopic(address _identity, uint256 _topic) external view returns (bytes32[] memory);

    // Claim Topics Management
    function addClaimTopic(uint256 _claimTopic) external;

    function removeClaimTopic(uint256 _claimTopic) external;

    function isClaimTopicRequired(uint256 _claimTopic) external view returns (bool);

    // Claim Issuers Management
    function addClaimIssuer(address _claimIssuer, uint256[] calldata _claimTopics) external;

    function removeClaimIssuer(address _claimIssuer) external;

    function isClaimIssuer(address _claimIssuer) external view returns (bool);

    function hasClaimTopic(address _claimIssuer, uint256 _claimTopic) external view returns (bool);

    // Batch Operations
    function batchRegisterIdentity(
        address[] calldata _users,
        address[] calldata _identities,
        uint256[] calldata _countries
    ) external;
}
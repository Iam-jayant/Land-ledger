// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICompliance
 * @dev Interface for the Compliance contract
 * Manages transfer restrictions and regulatory compliance for ERC-3643 tokens
 */
interface ICompliance {
    // Events
    event ComplianceRuleAdded(bytes32 indexed ruleId, string ruleName);
    event ComplianceRuleRemoved(bytes32 indexed ruleId);
    event ComplianceRuleUpdated(bytes32 indexed ruleId, string ruleName);
    event CountryRestrictionSet(uint256 indexed country, bool allowed);
    event MaxHoldingSet(uint256 maxHolding);
    event MinHoldingSet(uint256 minHolding);
    event TransferApproved(address indexed from, address indexed to, uint256 amount);
    event TransferRejected(address indexed from, address indexed to, uint256 amount, string reason);

    // Structs
    struct TransferRequest {
        address from;
        address to;
        uint256 amount;
        uint256 tokenId;
    }

    struct TransferResult {
        bool allowed;
        string reason;
        uint256 errorCode;
    }

    struct ComplianceRule {
        bytes32 id;
        string name;
        bool active;
        uint256 priority;
        bytes parameters;
    }

    // Core Compliance Functions
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool, string memory);

    function canTransferToken(
        address _from,
        address _to,
        uint256 _tokenId
    ) external view returns (bool, string memory);

    function batchCanTransfer(
        TransferRequest[] calldata _transfers
    ) external view returns (TransferResult[] memory);

    // Identity Verification
    function isVerifiedUser(address _user) external view returns (bool);

    function getUserCountry(address _user) external view returns (uint256);

    function isCountryAllowed(uint256 _country) external view returns (bool);

    // Compliance Rules Management
    function addComplianceRule(
        string calldata _name,
        uint256 _priority,
        bytes calldata _parameters
    ) external returns (bytes32 ruleId);

    function removeComplianceRule(bytes32 _ruleId) external;

    function updateComplianceRule(
        bytes32 _ruleId,
        string calldata _name,
        uint256 _priority,
        bytes calldata _parameters
    ) external;

    function getComplianceRule(bytes32 _ruleId) external view returns (ComplianceRule memory);

    function getAllComplianceRules() external view returns (ComplianceRule[] memory);

    // Country Restrictions
    function setCountryRestriction(uint256 _country, bool _allowed) external;

    function setCountryRestrictions(uint256[] calldata _countries, bool[] calldata _allowed) external;

    // Holding Limits
    function setMaxHolding(uint256 _maxHolding) external;

    function setMinHolding(uint256 _minHolding) external;

    function getMaxHolding() external view returns (uint256);

    function getMinHolding() external view returns (uint256);

    // Transfer Validation
    function validateTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function validateTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external returns (bool);

    // Batch Operations
    function batchValidateTransfers(
        TransferRequest[] calldata _transfers
    ) external returns (TransferResult[] memory);

    // Configuration
    function setIdentityRegistry(address _identityRegistry) external;

    function getIdentityRegistry() external view returns (address);

    function pause() external;

    function unpause() external;

    function isPaused() external view returns (bool);
}
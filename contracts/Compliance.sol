// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ICompliance.sol";
import "./interfaces/IIdentityRegistry.sol";

/**
 * @title Compliance
 * @dev Implementation of compliance rules for ERC-3643 tokens
 * Manages transfer restrictions, country limitations, and regulatory compliance
 */
contract Compliance is 
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ICompliance
{
    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");

    // Error Codes
    uint256 public constant ERROR_USER_NOT_VERIFIED = 1;
    uint256 public constant ERROR_COUNTRY_NOT_ALLOWED = 2;
    uint256 public constant ERROR_AMOUNT_TOO_HIGH = 3;
    uint256 public constant ERROR_AMOUNT_TOO_LOW = 4;
    uint256 public constant ERROR_TRANSFER_PAUSED = 5;
    uint256 public constant ERROR_CUSTOM_RULE = 6;

    // Storage
    IIdentityRegistry public identityRegistry;
    
    mapping(uint256 => bool) private _allowedCountries;
    mapping(bytes32 => ComplianceRule) private _complianceRules;
    bytes32[] private _ruleIds;
    
    uint256 private _maxHolding;
    uint256 private _minHolding;
    uint256 private _ruleCounter;

    // Default allowed countries (can be modified by admin)
    uint256[] private _defaultAllowedCountries;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract
     */
    function initialize(
        address _admin,
        address _identityRegistry,
        uint256[] calldata _allowedCountries
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(COMPLIANCE_OFFICER_ROLE, _admin);

        identityRegistry = IIdentityRegistry(_identityRegistry);

        // Set default allowed countries
        for (uint256 i = 0; i < _allowedCountries.length; i++) {
            _allowedCountries[_allowedCountries[i]] = true;
            _defaultAllowedCountries.push(_allowedCountries[i]);
            emit CountryRestrictionSet(_allowedCountries[i], true);
        }

        // Set default holding limits (0 means no limit)
        _maxHolding = 0;
        _minHolding = 0;
    }

    /**
     * @dev Check if a transfer can be executed
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view override returns (bool, string memory) {
        if (paused()) {
            return (false, "Transfers are paused");
        }

        // Skip checks for minting (from zero address)
        if (_from != address(0)) {
            // Check if sender is verified
            if (!identityRegistry.isVerified(_from)) {
                return (false, "Sender not verified");
            }

            // Check sender country
            uint256 fromCountry = identityRegistry.investorCountry(_from);
            if (!_allowedCountries[fromCountry]) {
                return (false, "Sender country not allowed");
            }
        }

        // Check if receiver is verified
        if (!identityRegistry.isVerified(_to)) {
            return (false, "Receiver not verified");
        }

        // Check receiver country
        uint256 toCountry = identityRegistry.investorCountry(_to);
        if (!_allowedCountries[toCountry]) {
            return (false, "Receiver country not allowed");
        }

        // Check holding limits
        if (_maxHolding > 0 && _amount > _maxHolding) {
            return (false, "Amount exceeds maximum holding limit");
        }

        if (_minHolding > 0 && _amount < _minHolding) {
            return (false, "Amount below minimum holding limit");
        }

        // Check custom compliance rules
        for (uint256 i = 0; i < _ruleIds.length; i++) {
            ComplianceRule memory rule = _complianceRules[_ruleIds[i]];
            if (rule.active) {
                (bool ruleResult, string memory ruleReason) = _checkCustomRule(rule, _from, _to, _amount);
                if (!ruleResult) {
                    return (false, ruleReason);
                }
            }
        }

        return (true, "Transfer allowed");
    }

    /**
     * @dev Check if a token transfer can be executed (for NFT-like transfers)
     */
    function canTransferToken(
        address _from,
        address _to,
        uint256 _tokenId
    ) external view override returns (bool, string memory) {
        // For property tokens, we treat each token as having value of 1
        return this.canTransfer(_from, _to, 1);
    }

    /**
     * @dev Batch check multiple transfers
     */
    function batchCanTransfer(
        TransferRequest[] calldata _transfers
    ) external view override returns (TransferResult[] memory) {
        TransferResult[] memory results = new TransferResult[](_transfers.length);
        
        for (uint256 i = 0; i < _transfers.length; i++) {
            (bool allowed, string memory reason) = this.canTransfer(
                _transfers[i].from,
                _transfers[i].to,
                _transfers[i].amount
            );
            
            results[i] = TransferResult({
                allowed: allowed,
                reason: reason,
                errorCode: allowed ? 0 : _getErrorCode(reason)
            });
        }
        
        return results;
    }

    /**
     * @dev Check if user is verified
     */
    function isVerifiedUser(address _user) external view override returns (bool) {
        return identityRegistry.isVerified(_user);
    }

    /**
     * @dev Get user country
     */
    function getUserCountry(address _user) external view override returns (uint256) {
        return identityRegistry.investorCountry(_user);
    }

    /**
     * @dev Check if country is allowed
     */
    function isCountryAllowed(uint256 _country) external view override returns (bool) {
        return _allowedCountries[_country];
    }

    /**
     * @dev Add a compliance rule
     */
    function addComplianceRule(
        string calldata _name,
        uint256 _priority,
        bytes calldata _parameters
    ) external override onlyRole(COMPLIANCE_OFFICER_ROLE) returns (bytes32 ruleId) {
        ruleId = keccak256(abi.encodePacked(_name, _priority, _ruleCounter++));
        
        _complianceRules[ruleId] = ComplianceRule({
            id: ruleId,
            name: _name,
            active: true,
            priority: _priority,
            parameters: _parameters
        });
        
        _ruleIds.push(ruleId);
        
        emit ComplianceRuleAdded(ruleId, _name);
    }

    /**
     * @dev Remove a compliance rule
     */
    function removeComplianceRule(bytes32 _ruleId) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(_complianceRules[_ruleId].id != bytes32(0), "Compliance: rule does not exist");
        
        delete _complianceRules[_ruleId];
        
        // Remove from array
        for (uint256 i = 0; i < _ruleIds.length; i++) {
            if (_ruleIds[i] == _ruleId) {
                _ruleIds[i] = _ruleIds[_ruleIds.length - 1];
                _ruleIds.pop();
                break;
            }
        }
        
        emit ComplianceRuleRemoved(_ruleId);
    }

    /**
     * @dev Update a compliance rule
     */
    function updateComplianceRule(
        bytes32 _ruleId,
        string calldata _name,
        uint256 _priority,
        bytes calldata _parameters
    ) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(_complianceRules[_ruleId].id != bytes32(0), "Compliance: rule does not exist");
        
        _complianceRules[_ruleId].name = _name;
        _complianceRules[_ruleId].priority = _priority;
        _complianceRules[_ruleId].parameters = _parameters;
        
        emit ComplianceRuleUpdated(_ruleId, _name);
    }

    /**
     * @dev Get a compliance rule
     */
    function getComplianceRule(bytes32 _ruleId) external view override returns (ComplianceRule memory) {
        return _complianceRules[_ruleId];
    }

    /**
     * @dev Get all compliance rules
     */
    function getAllComplianceRules() external view override returns (ComplianceRule[] memory) {
        ComplianceRule[] memory rules = new ComplianceRule[](_ruleIds.length);
        for (uint256 i = 0; i < _ruleIds.length; i++) {
            rules[i] = _complianceRules[_ruleIds[i]];
        }
        return rules;
    }

    /**
     * @dev Set country restriction
     */
    function setCountryRestriction(uint256 _country, bool _allowed) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _allowedCountries[_country] = _allowed;
        emit CountryRestrictionSet(_country, _allowed);
    }

    /**
     * @dev Set multiple country restrictions
     */
    function setCountryRestrictions(
        uint256[] calldata _countries,
        bool[] calldata _allowed
    ) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(_countries.length == _allowed.length, "Compliance: arrays length mismatch");
        
        for (uint256 i = 0; i < _countries.length; i++) {
            _allowedCountries[_countries[i]] = _allowed[i];
            emit CountryRestrictionSet(_countries[i], _allowed[i]);
        }
    }

    /**
     * @dev Set maximum holding limit
     */
    function setMaxHolding(uint256 _maxHolding) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _maxHolding = _maxHolding;
        emit MaxHoldingSet(_maxHolding);
    }

    /**
     * @dev Set minimum holding limit
     */
    function setMinHolding(uint256 _minHolding) external override onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _minHolding = _minHolding;
        emit MinHoldingSet(_minHolding);
    }

    /**
     * @dev Get maximum holding limit
     */
    function getMaxHolding() external view override returns (uint256) {
        return _maxHolding;
    }

    /**
     * @dev Get minimum holding limit
     */
    function getMinHolding() external view override returns (uint256) {
        return _minHolding;
    }

    /**
     * @dev Validate transfer (with state changes)
     */
    function validateTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyRole(TOKEN_ROLE) returns (bool) {
        (bool allowed, string memory reason) = this.canTransfer(_from, _to, _amount);
        
        if (allowed) {
            emit TransferApproved(_from, _to, _amount);
        } else {
            emit TransferRejected(_from, _to, _amount, reason);
        }
        
        return allowed;
    }

    /**
     * @dev Validate token transfer (with state changes)
     */
    function validateTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override onlyRole(TOKEN_ROLE) returns (bool) {
        (bool allowed, string memory reason) = this.canTransferToken(_from, _to, _tokenId);
        
        if (allowed) {
            emit TransferApproved(_from, _to, _tokenId);
        } else {
            emit TransferRejected(_from, _to, _tokenId, reason);
        }
        
        return allowed;
    }

    /**
     * @dev Batch validate transfers
     */
    function batchValidateTransfers(
        TransferRequest[] calldata _transfers
    ) external override onlyRole(TOKEN_ROLE) returns (TransferResult[] memory) {
        return this.batchCanTransfer(_transfers);
    }

    /**
     * @dev Set identity registry
     */
    function setIdentityRegistry(address _identityRegistry) external override onlyRole(ADMIN_ROLE) {
        require(_identityRegistry != address(0), "Compliance: invalid identity registry");
        identityRegistry = IIdentityRegistry(_identityRegistry);
    }

    /**
     * @dev Get identity registry
     */
    function getIdentityRegistry() external view override returns (address) {
        return address(identityRegistry);
    }

    /**
     * @dev Pause transfers
     */
    function pause() external override onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause transfers
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
     * @dev Internal function to check custom rules
     */
    function _checkCustomRule(
        ComplianceRule memory _rule,
        address _from,
        address _to,
        uint256 _amount
    ) internal pure returns (bool, string memory) {
        // This is a placeholder for custom rule logic
        // In a real implementation, you would decode the parameters and apply specific rules
        // For now, we'll just return true to allow all transfers that pass basic checks
        return (true, "Custom rule passed");
    }

    /**
     * @dev Get error code from reason string
     */
    function _getErrorCode(string memory _reason) internal pure returns (uint256) {
        bytes32 reasonHash = keccak256(bytes(_reason));
        
        if (reasonHash == keccak256("Sender not verified") || reasonHash == keccak256("Receiver not verified")) {
            return ERROR_USER_NOT_VERIFIED;
        }
        if (reasonHash == keccak256("Sender country not allowed") || reasonHash == keccak256("Receiver country not allowed")) {
            return ERROR_COUNTRY_NOT_ALLOWED;
        }
        if (reasonHash == keccak256("Amount exceeds maximum holding limit")) {
            return ERROR_AMOUNT_TOO_HIGH;
        }
        if (reasonHash == keccak256("Amount below minimum holding limit")) {
            return ERROR_AMOUNT_TOO_LOW;
        }
        if (reasonHash == keccak256("Transfers are paused")) {
            return ERROR_TRANSFER_PAUSED;
        }
        
        return ERROR_CUSTOM_RULE;
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
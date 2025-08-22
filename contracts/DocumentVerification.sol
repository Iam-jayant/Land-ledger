// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DocumentVerification
 * @dev Advanced document verification system using IPFS hashes
 * @notice Manages document authenticity and tamper-proof storage
 */
contract DocumentVerification is AccessControl, Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant DOCUMENT_MANAGER_ROLE =
        keccak256("DOCUMENT_MANAGER_ROLE");

    Counters.Counter private _documentIds;

    // Custom errors
    error DocumentNotFound(uint256 documentId);
    error InvalidIPFSHash(string ipfsHash);
    error DocumentAlreadyExists(string ipfsHash);
    error UnauthorizedDocumentAccess(address caller, uint256 documentId);
    error DocumentAlreadyVerified(uint256 documentId);
    error InvalidDocumentType(string documentType);

    enum DocumentType {
        PropertyDeed,
        IdentityProof,
        AddressProof,
        TaxReceipt,
        SurveyDocument,
        LegalClearance,
        Other
    }

    enum VerificationStatus {
        Pending,
        Verified,
        Rejected,
        Expired
    }

    struct Document {
        uint256 id;
        string ipfsHash;
        string fileName;
        DocumentType docType;
        address owner;
        address uploader;
        VerificationStatus status;
        uint256 uploadedAt;
        uint256 verifiedAt;
        address verifiedBy;
        uint256 expiresAt;
        string metadata;
        bytes32 contentHash;
        bool isPublic;
    }

    struct VerificationRecord {
        uint256 documentId;
        address verifier;
        VerificationStatus status;
        string comments;
        uint256 timestamp;
        string verificationMethod;
    }

    // Mappings
    mapping(uint256 => Document) public documents;
    mapping(string => uint256) public ipfsHashToDocumentId;
    mapping(address => uint256[]) public userDocuments;
    mapping(uint256 => VerificationRecord[]) public verificationHistory;
    mapping(bytes32 => bool) public contentHashExists;
    mapping(address => mapping(DocumentType => uint256[]))
        public userDocumentsByType;

    // Arrays for enumeration
    uint256[] public allDocuments;
    uint256[] public pendingVerifications;

    // Constants
    uint256 public constant DOCUMENT_VALIDITY_PERIOD = 365 days;
    uint256 public constant MAX_VERIFICATION_ATTEMPTS = 3;

    // Events
    event DocumentUploaded(
        uint256 indexed documentId,
        string indexed ipfsHash,
        address indexed owner,
        DocumentType docType
    );
    event DocumentVerified(
        uint256 indexed documentId,
        address indexed verifier,
        VerificationStatus status
    );
    event DocumentExpired(uint256 indexed documentId, uint256 expiredAt);
    event DocumentUpdated(uint256 indexed documentId, string newIpfsHash);
    event VerificationRequested(
        uint256 indexed documentId,
        address indexed requester
    );
    event DocumentMadePublic(uint256 indexed documentId, address indexed owner);
    event DocumentRevoked(
        uint256 indexed documentId,
        address indexed revoker,
        string reason
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
        _grantRole(DOCUMENT_MANAGER_ROLE, msg.sender);
    }

    modifier documentExists(uint256 documentId) {
        if (documents[documentId].id == 0) {
            revert DocumentNotFound(documentId);
        }
        _;
    }

    modifier onlyDocumentOwner(uint256 documentId) {
        if (
            documents[documentId].owner != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedDocumentAccess(msg.sender, documentId);
        }
        _;
    }

    modifier validIPFSHash(string memory ipfsHash) {
        if (bytes(ipfsHash).length == 0 || bytes(ipfsHash).length > 100) {
            revert InvalidIPFSHash(ipfsHash);
        }
        _;
    }

    /**
     * @dev Upload a new document to the system
     */
    function uploadDocument(
        string memory _ipfsHash,
        string memory _fileName,
        DocumentType _docType,
        string memory _metadata,
        bytes32 _contentHash,
        bool _isPublic
    ) external validIPFSHash(_ipfsHash) whenNotPaused returns (uint256) {
        // Check if document already exists
        if (ipfsHashToDocumentId[_ipfsHash] != 0) {
            revert DocumentAlreadyExists(_ipfsHash);
        }
        if (contentHashExists[_contentHash]) {
            revert DocumentAlreadyExists("Content hash already exists");
        }

        _documentIds.increment();
        uint256 newDocumentId = _documentIds.current();

        documents[newDocumentId] = Document({
            id: newDocumentId,
            ipfsHash: _ipfsHash,
            fileName: _fileName,
            docType: _docType,
            owner: msg.sender,
            uploader: msg.sender,
            status: VerificationStatus.Pending,
            uploadedAt: block.timestamp,
            verifiedAt: 0,
            verifiedBy: address(0),
            expiresAt: block.timestamp + DOCUMENT_VALIDITY_PERIOD,
            metadata: _metadata,
            contentHash: _contentHash,
            isPublic: _isPublic
        });

        // Update mappings
        ipfsHashToDocumentId[_ipfsHash] = newDocumentId;
        userDocuments[msg.sender].push(newDocumentId);
        userDocumentsByType[msg.sender][_docType].push(newDocumentId);
        contentHashExists[_contentHash] = true;
        allDocuments.push(newDocumentId);
        pendingVerifications.push(newDocumentId);

        emit DocumentUploaded(newDocumentId, _ipfsHash, msg.sender, _docType);
        return newDocumentId;
    }

    /**
     * @dev Verify a document
     */
    function verifyDocument(
        uint256 _documentId,
        VerificationStatus _status,
        string memory _comments,
        string memory _verificationMethod
    )
        external
        documentExists(_documentId)
        onlyRole(VERIFIER_ROLE)
        whenNotPaused
    {
        Document storage doc = documents[_documentId];

        if (doc.status == VerificationStatus.Verified) {
            revert DocumentAlreadyVerified(_documentId);
        }

        // Update document status
        doc.status = _status;
        doc.verifiedAt = block.timestamp;
        doc.verifiedBy = msg.sender;

        // Add to verification history
        verificationHistory[_documentId].push(
            VerificationRecord({
                documentId: _documentId,
                verifier: msg.sender,
                status: _status,
                comments: _comments,
                timestamp: block.timestamp,
                verificationMethod: _verificationMethod
            })
        );

        // Remove from pending if verified or rejected
        if (
            _status == VerificationStatus.Verified ||
            _status == VerificationStatus.Rejected
        ) {
            _removePendingVerification(_documentId);
        }

        emit DocumentVerified(_documentId, msg.sender, _status);
    }

    /**
     * @dev Batch verify multiple documents
     */
    function batchVerifyDocuments(
        uint256[] memory documentIds,
        VerificationStatus[] memory _statuses,
        string[] memory _comments
    ) external onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(
            documentIds.length == _statuses.length &&
                _statuses.length == _comments.length,
            "Array lengths mismatch"
        );

        for (uint256 i = 0; i < documentIds.length; i++) {
            this.verifyDocument(
                documentIds[i],
                _statuses[i],
                _comments[i],
                "Batch verification"
            );
        }
    }

    /**
     * @dev Update document IPFS hash (for document revisions)
     */
    function updateDocument(
        uint256 _documentId,
        string memory _newIpfsHash,
        bytes32 _newContentHash
    )
        external
        documentExists(_documentId)
        onlyDocumentOwner(_documentId)
        validIPFSHash(_newIpfsHash)
        whenNotPaused
    {
        Document storage doc = documents[_documentId];

        // Remove old hash mapping
        delete ipfsHashToDocumentId[doc.ipfsHash];
        delete contentHashExists[doc.contentHash];

        // Update with new hash
        doc.ipfsHash = _newIpfsHash;
        doc.contentHash = _newContentHash;
        doc.status = VerificationStatus.Pending; // Reset verification status
        doc.verifiedAt = 0;
        doc.verifiedBy = address(0);

        // Update mappings
        ipfsHashToDocumentId[_newIpfsHash] = _documentId;
        contentHashExists[_newContentHash] = true;
        pendingVerifications.push(_documentId);

        emit DocumentUpdated(_documentId, _newIpfsHash);
    }

    /**
     * @dev Request verification for a document
     */
    function requestVerification(
        uint256 _documentId
    )
        external
        documentExists(_documentId)
        onlyDocumentOwner(_documentId)
        whenNotPaused
    {
        Document storage doc = documents[_documentId];

        if (doc.status == VerificationStatus.Verified) {
            revert DocumentAlreadyVerified(_documentId);
        }

        doc.status = VerificationStatus.Pending;
        pendingVerifications.push(_documentId);

        emit VerificationRequested(_documentId, msg.sender);
    }

    /**
     * @dev Make document public for transparency
     */
    function makeDocumentPublic(
        uint256 _documentId
    )
        external
        documentExists(_documentId)
        onlyDocumentOwner(_documentId)
        whenNotPaused
    {
        documents[_documentId].isPublic = true;
        emit DocumentMadePublic(_documentId, msg.sender);
    }

    /**
     * @dev Revoke a document
     */
    function revokeDocument(
        uint256 _documentId,
        string memory _reason
    ) external documentExists(_documentId) whenNotPaused {
        // Only owner or admin can revoke
        if (
            documents[_documentId].owner != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedDocumentAccess(msg.sender, _documentId);
        }

        documents[_documentId].status = VerificationStatus.Expired;
        documents[_documentId].expiresAt = block.timestamp;

        emit DocumentRevoked(_documentId, msg.sender, _reason);
    }

    /**
     * @dev Handle expired documents
     */
    function handleExpiredDocuments(
        uint256[] memory documentIds
    ) external onlyRole(DOCUMENT_MANAGER_ROLE) whenNotPaused {
        for (uint256 i = 0; i < documentIds.length; i++) {
            uint256 docId = documentIds[i];
            if (
                documents[docId].id != 0 &&
                block.timestamp > documents[docId].expiresAt
            ) {
                documents[docId].status = VerificationStatus.Expired;
                emit DocumentExpired(docId, block.timestamp);
            }
        }
    }

    /**
     * @dev Verify document authenticity using IPFS hash
     */
    function verifyDocumentAuthenticity(
        string memory _ipfsHash,
        bytes32 _contentHash
    )
        external
        view
        returns (
            bool isAuthentic,
            uint256 documentId,
            VerificationStatus status
        )
    {
        documentId = ipfsHashToDocumentId[_ipfsHash];
        if (documentId == 0) {
            return (false, 0, VerificationStatus.Pending);
        }

        Document memory doc = documents[documentId];
        isAuthentic = (doc.contentHash == _contentHash);
        status = doc.status;

        return (isAuthentic, documentId, status);
    }

    /**
     * @dev Get document by IPFS hash
     */
    function getDocumentByIPFS(
        string memory _ipfsHash
    ) external view returns (Document memory) {
        uint256 docId = ipfsHashToDocumentId[_ipfsHash];
        if (docId == 0) {
            revert DocumentNotFound(0);
        }
        return documents[docId];
    }

    /**
     * @dev Get user's documents by type
     */
    function getUserDocumentsByType(
        address _user,
        DocumentType _docType
    ) external view returns (uint256[] memory) {
        return userDocumentsByType[_user][_docType];
    }

    /**
     * @dev Get verification history for a document
     */
    function getVerificationHistory(
        uint256 _documentId
    )
        external
        view
        documentExists(_documentId)
        returns (VerificationRecord[] memory)
    {
        return verificationHistory[_documentId];
    }

    /**
     * @dev Get pending verifications
     */
    function getPendingVerifications()
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (uint256[] memory)
    {
        return pendingVerifications;
    }

    /**
     * @dev Get user's documents
     */
    function getUserDocuments(
        address _user
    ) external view returns (uint256[] memory) {
        return userDocuments[_user];
    }

    /**
     * @dev Get all public documents
     */
    function getPublicDocuments() external view returns (uint256[] memory) {
        uint256[] memory publicDocs = new uint256[](allDocuments.length);
        uint256 count = 0;

        for (uint256 i = 0; i < allDocuments.length; i++) {
            if (documents[allDocuments[i]].isPublic) {
                publicDocs[count] = allDocuments[i];
                count++;
            }
        }

        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = publicDocs[i];
        }

        return result;
    }

    /**
     * @dev Check if document is expired
     */
    function isDocumentExpired(
        uint256 _documentId
    ) external view documentExists(_documentId) returns (bool) {
        return block.timestamp > documents[_documentId].expiresAt;
    }

    /**
     * @dev Get document verification status
     */
    function getDocumentStatus(
        uint256 _documentId
    ) external view documentExists(_documentId) returns (VerificationStatus) {
        return documents[_documentId].status;
    }

    /**
     * @dev Get total documents count
     */
    function getTotalDocuments() external view returns (uint256) {
        return _documentIds.current();
    }

    /**
     * @dev Internal function to remove from pending verifications
     */
    function _removePendingVerification(uint256 _documentId) internal {
        for (uint256 i = 0; i < pendingVerifications.length; i++) {
            if (pendingVerifications[i] == _documentId) {
                pendingVerifications[i] = pendingVerifications[
                    pendingVerifications.length - 1
                ];
                pendingVerifications.pop();
                break;
            }
        }
    }

    /**
     * @dev Emergency functions
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Bulk document operations for efficiency
     */
    function bulkUploadDocuments(
        string[] memory ipfsHashes,
        string[] memory fileNames,
        DocumentType[] memory docTypes,
        string[] memory metadatas,
        bytes32[] memory contentHashes,
        bool[] memory isPublics
    ) external whenNotPaused returns (uint256[] memory) {
        require(
            ipfsHashes.length == fileNames.length &&
                fileNames.length == docTypes.length &&
                docTypes.length == metadatas.length &&
                metadatas.length == contentHashes.length &&
                contentHashes.length == isPublics.length,
            "Array lengths mismatch"
        );

        uint256[] memory documentIds = new uint256[](ipfsHashes.length);

        for (uint256 i = 0; i < ipfsHashes.length; i++) {
            documentIds[i] = this.uploadDocument(
                ipfsHashes[i],
                fileNames[i],
                docTypes[i],
                metadatas[i],
                contentHashes[i],
                isPublics[i]
            );
        }

        return documentIds;
    }
}

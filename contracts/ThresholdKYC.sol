// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IThresholdKYC.sol";
import "./interfaces/IRegistry.sol";

/// @title ThresholdKYC
/// @notice On-chain coordination layer for threshold-encrypted identity access.
/// @dev Actual encryption and decryption happen entirely off-chain.
///      This contract only coordinates: who may request access, whether
///      threshold is met, and maintains an irrevocable audit trail.
///
///      Shamir's Secret Sharing scheme:
///        V1 — 3-of-5  (initial deployment)
///        V2 — 5-of-9  (growth phase)
///        V3 — 7-of-13 (mature deployment)
contract ThresholdKYC is IThresholdKYC, AccessControl, ReentrancyGuard {

    // -------------------------
    // Roles
    // -------------------------

    bytes32 public constant GOVERNANCE_ROLE   = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant RIDE_SESSION_ROLE = keccak256("RIDE_SESSION_ROLE");

    // -------------------------
    // Constants
    // -------------------------

    /// @notice Access request expiry — must be resolved within this window
    uint256 public constant ACCESS_REQUEST_EXPIRY = 7 days;

    /// @notice High value freeze threshold — triggers eligible access reason
    uint256 public constant HIGH_VALUE_THRESHOLD = 1 ether;

    // -------------------------
    // Schema configuration
    // -------------------------

    /// @notice Threshold M per schema version
    mapping(SchemaVersion => uint256) private _thresholds;

    /// @notice Total shards N per schema version
    mapping(SchemaVersion => uint256) private _totalShards;

    /// @notice Currently active schema
    SchemaVersion private _currentSchema;

    // -------------------------
    // Storage
    // -------------------------

    IRegistry public immutable registry;

    /// @notice Identity records per wallet
    mapping(address => Identity) private _identities;

    /// @notice Access requests
    mapping(bytes32 => AccessRequest) private _accessRequests;

    /// @notice Shard submissions per request
    /// requestId => arbiterAddress => submitted
    mapping(bytes32 => mapping(address => bool)) private _shardSubmissions;

    /// @notice Shard data per request (stored as hashes only — actual shards off-chain)
    /// requestId => shardIndex => shardHash
    mapping(bytes32 => mapping(uint256 => bytes32)) private _shardHashes;

    /// @notice Access history per wallet
    mapping(address => bytes32[]) private _accessHistory;

    /// @notice Panic button status per session
    mapping(bytes32 => bool) private _panicActive;

    /// @notice Nonce for request ID generation
    uint256 private _nonce;

    // -------------------------
    // Constructor
    // -------------------------

    constructor(address registryAddress, address admin) {
        require(registryAddress != address(0), "ThresholdKYC: invalid registry");
        registry = IRegistry(registryAddress);

        // configure schema thresholds
        _thresholds[SchemaVersion.V1_3_OF_5]  = 3;
        _thresholds[SchemaVersion.V2_5_OF_9]  = 5;
        _thresholds[SchemaVersion.V3_7_OF_13] = 7;

        _totalShards[SchemaVersion.V1_3_OF_5]  = 5;
        _totalShards[SchemaVersion.V2_5_OF_9]  = 9;
        _totalShards[SchemaVersion.V3_7_OF_13] = 13;

        // start with V1
        _currentSchema = SchemaVersion.V1_3_OF_5;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNANCE_ROLE, admin);
    }

    // -------------------------
    // Registration functions
    // -------------------------

    /// @inheritdoc IThresholdKYC
    function registerIdentity(bytes32 encryptedHash) external {
        require(encryptedHash != bytes32(0), "ThresholdKYC: invalid hash");
        require(
            _identities[msg.sender].wallet == address(0),
            "ThresholdKYC: already registered"
        );

        _identities[msg.sender] = Identity({
            wallet:        msg.sender,
            encryptedHash: encryptedHash,
            registeredAt:  block.timestamp,
            active:        true
        });

        emit IdentityRegistered(msg.sender, encryptedHash);
    }

    /// @inheritdoc IThresholdKYC
    function updateIdentity(bytes32 newEncryptedHash) external {
        require(newEncryptedHash != bytes32(0), "ThresholdKYC: invalid hash");
        require(
            _identities[msg.sender].wallet != address(0),
            "ThresholdKYC: not registered"
        );

        _identities[msg.sender].encryptedHash = newEncryptedHash;

        emit IdentityRegistered(msg.sender, newEncryptedHash);
    }

    /// @inheritdoc IThresholdKYC
    function getIdentity(address wallet) external view returns (Identity memory) {
        return _identities[wallet];
    }

    // -------------------------
    // Panic button
    // -------------------------

    /// @inheritdoc IThresholdKYC
    function activatePanicButton(
        bytes32 sessionId,
        bytes32 locationHash
    ) external {
        require(sessionId   != bytes32(0), "ThresholdKYC: invalid session");
        require(locationHash != bytes32(0), "ThresholdKYC: invalid location");
        require(!_panicActive[sessionId],   "ThresholdKYC: panic already active");

        // irrevocable — no way to cancel after this point
        _panicActive[sessionId] = true;

        emit PanicButtonActivated(msg.sender, sessionId, block.timestamp);

        // automatically open access request for the activator's counterparty
        // activator could be driver or passenger — request targets their wallet
        _createAccessRequest(
            msg.sender,
            AccessReason.PANIC_BUTTON,
            sessionId
        );
    }

    // -------------------------
    // Access request functions
    // -------------------------

    /// @inheritdoc IThresholdKYC
    function createAccessRequest(
        address target,
        AccessReason reason,
        bytes32 sessionId
    ) external returns (bytes32 requestId) {
        // governance vote and high value freeze can be requested externally
        require(
            reason == AccessReason.GOVERNANCE_VOTE ||
            reason == AccessReason.HIGH_VALUE_FREEZE,
            "ThresholdKYC: panic button must use activatePanicButton"
        );

        if (reason == AccessReason.GOVERNANCE_ROLE) {
            require(
                hasRole(GOVERNANCE_ROLE, msg.sender),
                "ThresholdKYC: governance role required"
            );
        }

        return _createAccessRequest(target, reason, sessionId);
    }

    /// @inheritdoc IThresholdKYC
    function submitShard(
        bytes32 requestId,
        bytes calldata shardData
    ) external nonReentrant {
        AccessRequest storage request = _accessRequests[requestId];
        require(request.createdAt != 0,     "ThresholdKYC: request not found");
        require(!request.executed,          "ThresholdKYC: already executed");
        require(
            block.timestamp <= request.expiresAt,
            "ThresholdKYC: request expired"
        );

        // verify caller is an active arbiter
        IRegistry.Arbiter memory arbiter = registry.getArbiter(msg.sender);
        require(arbiter.wallet != address(0), "ThresholdKYC: not an arbiter");
        require(arbiter.active,               "ThresholdKYC: arbiter not active");

        // prevent double submission
        require(
            !_shardSubmissions[requestId][msg.sender],
            "ThresholdKYC: shard already submitted"
        );

        // store shard hash on-chain (actual shard data handled off-chain)
        uint256 shardIndex = request.shardsSubmitted;
        _shardHashes[requestId][shardIndex] = keccak256(shardData);
        _shardSubmissions[requestId][msg.sender] = true;
        request.shardsSubmitted++;

        emit ShardSubmitted(requestId, msg.sender, shardIndex);
    }

    /// @inheritdoc IThresholdKYC
    function executeReconstruction(bytes32 requestId) external nonReentrant {
        AccessRequest storage request = _accessRequests[requestId];
        require(request.createdAt != 0, "ThresholdKYC: request not found");
        require(!request.executed,      "ThresholdKYC: already executed");
        require(
            block.timestamp <= request.expiresAt,
            "ThresholdKYC: request expired"
        );
        require(
            request.shardsSubmitted >= request.threshold,
            "ThresholdKYC: threshold not met"
        );

        request.executed = true;

        emit IdentityReconstructed(requestId, request.target);
    }

    // -------------------------
    // Schema upgrade
    // -------------------------

    /// @inheritdoc IThresholdKYC
    function upgradeSchema(
        SchemaVersion newVersion
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(
            uint8(newVersion) > uint8(_currentSchema),
            "ThresholdKYC: can only upgrade to higher version"
        );

        SchemaVersion oldVersion = _currentSchema;
        _currentSchema = newVersion;

        emit SchemaUpgraded(oldVersion, newVersion);
    }

    // -------------------------
    // View functions
    // -------------------------

    /// @inheritdoc IThresholdKYC
    function getAccessRequest(
        bytes32 requestId
    ) external view returns (AccessRequest memory) {
        return _accessRequests[requestId];
    }

    /// @inheritdoc IThresholdKYC
    function getAccessHistory(
        address wallet
    ) external view returns (bytes32[] memory) {
        return _accessHistory[wallet];
    }

    /// @inheritdoc IThresholdKYC
    function isPanicActive(bytes32 sessionId) external view returns (bool) {
        return _panicActive[sessionId];
    }

    /// @inheritdoc IThresholdKYC
    function currentThreshold() external view returns (uint256) {
        return _thresholds[_currentSchema];
    }

    /// @inheritdoc IThresholdKYC
    function currentTotalShards() external view returns (uint256) {
        return _totalShards[_currentSchema];
    }

    /// @inheritdoc IThresholdKYC
    function currentSchema() external view returns (SchemaVersion) {
        return _currentSchema;
    }

    // -------------------------
    // Internal functions
    // -------------------------

    function _createAccessRequest(
        address target,
        AccessReason reason,
        bytes32 sessionId
    ) internal returns (bytes32 requestId) {
        require(
            _identities[target].wallet != address(0),
            "ThresholdKYC: target not registered"
        );

        requestId = keccak256(
            abi.encodePacked(target, reason, sessionId, block.timestamp, _nonce++)
        );

        uint256 threshold = _thresholds[_currentSchema];

        _accessRequests[requestId] = AccessRequest({
            requestId:       requestId,
            target:          target,
            reason:          reason,
            sessionId:       sessionId,
            shardsSubmitted: 0,
            threshold:       threshold,
            executed:        false,
            createdAt:       block.timestamp,
            expiresAt:       block.timestamp + ACCESS_REQUEST_EXPIRY
        });

        _accessHistory[target].push(requestId);

        emit AccessRequestCreated(requestId, target, reason);
    }

    // -------------------------
    // Admin functions
    // -------------------------

    /// @notice Grant governance role to multisig or governance contract
    function setGovernance(
        address governance
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GOVERNANCE_ROLE, governance);
    }

    /// @notice Grant RideSession role
    function setRideSessionContract(
        address rideSessionAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RIDE_SESSION_ROLE, rideSessionAddress);
    }

    // -------------------------
    // Fallback
    // -------------------------

    receive() external payable {
        revert("ThresholdKYC: no ether accepted");
    }
}

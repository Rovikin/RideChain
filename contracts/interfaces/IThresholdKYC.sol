// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title IThresholdKYC
/// @notice Interface for threshold-encrypted identity management
/// @dev Identity documents are encrypted off-chain using Shamir's Secret Sharing.
///      Only the content hash and shard metadata are stored on-chain.
///      Reconstruction requires M-of-N active arbiters to submit their shards.
interface IThresholdKYC {

    // -------------------------
    // Enums
    // -------------------------

    enum AccessReason {
        PANIC_BUTTON,       // triggered by participant during trip
        GOVERNANCE_VOTE,    // community vote reached threshold
        HIGH_VALUE_FREEZE   // escrow freeze exceeds defined threshold
    }

    enum SchemaVersion {
        V1_3_OF_5,          // initial deployment, small community
        V2_5_OF_9,          // growth phase
        V3_7_OF_13          // mature deployment
    }

    // -------------------------
    // Structs
    // -------------------------

    struct Identity {
        address wallet;
        bytes32 encryptedHash;      // IPFS hash of encrypted identity documents
        uint256 registeredAt;
        bool active;
    }

    struct AccessRequest {
        bytes32 requestId;
        address target;             // wallet whose identity is requested
        AccessReason reason;
        bytes32 sessionId;          // relevant session (if applicable)
        uint256 shardsSubmitted;    // number of shards received so far
        uint256 threshold;          // M required for this schema version
        bool executed;              // whether reconstruction was completed
        uint256 createdAt;
        uint256 expiresAt;
    }

    struct ShardMetadata {
        address arbiter;            // shard holder
        uint256 shardIndex;         // index in the secret sharing scheme
        bool submitted;             // whether submitted for reconstruction
    }

    // -------------------------
    // Events
    // -------------------------

    event IdentityRegistered(
        address indexed wallet,
        bytes32 encryptedHash
    );
    event AccessRequestCreated(
        bytes32 indexed requestId,
        address indexed target,
        AccessReason reason
    );
    event ShardSubmitted(
        bytes32 indexed requestId,
        address indexed arbiter,
        uint256 shardIndex
    );
    event IdentityReconstructed(
        bytes32 indexed requestId,
        address indexed target
    );
    event SchemaUpgraded(
        SchemaVersion oldVersion,
        SchemaVersion newVersion
    );
    event PanicButtonActivated(
        address indexed activator,
        bytes32 indexed sessionId,
        uint256 timestamp
    );

    // -------------------------
    // Registration functions
    // -------------------------

    /// @notice Register encrypted identity hash on-chain
    /// @param encryptedHash IPFS content hash of encrypted identity documents
    function registerIdentity(bytes32 encryptedHash) external;

    /// @notice Update identity hash (e.g. document renewal)
    function updateIdentity(bytes32 newEncryptedHash) external;

    /// @notice Get identity data for a wallet
    function getIdentity(address wallet) external view returns (Identity memory);

    // -------------------------
    // Panic button
    // -------------------------

    /// @notice Activate panic button during an active trip
    /// @dev Irrevocable. Commits GPS location hash and notifies network.
    /// @param sessionId the active trip session
    /// @param locationHash hash of current GPS coordinates
    function activatePanicButton(
        bytes32 sessionId,
        bytes32 locationHash
    ) external;

    // -------------------------
    // Access request functions
    // -------------------------

    /// @notice Create an identity access request
    /// @dev Only permitted under defined AccessReason conditions
    /// @param target wallet address whose identity is requested
    /// @param reason the reason for access
    /// @param sessionId relevant session ID (use bytes32(0) if not applicable)
    function createAccessRequest(
        address target,
        AccessReason reason,
        bytes32 sessionId
    ) external returns (bytes32 requestId);

    /// @notice Arbiter submits their shard for an active access request
    /// @param requestId the access request
    /// @param shardData the arbiter's shard (encrypted, verified off-chain)
    function submitShard(
        bytes32 requestId,
        bytes calldata shardData
    ) external;

    /// @notice Execute identity reconstruction once threshold is reached
    /// @dev Emits IdentityReconstructed event. Actual decryption happens off-chain.
    function executeReconstruction(bytes32 requestId) external;

    // -------------------------
    // Schema upgrade functions
    // -------------------------

    /// @notice Upgrade threshold schema (governance only)
    /// @dev Triggers shard redistribution process
    function upgradeSchema(SchemaVersion newVersion) external;

    /// @notice Get current active schema version
    function currentSchema() external view returns (SchemaVersion);

    // -------------------------
    // View functions
    // -------------------------

    /// @notice Get access request data
    function getAccessRequest(bytes32 requestId) external view returns (AccessRequest memory);

    /// @notice Get all access requests for a target wallet
    function getAccessHistory(address wallet) external view returns (bytes32[] memory);

    /// @notice Check if panic button has been activated for a session
    function isPanicActive(bytes32 sessionId) external view returns (bool);

    /// @notice Get current threshold (M) for active schema
    function currentThreshold() external view returns (uint256);

    /// @notice Get total shard holders (N) for active schema
    function currentTotalShards() external view returns (uint256);
}

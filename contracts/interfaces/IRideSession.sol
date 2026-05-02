// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title IRideSession
/// @notice Interface for individual trip state machine and escrow
interface IRideSession {

    // -------------------------
    // Enums
    // -------------------------

    enum State {
        CREATED,        // escrow locked, waiting for driver to accept
        ACCEPTED,       // driver accepted, moving to pickup
        PICKING_UP,     // driver arrived at pickup location
        IN_PROGRESS,    // trip ongoing
        COMPLETED,      // driver claimed delivery, waiting confirmation
        CONFIRMED,      // passenger confirmed or timeout — funds released
        DISPUTED,       // passenger disputed, escrow frozen
        RESOLVED,       // arbiter decided, funds executed
        CANCELLED,      // cancelled by rules
        EXPIRED         // no action within timeout
    }

    // -------------------------
    // Structs
    // -------------------------

    struct Session {
        bytes32 sessionId;
        address driver;
        address passenger;
        uint256 escrowAmount;       // total locked (fare + gas buffer)
        uint256 fareAmount;         // agreed fare
        uint256 routingFee;         // already paid at creation
        int256 pickupLat;
        int256 pickupLng;
        int256 dropoffLat;
        int256 dropoffLng;
        uint256 estimatedDistance;  // meters
        bytes32 gpsMerkleRoot;      // submitted at COMPLETED state
        State state;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // -------------------------
    // Events
    // -------------------------

    event SessionCreated(
        bytes32 indexed sessionId,
        address indexed driver,
        address indexed passenger,
        uint256 fareAmount
    );
    event StateChanged(
        bytes32 indexed sessionId,
        State oldState,
        State newState
    );
    event EscrowReleased(
        bytes32 indexed sessionId,
        address recipient,
        uint256 amount
    );
    event GpsMerkleRootSubmitted(
        bytes32 indexed sessionId,
        bytes32 merkleRoot
    );
    event DisputeOpened(
        bytes32 indexed sessionId,
        address indexed openedBy
    );

    // -------------------------
    // Timeouts (in seconds)
    // -------------------------

    /// @notice Max time for driver to accept after order created
    function TIMEOUT_ACCEPT() external view returns (uint256);

    /// @notice Max time for driver to start moving after accept
    function TIMEOUT_PICKUP() external view returns (uint256);

    /// @notice Max time for passenger to appear at pickup
    function TIMEOUT_PASSENGER_APPEAR() external view returns (uint256);

    /// @notice Max time for passenger to confirm after driver claims completed
    function TIMEOUT_CONFIRM() external view returns (uint256);

    // -------------------------
    // Driver functions
    // -------------------------

    /// @notice Driver accepts the order
    function acceptOrder(bytes32 sessionId) external;

    /// @notice Driver signals arrival at pickup location
    function arrivedAtPickup(bytes32 sessionId) external;

    /// @notice Driver signals trip has started (passenger on board)
    function startTrip(bytes32 sessionId) external;

    /// @notice Driver claims trip is completed, submits GPS Merkle root
    function completeTrip(bytes32 sessionId, bytes32 gpsMerkleRoot) external;

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @notice Passenger confirms trip completed — releases escrow to driver
    function confirmTrip(bytes32 sessionId) external;

    /// @notice Passenger disputes completion claim
    /// @dev Requires arbiter fee deposit
    function openDispute(bytes32 sessionId) external payable;

    /// @notice Passenger cancels order (rules-based penalty applies)
    function cancelByPassenger(bytes32 sessionId) external;

    // -------------------------
    // Timeout functions
    // -------------------------

    /// @notice Anyone can trigger timeout resolution after deadline passes
    function triggerTimeout(bytes32 sessionId) external;

    // -------------------------
    // Dispute functions
    // -------------------------

    /// @notice Called by Dispute Contract to resolve and execute fund distribution
    /// @param sessionId the session being resolved
    /// @param driverWins true if driver is found correct
    function resolveDispute(bytes32 sessionId, bool driverWins) external;

    // -------------------------
    // View functions
    // -------------------------

    /// @notice Get session data
    function getSession(bytes32 sessionId) external view returns (Session memory);

    /// @notice Get current state of a session
    function getState(bytes32 sessionId) external view returns (State);

    /// @notice Verify a GPS Merkle proof against stored root
    function verifyGpsProof(
        bytes32 sessionId,
        bytes32[] calldata proof,
        bytes32 leaf
    ) external view returns (bool);
}

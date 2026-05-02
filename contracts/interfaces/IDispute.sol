// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title IDispute
/// @notice Interface for dispute resolution and arbiter management
interface IDispute {

    // -------------------------
    // Enums
    // -------------------------

    enum DisputeStatus {
        PENDING,        // waiting for arbiter to respond
        IN_REVIEW,      // arbiter accepted, reviewing evidence
        RESOLVED,       // decision made, funds executed
        REASSIGNED      // arbiter timed out, reassigned to new arbiter
    }

    // -------------------------
    // Structs
    // -------------------------

    struct Dispute {
        bytes32 disputeId;
        bytes32 sessionId;
        address driver;
        address passenger;
        address arbiter;
        uint256 arbiterFee;         // fee deposited by passenger upfront
        uint256 arbiterDeposit;     // arbiter's own collateral at stake
        DisputeStatus status;
        bool driverWins;            // outcome, valid only when RESOLVED
        uint256 createdAt;
        uint256 updatedAt;
        uint256 resolveDeadline;    // arbiter must decide before this
    }

    // -------------------------
    // Events
    // -------------------------

    event DisputeCreated(
        bytes32 indexed disputeId,
        bytes32 indexed sessionId,
        address indexed arbiter,
        uint256 resolveDeadline
    );
    event DisputeResolved(
        bytes32 indexed disputeId,
        address indexed arbiter,
        bool driverWins
    );
    event ArbiterReassigned(
        bytes32 indexed disputeId,
        address oldArbiter,
        address newArbiter
    );
    event ArbiterSlashed(
        bytes32 indexed disputeId,
        address indexed arbiter,
        uint256 amount
    );
    event ArbiterRated(
        bytes32 indexed disputeId,
        address indexed arbiter,
        uint256 rating
    );

    // -------------------------
    // Timeouts
    // -------------------------

    /// @notice Max time for arbiter to respond after assignment
    function TIMEOUT_ARBITER_RESPOND() external view returns (uint256);

    /// @notice Max time for arbiter to resolve after responding
    function TIMEOUT_ARBITER_RESOLVE() external view returns (uint256);

    // -------------------------
    // Core functions
    // -------------------------

    /// @notice Open a dispute for a session
    /// @dev Called by RideSession Contract when passenger disputes
    /// @param sessionId the session being disputed
    /// @param driver driver address
    /// @param passenger passenger address
    function openDispute(
        bytes32 sessionId,
        address driver,
        address passenger
    ) external payable returns (bytes32 disputeId);

    /// @notice Arbiter accepts the assigned dispute
    function acceptDispute(bytes32 disputeId) external;

    /// @notice Arbiter submits final decision
    /// @param disputeId the dispute being resolved
    /// @param driverWins true if driver is found correct
    function resolveDispute(
        bytes32 disputeId,
        bool driverWins
    ) external;

    /// @notice Trigger reassignment if arbiter timed out
    /// @dev Anyone can call this after deadline passes
    function triggerReassignment(bytes32 disputeId) external;

    // -------------------------
    // Rating functions
    // -------------------------

    /// @notice Winning party rates the arbiter after resolution
    /// @param disputeId the resolved dispute
    /// @param rating score between 1 and 5
    function rateArbiter(bytes32 disputeId, uint256 rating) external;

    // -------------------------
    // View functions
    // -------------------------

    /// @notice Get dispute data
    function getDispute(bytes32 disputeId) external view returns (Dispute memory);

    /// @notice Get dispute by session ID
    function getDisputeBySession(bytes32 sessionId) external view returns (Dispute memory);

    /// @notice Check if a session currently has an active dispute
    function hasActiveDispute(bytes32 sessionId) external view returns (bool);
}

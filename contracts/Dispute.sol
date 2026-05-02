// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IDispute.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IRideSession.sol";

/// @title Dispute
/// @notice Manages dispute resolution with community arbiters
contract Dispute is IDispute, AccessControl, ReentrancyGuard {

    // -------------------------
    // Roles
    // -------------------------

    bytes32 public constant RIDE_SESSION_ROLE = keccak256("RIDE_SESSION_ROLE");

    // -------------------------
    // Timeouts
    // -------------------------

    uint256 public constant override TIMEOUT_ARBITER_RESPOND = 2  hours;
    uint256 public constant override TIMEOUT_ARBITER_RESOLVE = 24 hours;

    // -------------------------
    // Constants
    // -------------------------

    /// @notice Slash amount for non-responsive arbiter (10% of their deposit)
    uint256 public constant ARBITER_SLASH_BPS = 1000;

    /// @notice Valid rating range
    uint256 public constant MIN_RATING = 1;
    uint256 public constant MAX_RATING = 5;

    // -------------------------
    // Storage
    // -------------------------

    IRegistry    public immutable registry;
    IRideSession public immutable rideSession;

    mapping(bytes32 => Dispute)  private _disputes;
    mapping(bytes32 => bytes32)  private _sessionToDispute;

    // -------------------------
    // Constructor
    // -------------------------

    constructor(
        address registryAddress,
        address rideSessionAddress,
        address admin
    ) {
        require(registryAddress   != address(0), "Dispute: invalid registry");
        require(rideSessionAddress != address(0), "Dispute: invalid rideSession");

        registry    = IRegistry(registryAddress);
        rideSession = IRideSession(rideSessionAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RIDE_SESSION_ROLE, rideSessionAddress);
    }

    // -------------------------
    // Core functions
    // -------------------------

    /// @inheritdoc IDispute
    function openDispute(
        bytes32 sessionId,
        address driver,
        address passenger
    ) external payable onlyRole(RIDE_SESSION_ROLE) nonReentrant returns (bytes32 disputeId) {
        require(
            _sessionToDispute[sessionId] == bytes32(0),
            "Dispute: dispute already exists"
        );
        require(msg.value > 0, "Dispute: arbiter fee required");

        // select arbiter using block data as seed
        // not perfectly random but sufficient for this use case
        uint256 seed = uint256(
            keccak256(abi.encodePacked(sessionId, block.timestamp, block.prevrandao))
        );
        address arbiter = registry.getRandomArbiter(seed);
        require(arbiter != driver && arbiter != passenger, "Dispute: invalid arbiter");

        IRegistry.Arbiter memory arbiterData = registry.getArbiter(arbiter);
        uint256 arbiterSlash = (arbiterData.depositAmount * ARBITER_SLASH_BPS) / 10000;

        disputeId = keccak256(abi.encodePacked(sessionId, block.timestamp));

        _disputes[disputeId] = Dispute({
            disputeId:       disputeId,
            sessionId:       sessionId,
            driver:          driver,
            passenger:       passenger,
            arbiter:         arbiter,
            arbiterFee:      msg.value,
            arbiterDeposit:  arbiterSlash,
            status:          DisputeStatus.PENDING,
            driverWins:      false,
            createdAt:       block.timestamp,
            updatedAt:       block.timestamp,
            resolveDeadline: block.timestamp + TIMEOUT_ARBITER_RESPOND + TIMEOUT_ARBITER_RESOLVE
        });

        _sessionToDispute[sessionId] = disputeId;

        emit DisputeCreated(disputeId, sessionId, arbiter, _disputes[disputeId].resolveDeadline);
    }

    /// @inheritdoc IDispute
    function acceptDispute(bytes32 disputeId) external {
        Dispute storage d = _disputes[disputeId];
        require(msg.sender == d.arbiter, "Dispute: not assigned arbiter");
        require(d.status == DisputeStatus.PENDING, "Dispute: not pending");
        require(
            block.timestamp <= d.createdAt + TIMEOUT_ARBITER_RESPOND,
            "Dispute: response timeout passed"
        );

        d.status    = DisputeStatus.IN_REVIEW;
        d.updatedAt = block.timestamp;
    }

    /// @inheritdoc IDispute
    function resolveDispute(
        bytes32 disputeId,
        bool driverWins
    ) external nonReentrant {
        Dispute storage d = _disputes[disputeId];
        require(msg.sender == d.arbiter, "Dispute: not assigned arbiter");
        require(d.status == DisputeStatus.IN_REVIEW, "Dispute: not in review");
        require(
            block.timestamp <= d.resolveDeadline,
            "Dispute: resolve deadline passed"
        );

        // --- Effects ---
        d.status     = DisputeStatus.RESOLVED;
        d.driverWins = driverWins;
        d.updatedAt  = block.timestamp;

        emit DisputeResolved(disputeId, d.arbiter, driverWins);

        // --- Interactions ---
        // instruct RideSession to execute fund distribution
        rideSession.resolveDispute(d.sessionId, driverWins);

        // pay arbiter fee from losing party's slash
        address loser = driverWins ? d.passenger : d.driver;
        registry.slash(loser, d.arbiterFee, d.arbiter);

        emit ArbiterRated(disputeId, d.arbiter, 0); // placeholder, actual rating via rateArbiter
    }

    /// @inheritdoc IDispute
    function triggerReassignment(bytes32 disputeId) external nonReentrant {
        Dispute storage d = _disputes[disputeId];

        if (d.status == DisputeStatus.PENDING) {
            require(
                block.timestamp > d.createdAt + TIMEOUT_ARBITER_RESPOND,
                "Dispute: response timeout not reached"
            );
        } else if (d.status == DisputeStatus.IN_REVIEW) {
            require(
                block.timestamp > d.resolveDeadline,
                "Dispute: resolve deadline not reached"
            );
        } else {
            revert("Dispute: cannot reassign at this status");
        }

        address oldArbiter = d.arbiter;

        // slash non-responsive arbiter
        IRegistry.Arbiter memory arbiterData = registry.getArbiter(oldArbiter);
        uint256 slashAmount = (arbiterData.depositAmount * ARBITER_SLASH_BPS) / 10000;

        if (slashAmount > 0) {
            // split slash between driver and passenger as compensation
            uint256 half = slashAmount / 2;
            registry.slash(oldArbiter, half, d.driver);
            registry.slash(oldArbiter, slashAmount - half, d.passenger);

            emit ArbiterSlashed(disputeId, oldArbiter, slashAmount);
        }

        // select new arbiter
        uint256 seed = uint256(
            keccak256(abi.encodePacked(disputeId, block.timestamp, block.prevrandao))
        );
        address newArbiter = registry.getRandomArbiter(seed);
        require(
            newArbiter != d.driver && newArbiter != d.passenger,
            "Dispute: invalid arbiter"
        );

        d.arbiter         = newArbiter;
        d.status          = DisputeStatus.PENDING;
        d.updatedAt       = block.timestamp;
        d.resolveDeadline = block.timestamp + TIMEOUT_ARBITER_RESPOND + TIMEOUT_ARBITER_RESOLVE;

        emit ArbiterReassigned(disputeId, oldArbiter, newArbiter);
    }

    // -------------------------
    // Rating functions
    // -------------------------

    /// @inheritdoc IDispute
    function rateArbiter(bytes32 disputeId, uint256 rating) external {
        Dispute storage d = _disputes[disputeId];
        require(d.status == DisputeStatus.RESOLVED, "Dispute: not resolved");
        require(rating >= MIN_RATING && rating <= MAX_RATING, "Dispute: invalid rating");

        // only winning party can rate
        bool callerIsWinner = d.driverWins
            ? msg.sender == d.driver
            : msg.sender == d.passenger;
        require(callerIsWinner, "Dispute: only winner can rate");

        registry.updateReputation(d.arbiter, rating);

        emit ArbiterRated(disputeId, d.arbiter, rating);
    }

    // -------------------------
    // View functions
    // -------------------------

    /// @inheritdoc IDispute
    function getDispute(bytes32 disputeId) external view returns (Dispute memory) {
        return _disputes[disputeId];
    }

    /// @inheritdoc IDispute
    function getDisputeBySession(bytes32 sessionId) external view returns (Dispute memory) {
        return _disputes[_sessionToDispute[sessionId]];
    }

    /// @inheritdoc IDispute
    function hasActiveDispute(bytes32 sessionId) external view returns (bool) {
        bytes32 disputeId = _sessionToDispute[sessionId];
        if (disputeId == bytes32(0)) return false;
        DisputeStatus status = _disputes[disputeId].status;
        return status == DisputeStatus.PENDING || status == DisputeStatus.IN_REVIEW;
    }

    // -------------------------
    // Fallback
    // -------------------------

    receive() external payable {
        revert("Dispute: use openDispute");
    }
}

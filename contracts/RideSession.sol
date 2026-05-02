// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IRideSession.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IDispute.sol";

/// @title RideSession
/// @notice Core state machine for each trip with escrow management
contract RideSession is IRideSession, AccessControl, ReentrancyGuard {

    // -------------------------
    // Roles
    // -------------------------

    bytes32 public constant DISPUTE_ROLE    = keccak256("DISPUTE_ROLE");
    bytes32 public constant ORDER_BOOK_ROLE = keccak256("ORDER_BOOK_ROLE");

    // -------------------------
    // Timeouts
    // -------------------------

    uint256 public constant override TIMEOUT_ACCEPT           = 5  minutes;
    uint256 public constant override TIMEOUT_PICKUP           = 10 minutes;
    uint256 public constant override TIMEOUT_PASSENGER_APPEAR = 10 minutes;
    uint256 public constant override TIMEOUT_CONFIRM          = 10 minutes;

    // -------------------------
    // Cancellation penalties
    // -------------------------

    /// @notice Penalty BPS when passenger cancels after driver arrived at pickup
    uint256 public constant CANCEL_PENALTY_BPS = 2000; // 20%

    // -------------------------
    // Storage
    // -------------------------

    IRegistry public immutable registry;
    IDispute  public           dispute;

    mapping(bytes32 => Session) private _sessions;

    // -------------------------
    // Constructor
    // -------------------------

    constructor(address registryAddress, address admin) {
        require(registryAddress != address(0), "RideSession: invalid registry");
        registry = IRegistry(registryAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // -------------------------
    // Session creation
    // -------------------------

    /// @notice Called by OrderBook after successful order creation
    function createSession(
        bytes32 sessionId,
        address driver,
        address passenger,
        uint256 fareAmount,
        uint256 routingFee,
        int256  pickupLat,
        int256  pickupLng,
        int256  dropoffLat,
        int256  dropoffLng,
        uint256 estimatedDistance
    ) external payable onlyRole(ORDER_BOOK_ROLE) {
        require(_sessions[sessionId].createdAt == 0, "RideSession: session exists");

        _sessions[sessionId] = Session({
            sessionId:         sessionId,
            driver:            driver,
            passenger:         passenger,
            escrowAmount:      msg.value,
            fareAmount:        fareAmount,
            routingFee:        routingFee,
            pickupLat:         pickupLat,
            pickupLng:         pickupLng,
            dropoffLat:        dropoffLat,
            dropoffLng:        dropoffLng,
            estimatedDistance: estimatedDistance,
            gpsMerkleRoot:     bytes32(0),
            state:             State.CREATED,
            createdAt:         block.timestamp,
            updatedAt:         block.timestamp
        });

        emit SessionCreated(sessionId, driver, passenger, fareAmount);
    }

    // -------------------------
    // Driver functions
    // -------------------------

    /// @inheritdoc IRideSession
    function acceptOrder(bytes32 sessionId) external {
        Session storage session = _sessions[sessionId];
        _requireDriver(session);
        _requireState(session, State.CREATED);
        _requireNotExpired(session, TIMEOUT_ACCEPT);

        _transition(session, State.ACCEPTED);
    }

    /// @inheritdoc IRideSession
    function arrivedAtPickup(bytes32 sessionId) external {
        Session storage session = _sessions[sessionId];
        _requireDriver(session);
        _requireState(session, State.ACCEPTED);
        _requireNotExpired(session, TIMEOUT_PICKUP);

        _transition(session, State.PICKING_UP);
    }

    /// @inheritdoc IRideSession
    function startTrip(bytes32 sessionId) external {
        Session storage session = _sessions[sessionId];
        _requireDriver(session);
        _requireState(session, State.PICKING_UP);
        _requireNotExpired(session, TIMEOUT_PASSENGER_APPEAR);

        _transition(session, State.IN_PROGRESS);
    }

    /// @inheritdoc IRideSession
    function completeTrip(
        bytes32 sessionId,
        bytes32 gpsMerkleRoot
    ) external {
        Session storage session = _sessions[sessionId];
        _requireDriver(session);
        _requireState(session, State.IN_PROGRESS);
        require(gpsMerkleRoot != bytes32(0), "RideSession: invalid merkle root");

        session.gpsMerkleRoot = gpsMerkleRoot;

        emit GpsMerkleRootSubmitted(sessionId, gpsMerkleRoot);
        _transition(session, State.COMPLETED);
    }

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @inheritdoc IRideSession
    function confirmTrip(bytes32 sessionId) external nonReentrant {
        Session storage session = _sessions[sessionId];
        _requirePassenger(session);
        _requireState(session, State.COMPLETED);

        _transition(session, State.CONFIRMED);
        _releaseToDriver(session);
    }

    /// @inheritdoc IRideSession
    function openDispute(bytes32 sessionId) external payable nonReentrant {
        Session storage session = _sessions[sessionId];
        _requirePassenger(session);
        _requireState(session, State.COMPLETED);
        _requireNotExpired(session, TIMEOUT_CONFIRM);
        require(address(dispute) != address(0), "RideSession: dispute contract not set");

        _transition(session, State.DISPUTED);

        emit DisputeOpened(sessionId, msg.sender);

        dispute.openDispute{value: msg.value}(
            sessionId,
            session.driver,
            session.passenger
        );
    }

    /// @inheritdoc IRideSession
    function cancelByPassenger(bytes32 sessionId) external nonReentrant {
        Session storage session = _sessions[sessionId];
        _requirePassenger(session);

        State current = session.state;
        require(
            current == State.CREATED   ||
            current == State.ACCEPTED  ||
            current == State.PICKING_UP,
            "RideSession: cannot cancel at this state"
        );

        _transition(session, State.CANCELLED);
        _executeCancellation(session, current);
    }

    // -------------------------
    // Timeout function
    // -------------------------

    /// @inheritdoc IRideSession
    function triggerTimeout(bytes32 sessionId) external nonReentrant {
        Session storage session = _sessions[sessionId];
        State current = session.state;

        if (current == State.CREATED) {
            require(
                block.timestamp > session.updatedAt + TIMEOUT_ACCEPT,
                "RideSession: timeout not reached"
            );
            _transition(session, State.EXPIRED);
            _refundPassenger(session, session.escrowAmount);

        } else if (current == State.ACCEPTED) {
            require(
                block.timestamp > session.updatedAt + TIMEOUT_PICKUP,
                "RideSession: timeout not reached"
            );
            // driver accepted but did not move — small slash
            _transition(session, State.EXPIRED);
            _refundPassenger(session, session.escrowAmount);

        } else if (current == State.PICKING_UP) {
            require(
                block.timestamp > session.updatedAt + TIMEOUT_PASSENGER_APPEAR,
                "RideSession: timeout not reached"
            );
            // passenger did not appear — driver gets penalty from escrow
            _transition(session, State.EXPIRED);
            _executeCancellation(session, State.PICKING_UP);

        } else if (current == State.COMPLETED) {
            require(
                block.timestamp > session.updatedAt + TIMEOUT_CONFIRM,
                "RideSession: timeout not reached"
            );
            // passenger did not confirm or dispute — auto release to driver
            _transition(session, State.CONFIRMED);
            _releaseToDriver(session);

        } else {
            revert("RideSession: state not eligible for timeout");
        }
    }

    // -------------------------
    // Dispute resolution
    // -------------------------

    /// @inheritdoc IRideSession
    function resolveDispute(
        bytes32 sessionId,
        bool driverWins
    ) external onlyRole(DISPUTE_ROLE) nonReentrant {
        Session storage session = _sessions[sessionId];
        _requireState(session, State.DISPUTED);

        _transition(session, State.RESOLVED);

        if (driverWins) {
            _releaseToDriver(session);
        } else {
            _refundPassenger(session, session.escrowAmount);
        }
    }

    // -------------------------
    // View functions
    // -------------------------

    /// @inheritdoc IRideSession
    function getSession(bytes32 sessionId) external view returns (Session memory) {
        return _sessions[sessionId];
    }

    /// @inheritdoc IRideSession
    function getState(bytes32 sessionId) external view returns (State) {
        return _sessions[sessionId].state;
    }

    /// @inheritdoc IRideSession
    function verifyGpsProof(
        bytes32 sessionId,
        bytes32[] calldata proof,
        bytes32 leaf
    ) external view returns (bool) {
        bytes32 root = _sessions[sessionId].gpsMerkleRoot;
        require(root != bytes32(0), "RideSession: no merkle root");
        return MerkleProof.verify(proof, root, leaf);
    }

    // -------------------------
    // Internal: fund distribution
    // -------------------------

    function _releaseToDriver(Session storage session) internal {
        uint256 amount = session.escrowAmount;
        session.escrowAmount = 0;

        // deduct driver's share of routing fee
        uint256 driverRoutingFee = session.routingFee / 2;
        uint256 payout = amount > driverRoutingFee
            ? amount - driverRoutingFee
            : 0;

        emit EscrowReleased(session.sessionId, session.driver, payout);

        (bool success, ) = session.driver.call{value: payout}("");
        require(success, "RideSession: driver transfer failed");
    }

    function _refundPassenger(
        Session storage session,
        uint256 amount
    ) internal {
        session.escrowAmount = 0;

        emit EscrowReleased(session.sessionId, session.passenger, amount);

        (bool success, ) = session.passenger.call{value: amount}("");
        require(success, "RideSession: passenger refund failed");
    }

    function _executeCancellation(
        Session storage session,
        State cancelledFrom
    ) internal {
        uint256 escrow = session.escrowAmount;
        session.escrowAmount = 0;

        if (cancelledFrom == State.CREATED || cancelledFrom == State.ACCEPTED) {
            // full refund to passenger
            _refundPassenger(session, escrow);

        } else if (cancelledFrom == State.PICKING_UP) {
            // 20% penalty to driver, rest to passenger
            uint256 penalty = (escrow * CANCEL_PENALTY_BPS) / 10000;
            uint256 refund  = escrow - penalty;

            emit EscrowReleased(session.sessionId, session.driver, penalty);
            emit EscrowReleased(session.sessionId, session.passenger, refund);

            (bool d, ) = session.driver.call{value: penalty}("");
            require(d, "RideSession: driver penalty transfer failed");

            (bool p, ) = session.passenger.call{value: refund}("");
            require(p, "RideSession: passenger refund failed");
        }
    }

    // -------------------------
    // Internal: guards
    // -------------------------

    function _requireDriver(Session storage session) internal view {
        require(msg.sender == session.driver, "RideSession: not driver");
    }

    function _requirePassenger(Session storage session) internal view {
        require(msg.sender == session.passenger, "RideSession: not passenger");
    }

    function _requireState(Session storage session, State expected) internal view {
        require(session.state == expected, "RideSession: invalid state");
    }

    function _requireNotExpired(
        Session storage session,
        uint256 timeout
    ) internal view {
        require(
            block.timestamp <= session.updatedAt + timeout,
            "RideSession: session expired"
        );
    }

    function _transition(Session storage session, State newState) internal {
        emit StateChanged(session.sessionId, session.state, newState);
        session.state     = newState;
        session.updatedAt = block.timestamp;
    }

    // -------------------------
    // Admin functions
    // -------------------------

    function setDisputeContract(
        address disputeAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(disputeAddress != address(0), "RideSession: invalid address");
        dispute = IDispute(disputeAddress);
        _grantRole(DISPUTE_ROLE, disputeAddress);
    }

    function setOrderBookContract(
        address orderBook
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORDER_BOOK_ROLE, orderBook);
    }

    // -------------------------
    // Fallback
    // -------------------------

    receive() external payable {
        revert("RideSession: use createSession");
    }
}

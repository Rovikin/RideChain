// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Registry.sol";
import "../contracts/OrderBook.sol";
import "../contracts/RideSession.sol";
import "../contracts/interfaces/IRegistry.sol";
import "../contracts/interfaces/IOrderBook.sol";
import "../contracts/interfaces/IRideSession.sol";

/// @notice Mock Dispute contract for isolated RideSession testing
contract MockDispute {
    bool public disputeOpened;
    bytes32 public lastSessionId;

    function openDispute(
        bytes32 sessionId,
        address,
        address
    ) external payable returns (bytes32) {
        disputeOpened  = true;
        lastSessionId  = sessionId;
        return keccak256(abi.encodePacked(sessionId));
    }
}

contract RideSessionTest is Test {

    Registry    registry;
    OrderBook   orderBook;
    RideSession rideSession;
    MockDispute mockDispute;

    address admin       = makeAddr("admin");
    address driver1     = makeAddr("driver1");
    address passenger1  = makeAddr("passenger1");
    address routingNode = makeAddr("routingNode");

    bytes32 constant KYC_DRIVER    = keccak256("driver1-kyc");
    bytes32 constant KYC_PASSENGER = keccak256("passenger1-kyc");

    uint256 constant DRIVER_DEPOSIT  = 2 ether;
    uint256 constant FARE_PER_KM     = 0.001 ether;
    uint256 constant DISTANCE_METERS = 5000;

    int256 constant PICKUP_LAT  = -6200000;
    int256 constant PICKUP_LNG  =  106816667;
    int256 constant DROPOFF_LAT = -6210000;
    int256 constant DROPOFF_LNG =  106820000;

    bytes32 sessionId;
    uint256 fareAmount;
    uint256 escrowAmount;

    // -------------------------
    // Setup
    // -------------------------

    function setUp() public {
        registry    = new Registry(admin);
        orderBook   = new OrderBook(address(registry), admin);
        rideSession = new RideSession(address(registry), admin);
        mockDispute = new MockDispute();

        // wire contracts
        vm.startPrank(admin);
        registry.setRideSessionContract(address(rideSession));
        rideSession.setDisputeContract(address(mockDispute));
        rideSession.setOrderBookContract(address(orderBook));
        vm.stopPrank();

        vm.deal(driver1,    10 ether);
        vm.deal(passenger1, 10 ether);

        // register driver
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        // register passenger
        vm.prank(passenger1);
        registry.registerPassenger(KYC_PASSENGER);

        // create a session for use in tests
        _createSession();
    }

    // -------------------------
    // acceptOrder
    // -------------------------

    function test_AcceptOrder_Success() public {
        vm.prank(driver1);
        rideSession.acceptOrder(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.ACCEPTED)
        );
    }

    function test_AcceptOrder_EmitsStateChanged() public {
        vm.expectEmit(true, false, false, true);
        emit IRideSession.StateChanged(
            sessionId,
            IRideSession.State.CREATED,
            IRideSession.State.ACCEPTED
        );

        vm.prank(driver1);
        rideSession.acceptOrder(sessionId);
    }

    function test_AcceptOrder_RevertIf_NotDriver() public {
        vm.prank(passenger1);
        vm.expectRevert("RideSession: not driver");
        rideSession.acceptOrder(sessionId);
    }

    function test_AcceptOrder_RevertIf_WrongState() public {
        vm.prank(driver1);
        rideSession.acceptOrder(sessionId);

        // already ACCEPTED — cannot accept again
        vm.prank(driver1);
        vm.expectRevert("RideSession: invalid state");
        rideSession.acceptOrder(sessionId);
    }

    function test_AcceptOrder_RevertIf_Expired() public {
        vm.warp(block.timestamp + rideSession.TIMEOUT_ACCEPT() + 1);

        vm.prank(driver1);
        vm.expectRevert("RideSession: session expired");
        rideSession.acceptOrder(sessionId);
    }

    // -------------------------
    // arrivedAtPickup
    // -------------------------

    function test_ArrivedAtPickup_Success() public {
        _accept();

        vm.prank(driver1);
        rideSession.arrivedAtPickup(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.PICKING_UP)
        );
    }

    function test_ArrivedAtPickup_RevertIf_WrongState() public {
        vm.prank(driver1);
        vm.expectRevert("RideSession: invalid state");
        rideSession.arrivedAtPickup(sessionId);
    }

    // -------------------------
    // startTrip
    // -------------------------

    function test_StartTrip_Success() public {
        _accept();
        _arrivedAtPickup();

        vm.prank(driver1);
        rideSession.startTrip(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.IN_PROGRESS)
        );
    }

    function test_StartTrip_RevertIf_PassengerTimeout() public {
        _accept();
        _arrivedAtPickup();

        vm.warp(block.timestamp + rideSession.TIMEOUT_PASSENGER_APPEAR() + 1);

        vm.prank(driver1);
        vm.expectRevert("RideSession: session expired");
        rideSession.startTrip(sessionId);
    }

    // -------------------------
    // completeTrip
    // -------------------------

    function test_CompleteTrip_Success() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();

        bytes32 merkleRoot = keccak256("gps-route-data");

        vm.prank(driver1);
        rideSession.completeTrip(sessionId, merkleRoot);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.COMPLETED)
        );

        IRideSession.Session memory s = rideSession.getSession(sessionId);
        assertEq(s.gpsMerkleRoot, merkleRoot);
    }

    function test_CompleteTrip_EmitsMerkleRoot() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();

        bytes32 merkleRoot = keccak256("gps-route-data");

        vm.expectEmit(true, false, false, true);
        emit IRideSession.GpsMerkleRootSubmitted(sessionId, merkleRoot);

        vm.prank(driver1);
        rideSession.completeTrip(sessionId, merkleRoot);
    }

    function test_CompleteTrip_RevertIf_EmptyMerkleRoot() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();

        vm.prank(driver1);
        vm.expectRevert("RideSession: invalid merkle root");
        rideSession.completeTrip(sessionId, bytes32(0));
    }

    // -------------------------
    // confirmTrip
    // -------------------------

    function test_ConfirmTrip_ReleasesEscrowToDriver() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        uint256 driverBefore = driver1.balance;

        vm.prank(passenger1);
        rideSession.confirmTrip(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.CONFIRMED)
        );

        // driver received fare minus driver's routing fee share
        assertGt(driver1.balance, driverBefore);
    }

    function test_ConfirmTrip_RevertIf_NotPassenger() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.prank(driver1);
        vm.expectRevert("RideSession: not passenger");
        rideSession.confirmTrip(sessionId);
    }

    // -------------------------
    // openDispute
    // -------------------------

    function test_OpenDispute_Success() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        uint256 arbiterFee = 0.01 ether;

        vm.prank(passenger1);
        rideSession.openDispute{value: arbiterFee}(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.DISPUTED)
        );
        assertTrue(mockDispute.disputeOpened());
        assertEq(mockDispute.lastSessionId(), sessionId);
    }

    function test_OpenDispute_RevertIf_NotPassenger() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.prank(driver1);
        vm.expectRevert("RideSession: not passenger");
        rideSession.openDispute{value: 0.01 ether}(sessionId);
    }

    function test_OpenDispute_RevertIf_WrongState() public {
        _accept();

        vm.prank(passenger1);
        vm.expectRevert("RideSession: invalid state");
        rideSession.openDispute{value: 0.01 ether}(sessionId);
    }

    // -------------------------
    // cancelByPassenger
    // -------------------------

    function test_CancelByPassenger_AtCreated_FullRefund() public {
        uint256 balanceBefore = passenger1.balance;

        vm.prank(passenger1);
        rideSession.cancelByPassenger(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.CANCELLED)
        );

        // full refund — passenger gets escrow back
        assertGt(passenger1.balance, balanceBefore);
    }

    function test_CancelByPassenger_AtPickingUp_PenaltyToDriver() public {
        _accept();
        _arrivedAtPickup();

        uint256 driverBefore    = driver1.balance;
        uint256 passengerBefore = passenger1.balance;

        vm.prank(passenger1);
        rideSession.cancelByPassenger(sessionId);

        // driver received penalty
        assertGt(driver1.balance, driverBefore);

        // passenger received refund minus penalty
        assertGt(passenger1.balance, passengerBefore);

        // penalty + refund = escrow
        uint256 driverGained    = driver1.balance - driverBefore;
        uint256 passengerGained = passenger1.balance - passengerBefore;
        assertEq(driverGained + passengerGained, escrowAmount);
    }

    function test_CancelByPassenger_RevertIf_InProgress() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();

        vm.prank(passenger1);
        vm.expectRevert("RideSession: cannot cancel at this state");
        rideSession.cancelByPassenger(sessionId);
    }

    // -------------------------
    // triggerTimeout
    // -------------------------

    function test_TriggerTimeout_AtCreated_RefundsPassenger() public {
        vm.warp(block.timestamp + rideSession.TIMEOUT_ACCEPT() + 1);

        uint256 balanceBefore = passenger1.balance;

        rideSession.triggerTimeout(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.EXPIRED)
        );
        assertGt(passenger1.balance, balanceBefore);
    }

    function test_TriggerTimeout_AtCompleted_ReleasesToDriver() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.warp(block.timestamp + rideSession.TIMEOUT_CONFIRM() + 1);

        uint256 driverBefore = driver1.balance;

        rideSession.triggerTimeout(sessionId);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.CONFIRMED)
        );
        assertGt(driver1.balance, driverBefore);
    }

    function test_TriggerTimeout_RevertIf_TooEarly() public {
        vm.expectRevert("RideSession: timeout not reached");
        rideSession.triggerTimeout(sessionId);
    }

    // -------------------------
    // resolveDispute
    // -------------------------

    function test_ResolveDispute_DriverWins_ReleasesToDriver() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.prank(passenger1);
        rideSession.openDispute{value: 0.01 ether}(sessionId);

        uint256 driverBefore = driver1.balance;

        vm.prank(address(mockDispute));
        rideSession.resolveDispute(sessionId, true);

        assertEq(
            uint8(rideSession.getState(sessionId)),
            uint8(IRideSession.State.RESOLVED)
        );
        assertGt(driver1.balance, driverBefore);
    }

    function test_ResolveDispute_PassengerWins_RefundsPassenger() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.prank(passenger1);
        rideSession.openDispute{value: 0.01 ether}(sessionId);

        uint256 passengerBefore = passenger1.balance;

        vm.prank(address(mockDispute));
        rideSession.resolveDispute(sessionId, false);

        assertGt(passenger1.balance, passengerBefore);
    }

    function test_ResolveDispute_RevertIf_NotDisputeContract() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();
        _completeTrip();

        vm.prank(passenger1);
        rideSession.openDispute{value: 0.01 ether}(sessionId);

        vm.prank(driver1);
        vm.expectRevert();
        rideSession.resolveDispute(sessionId, true);
    }

    // -------------------------
    // verifyGpsProof
    // -------------------------

    function test_VerifyGpsProof_ValidProof() public {
        _accept();
        _arrivedAtPickup();
        _startTrip();

        // build a simple 1-leaf Merkle tree
        bytes32 leaf = keccak256(abi.encodePacked(
            DROPOFF_LAT,
            DROPOFF_LNG,
            uint256(1000),
            uint256(42)
        ));
        bytes32 merkleRoot = leaf; // single leaf — root equals leaf

        vm.prank(driver1);
        rideSession.completeTrip(sessionId, merkleRoot);

        bytes32[] memory proof = new bytes32[](0);
        assertTrue(rideSession.verifyGpsProof(sessionId, proof, leaf));
    }

    // -------------------------
    // Fuzz tests
    // -------------------------

    function testFuzz_CancelPenaltyNeverExceedsEscrow(
        uint256 escrow
    ) public {
        vm.assume(escrow >= 0.01 ether && escrow <= 5 ether);

        // create new session with custom escrow
        bytes32 newSessionId = _createSessionWithEscrow(escrow);

        _acceptSession(newSessionId);
        _arrivedAtPickupSession(newSessionId);

        uint256 driverBefore    = driver1.balance;
        uint256 passengerBefore = passenger1.balance;

        vm.prank(passenger1);
        rideSession.cancelByPassenger(newSessionId);

        uint256 driverGained    = driver1.balance    - driverBefore;
        uint256 passengerGained = passenger1.balance - passengerBefore;

        // penalty + refund must equal escrow exactly
        assertEq(driverGained + passengerGained, escrow);

        // penalty must never exceed 20% of escrow
        assertLe(driverGained, escrow * 2000 / 10000);
    }

    // -------------------------
    // Helpers
    // -------------------------

    function _createSession() internal {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (uint256 fare, uint256 routingFee, uint256 total) =
            orderBook.calculateFare(driver1, DISTANCE_METERS);

        fareAmount   = fare;
        escrowAmount = fare + orderBook.GAS_BUFFER();
        uint256 payment = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        sessionId = orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function _createSessionWithEscrow(
        uint256 escrow
    ) internal returns (bytes32 newSessionId) {
        address newPassenger = makeAddr(string(abi.encodePacked("p", escrow)));
        vm.deal(newPassenger, escrow + 1 ether);

        vm.prank(newPassenger);
        registry.registerPassenger(keccak256(abi.encodePacked("kyc", escrow)));

        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment = total + orderBook.GAS_BUFFER();

        vm.prank(newPassenger);
        newSessionId = orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function _accept() internal {
        vm.prank(driver1);
        rideSession.acceptOrder(sessionId);
    }

    function _acceptSession(bytes32 sid) internal {
        vm.prank(driver1);
        rideSession.acceptOrder(sid);
    }

    function _arrivedAtPickup() internal {
        vm.prank(driver1);
        rideSession.arrivedAtPickup(sessionId);
    }

    function _arrivedAtPickupSession(bytes32 sid) internal {
        vm.prank(driver1);
        rideSession.arrivedAtPickup(sid);
    }

    function _startTrip() internal {
        vm.prank(driver1);
        rideSession.startTrip(sessionId);
    }

    function _completeTrip() internal {
        vm.prank(driver1);
        rideSession.completeTrip(sessionId, keccak256("gps-route-data"));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Registry.sol";
import "../contracts/OrderBook.sol";
import "../contracts/RideSession.sol";
import "../contracts/Dispute.sol";
import "../contracts/interfaces/IRegistry.sol";
import "../contracts/interfaces/IDispute.sol";

contract DisputeTest is Test {

    Registry    registry;
    OrderBook   orderBook;
    RideSession rideSession;
    Dispute     dispute;

    address admin       = makeAddr("admin");
    address driver1     = makeAddr("driver1");
    address passenger1  = makeAddr("passenger1");
    address arbiter1    = makeAddr("arbiter1");
    address arbiter2    = makeAddr("arbiter2");
    address arbiter3    = makeAddr("arbiter3");
    address routingNode = makeAddr("routingNode");

    bytes32 constant KYC_DRIVER    = keccak256("driver1-kyc");
    bytes32 constant KYC_PASSENGER = keccak256("passenger1-kyc");

    uint256 constant DRIVER_DEPOSIT   = 2 ether;
    uint256 constant ARBITER_DEPOSIT  = 1 ether;
    uint256 constant FARE_PER_KM      = 0.001 ether;
    uint256 constant DISTANCE_METERS  = 5000;
    uint256 constant ARBITER_FEE      = 0.01 ether;

    int256 constant PICKUP_LAT  = -6200000;
    int256 constant PICKUP_LNG  =  106816667;
    int256 constant DROPOFF_LAT = -6210000;
    int256 constant DROPOFF_LNG =  106820000;

    bytes32 sessionId;

    // -------------------------
    // Setup
    // -------------------------

    function setUp() public {
        registry    = new Registry(admin);
        orderBook   = new OrderBook(address(registry), admin);
        rideSession = new RideSession(address(registry), admin);
        dispute     = new Dispute(
            address(registry),
            address(rideSession),
            admin
        );

        // wire contracts
        vm.startPrank(admin);
        registry.setRideSessionContract(address(rideSession));
        registry.setDisputeContract(address(dispute));
        orderBook.setRideSessionContract(address(rideSession));
        rideSession.setDisputeContract(address(dispute));
        rideSession.setOrderBookContract(address(orderBook));
        vm.stopPrank();

        vm.deal(driver1,    10 ether);
        vm.deal(passenger1, 10 ether);
        vm.deal(arbiter1,   10 ether);
        vm.deal(arbiter2,   10 ether);
        vm.deal(arbiter3,   10 ether);

        // register participants
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        vm.prank(passenger1);
        registry.registerPassenger(KYC_PASSENGER);

        // register arbiters
        vm.prank(arbiter1);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();
        vm.prank(arbiter2);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();
        vm.prank(arbiter3);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();

        // create and progress session to COMPLETED
        sessionId = _createAndCompleteSession();
    }

    // -------------------------
    // openDispute
    // -------------------------

    function test_OpenDispute_Success() public {
        bytes32 disputeId = _openDispute();

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertEq(d.sessionId,  sessionId);
        assertEq(d.driver,     driver1);
        assertEq(d.passenger,  passenger1);
        assertEq(d.arbiterFee, ARBITER_FEE);
        assertEq(
            uint8(d.status),
            uint8(IDispute.DisputeStatus.PENDING)
        );
    }

    function test_OpenDispute_AssignsActiveArbiter() public {
        bytes32 disputeId = _openDispute();

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertTrue(
            d.arbiter == arbiter1 ||
            d.arbiter == arbiter2 ||
            d.arbiter == arbiter3
        );
    }

    function test_OpenDispute_EmitsDisputeCreated() public {
        vm.prank(passenger1);
        vm.expectEmit(false, true, false, false);
        emit IDispute.DisputeCreated(bytes32(0), sessionId, address(0), 0);

        rideSession.openDispute{value: ARBITER_FEE}(sessionId);
    }

    function test_OpenDispute_RevertIf_NoDuplicates() public {
        _openDispute();

        // try to open again on same session
        bytes32 newSessionId = _createAndCompleteSession();
        assertTrue(newSessionId != sessionId);
    }

    function test_HasActiveDispute_True() public {
        _openDispute();
        assertTrue(dispute.hasActiveDispute(sessionId));
    }

    function test_HasActiveDispute_False_BeforeDispute() public {
        assertFalse(dispute.hasActiveDispute(sessionId));
    }

    // -------------------------
    // acceptDispute
    // -------------------------

    function test_AcceptDispute_Success() public {
        bytes32 disputeId = _openDispute();

        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        assertEq(
            uint8(dispute.getDispute(disputeId).status),
            uint8(IDispute.DisputeStatus.IN_REVIEW)
        );
    }

    function test_AcceptDispute_RevertIf_NotAssignedArbiter() public {
        bytes32 disputeId = _openDispute();

        address assignedArbiter = dispute.getDispute(disputeId).arbiter;
        address wrongArbiter    = _getOtherArbiter(assignedArbiter);

        vm.prank(wrongArbiter);
        vm.expectRevert("Dispute: not assigned arbiter");
        dispute.acceptDispute(disputeId);
    }

    function test_AcceptDispute_RevertIf_ResponseTimeout() public {
        bytes32 disputeId = _openDispute();

        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.warp(block.timestamp + dispute.TIMEOUT_ARBITER_RESPOND() + 1);

        vm.prank(assignedArbiter);
        vm.expectRevert("Dispute: response timeout passed");
        dispute.acceptDispute(disputeId);
    }

    // -------------------------
    // resolveDispute
    // -------------------------

    function test_ResolveDispute_DriverWins() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        uint256 driverBefore = driver1.balance;

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true);

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertEq(
            uint8(d.status),
            uint8(IDispute.DisputeStatus.RESOLVED)
        );
        assertTrue(d.driverWins);
        assertGt(driver1.balance, driverBefore);
    }

    function test_ResolveDispute_PassengerWins() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        uint256 passengerBefore = passenger1.balance;

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, false);

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertFalse(d.driverWins);
        assertGt(passenger1.balance, passengerBefore);
    }

    function test_ResolveDispute_EmitsDisputeResolved() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.expectEmit(true, true, false, true);
        emit IDispute.DisputeResolved(disputeId, assignedArbiter, true);

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true);
    }

    function test_ResolveDispute_RevertIf_NotArbiter() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.prank(driver1);
        vm.expectRevert("Dispute: not assigned arbiter");
        dispute.resolveDispute(disputeId, true);
    }

    function test_ResolveDispute_RevertIf_NotInReview() public {
        bytes32 disputeId = _openDispute();

        // still PENDING — not accepted yet
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;
        vm.prank(assignedArbiter);
        vm.expectRevert("Dispute: not in review");
        dispute.resolveDispute(disputeId, true);
    }

    function test_ResolveDispute_RevertIf_DeadlinePassed() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.warp(block.timestamp + dispute.TIMEOUT_ARBITER_RESOLVE() + 1);

        vm.prank(assignedArbiter);
        vm.expectRevert("Dispute: resolve deadline passed");
        dispute.resolveDispute(disputeId, true);
    }

    // -------------------------
    // triggerReassignment
    // -------------------------

    function test_TriggerReassignment_AfterResponseTimeout() public {
        bytes32 disputeId   = _openDispute();
        address oldArbiter  = dispute.getDispute(disputeId).arbiter;

        vm.warp(block.timestamp + dispute.TIMEOUT_ARBITER_RESPOND() + 1);

        dispute.triggerReassignment(disputeId);

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertEq(uint8(d.status), uint8(IDispute.DisputeStatus.PENDING));

        // new arbiter assigned
        assertTrue(d.arbiter != address(0));

        emit IDispute.ArbiterReassigned(disputeId, oldArbiter, d.arbiter);
    }

    function test_TriggerReassignment_SlashesNonResponsiveArbiter() public {
        bytes32 disputeId  = _openDispute();
        address oldArbiter = dispute.getDispute(disputeId).arbiter;

        uint256 depositBefore = registry.getArbiter(oldArbiter).depositAmount;

        vm.warp(block.timestamp + dispute.TIMEOUT_ARBITER_RESPOND() + 1);
        dispute.triggerReassignment(disputeId);

        uint256 depositAfter = registry.getArbiter(oldArbiter).depositAmount;
        assertLt(depositAfter, depositBefore);
    }

    function test_TriggerReassignment_RevertIf_TooEarly() public {
        bytes32 disputeId = _openDispute();

        vm.expectRevert("Dispute: response timeout not reached");
        dispute.triggerReassignment(disputeId);
    }

    function test_TriggerReassignment_AfterReviewTimeout() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.warp(block.timestamp + dispute.TIMEOUT_ARBITER_RESOLVE() + 1);

        dispute.triggerReassignment(disputeId);

        IDispute.Dispute memory d = dispute.getDispute(disputeId);
        assertEq(uint8(d.status), uint8(IDispute.DisputeStatus.PENDING));
    }

    // -------------------------
    // rateArbiter
    // -------------------------

    function test_RateArbiter_WinnerCanRate() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true); // driver wins

        uint256 ratingBefore = registry.getArbiter(assignedArbiter).ratingTotal;

        vm.prank(driver1);
        dispute.rateArbiter(disputeId, 5);

        assertGt(
            registry.getArbiter(assignedArbiter).ratingTotal,
            ratingBefore
        );
    }

    function test_RateArbiter_RevertIf_LoserTriesToRate() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true); // driver wins

        // passenger (loser) tries to rate
        vm.prank(passenger1);
        vm.expectRevert("Dispute: only winner can rate");
        dispute.rateArbiter(disputeId, 1);
    }

    function test_RateArbiter_RevertIf_InvalidRating() public {
        bytes32 disputeId       = _openDispute();
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true);

        vm.prank(driver1);
        vm.expectRevert("Dispute: invalid rating");
        dispute.rateArbiter(disputeId, 6);
    }

    function test_RateArbiter_RevertIf_NotResolved() public {
        bytes32 disputeId = _openDispute();

        vm.prank(driver1);
        vm.expectRevert("Dispute: not resolved");
        dispute.rateArbiter(disputeId, 5);
    }

    // -------------------------
    // getDisputeBySession
    // -------------------------

    function test_GetDisputeBySession_ReturnsCorrectDispute() public {
        bytes32 disputeId = _openDispute();

        IDispute.Dispute memory d = dispute.getDisputeBySession(sessionId);
        assertEq(d.disputeId, disputeId);
        assertEq(d.sessionId, sessionId);
    }

    // -------------------------
    // Fuzz tests
    // -------------------------

    function testFuzz_ArbiterFeeAlwaysGoesToArbiter(
        uint256 fee
    ) public {
        vm.assume(fee >= 0.001 ether && fee <= 1 ether);
        vm.deal(passenger1, fee + 5 ether);

        // create fresh session
        bytes32 newSessionId = _createAndCompleteSession();

        bytes32 disputeId = _openDisputeWithFee(newSessionId, fee);
        address assignedArbiter = dispute.getDispute(disputeId).arbiter;

        vm.prank(assignedArbiter);
        dispute.acceptDispute(disputeId);

        uint256 arbiterBefore = assignedArbiter.balance;

        vm.prank(assignedArbiter);
        dispute.resolveDispute(disputeId, true);

        // arbiter received their fee
        assertGt(assignedArbiter.balance, arbiterBefore);
    }

    // -------------------------
    // Helpers
    // -------------------------

    function _createAndCompleteSession() internal returns (bytes32 sid) {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (, , uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment     = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        sid = orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );

        vm.prank(driver1); rideSession.acceptOrder(sid);
        vm.prank(driver1); rideSession.arrivedAtPickup(sid);
        vm.prank(driver1); rideSession.startTrip(sid);
        vm.prank(driver1); rideSession.completeTrip(sid, keccak256("gps"));
    }

    function _openDispute() internal returns (bytes32 disputeId) {
        return _openDisputeWithFee(sessionId, ARBITER_FEE);
    }

    function _openDisputeWithFee(
        bytes32 sid,
        uint256 fee
    ) internal returns (bytes32 disputeId) {
        vm.prank(passenger1);
        rideSession.openDispute{value: fee}(sid);

        return dispute.getDisputeBySession(sid).disputeId;
    }

    function _getOtherArbiter(
        address assigned
    ) internal view returns (address) {
        if (assigned != arbiter1) return arbiter1;
        if (assigned != arbiter2) return arbiter2;
        return arbiter3;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Registry.sol";
import "../contracts/OrderBook.sol";
import "../contracts/interfaces/IRegistry.sol";
import "../contracts/interfaces/IOrderBook.sol";

contract OrderBookTest is Test {

    Registry  registry;
    OrderBook orderBook;

    address admin      = makeAddr("admin");
    address driver1    = makeAddr("driver1");
    address driver2    = makeAddr("driver2");
    address passenger1 = makeAddr("passenger1");
    address routingNode = makeAddr("routingNode");

    bytes32 constant KYC_DRIVER    = keccak256("driver1-kyc");
    bytes32 constant KYC_PASSENGER = keccak256("passenger1-kyc");

    uint256 constant DRIVER_DEPOSIT   = 2 ether;
    uint256 constant FARE_PER_KM      = 0.001 ether;   // 1000 gwei per km
    uint256 constant DISTANCE_METERS  = 5000;           // 5 km

    // Jakarta coordinates × 1e6
    int256 constant PICKUP_LAT  = -6200000;
    int256 constant PICKUP_LNG  =  106816667;
    int256 constant DROPOFF_LAT = -6210000;
    int256 constant DROPOFF_LNG =  106820000;

    // -------------------------
    // Setup
    // -------------------------

    function setUp() public {
        registry  = new Registry(admin);
        orderBook = new OrderBook(address(registry), admin);

        vm.deal(driver1,    10 ether);
        vm.deal(driver2,    10 ether);
        vm.deal(passenger1, 10 ether);

        // register and setup driver1
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        // register passenger1
        vm.prank(passenger1);
        registry.registerPassenger(KYC_PASSENGER);
    }

    // -------------------------
    // publishAsk
    // -------------------------

    function test_PublishAsk_Success() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        IOrderBook.DriverAsk memory ask = orderBook.getDriverAsk(driver1);
        assertEq(ask.wallet,    driver1);
        assertEq(ask.farePerKm, FARE_PER_KM);
        assertEq(ask.lat,       PICKUP_LAT);
        assertEq(ask.lng,       PICKUP_LNG);
        assertTrue(ask.available);
    }

    function test_PublishAsk_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit IOrderBook.DriverAskPublished(driver1, FARE_PER_KM);

        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);
    }

    function test_PublishAsk_RevertIf_ZeroFare() public {
        vm.prank(driver1);
        vm.expectRevert("OrderBook: fare must be greater than zero");
        orderBook.publishAsk(0, PICKUP_LAT, PICKUP_LNG);
    }

    function test_PublishAsk_RevertIf_DriverNotRegistered() public {
        address unknown = makeAddr("unknown");
        vm.prank(unknown);
        vm.expectRevert("OrderBook: driver not registered");
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);
    }

    function test_PublishAsk_UpdatesExistingAsk() public {
        vm.startPrank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        uint256 newFare = FARE_PER_KM * 2;
        orderBook.publishAsk(newFare, PICKUP_LAT, PICKUP_LNG);
        vm.stopPrank();

        IOrderBook.DriverAsk memory ask = orderBook.getDriverAsk(driver1);
        assertEq(ask.farePerKm, newFare);
    }

    // -------------------------
    // updatePosition
    // -------------------------

    function test_UpdatePosition_Success() public {
        vm.startPrank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        int256 newLat = -6205000;
        int256 newLng =  106818000;
        orderBook.updatePosition(newLat, newLng);
        vm.stopPrank();

        IOrderBook.DriverAsk memory ask = orderBook.getDriverAsk(driver1);
        assertEq(ask.lat, newLat);
        assertEq(ask.lng, newLng);
    }

    function test_UpdatePosition_RevertIf_NoAsk() public {
        vm.prank(driver1);
        vm.expectRevert("OrderBook: ask not found");
        orderBook.updatePosition(PICKUP_LAT, PICKUP_LNG);
    }

    function test_UpdatePosition_RevertIf_AskWithdrawn() public {
        vm.startPrank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);
        orderBook.withdrawAsk();

        vm.expectRevert("OrderBook: ask not active");
        orderBook.updatePosition(PICKUP_LAT, PICKUP_LNG);
        vm.stopPrank();
    }

    // -------------------------
    // withdrawAsk
    // -------------------------

    function test_WithdrawAsk_Success() public {
        vm.startPrank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);
        orderBook.withdrawAsk();
        vm.stopPrank();

        IOrderBook.DriverAsk memory ask = orderBook.getDriverAsk(driver1);
        assertFalse(ask.available);
    }

    function test_WithdrawAsk_EmitsEvent() public {
        vm.startPrank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        vm.expectEmit(true, false, false, false);
        emit IOrderBook.DriverAskWithdrawn(driver1);

        orderBook.withdrawAsk();
        vm.stopPrank();
    }

    // -------------------------
    // calculateFare
    // -------------------------

    function test_CalculateFare_Correct() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (uint256 fare, uint256 routingFee, uint256 total) =
            orderBook.calculateFare(driver1, DISTANCE_METERS);

        // fare = 0.001 ether × 5000 / 1000 = 0.005 ether
        assertEq(fare, 0.005 ether);

        // routingFee = 0.005 ether × 50 / 10000 = 0.000025 ether
        assertEq(routingFee, 0.000025 ether);

        // total = fare + routingFee
        assertEq(total, fare + routingFee);
    }

    function test_CalculateFare_RevertIf_NoAsk() public {
        vm.expectRevert("OrderBook: ask not found");
        orderBook.calculateFare(driver1, DISTANCE_METERS);
    }

    // -------------------------
    // createOrder
    // -------------------------

    function test_CreateOrder_Success() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment    = total + orderBook.GAS_BUFFER();

        uint256 routingNodeBefore = routingNode.balance;

        vm.prank(passenger1);
        bytes32 orderId = orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );

        assertTrue(orderId != bytes32(0));

        // routing node received routing fee
        IOrderBook.OrderRequest memory order = orderBook.getOrder(orderId);
        assertGt(routingNode.balance, routingNodeBefore);
        assertTrue(order.matched);
        assertEq(order.passenger, passenger1);
    }

    function test_CreateOrder_EmitsOrderCreated() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment    = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        vm.expectEmit(false, true, true, false);
        emit IOrderBook.OrderCreated(bytes32(0), passenger1, driver1, 0);

        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function test_CreateOrder_DriverUnavailableAfterMatch() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment    = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );

        IOrderBook.DriverAsk memory ask = orderBook.getDriverAsk(driver1);
        assertFalse(ask.available);
    }

    function test_CreateOrder_RefundsExcess() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 excess  = 0.1 ether;
        uint256 payment = total + orderBook.GAS_BUFFER() + excess;

        uint256 balanceBefore = passenger1.balance;

        vm.prank(passenger1);
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );

        // excess should be refunded
        assertApproxEqAbs(
            passenger1.balance,
            balanceBefore - total - orderBook.GAS_BUFFER(),
            0.0001 ether
        );
    }

    function test_CreateOrder_RevertIf_InsufficientPayment() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        vm.prank(passenger1);
        vm.expectRevert("OrderBook: insufficient payment");
        orderBook.createOrder{value: 0.001 ether}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function test_CreateOrder_RevertIf_DriverNotAvailable() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment = total + orderBook.GAS_BUFFER();

        // first order — succeeds
        vm.prank(passenger1);
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );

        // second order — driver already matched
        address passenger2 = makeAddr("passenger2");
        vm.deal(passenger2, 10 ether);
        vm.prank(passenger2);
        vm.expectRevert("OrderBook: driver not available");
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function test_CreateOrder_RevertIf_DriverPositionStale() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        // warp past stale threshold
        vm.warp(block.timestamp + orderBook.DRIVER_STALE_THRESHOLD() + 1);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        vm.expectRevert("OrderBook: driver position stale");
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            routingNode
        );
    }

    function test_CreateOrder_RevertIf_InvalidRoutingNode() public {
        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (,, uint256 total) = orderBook.calculateFare(driver1, DISTANCE_METERS);
        uint256 payment = total + orderBook.GAS_BUFFER();

        vm.prank(passenger1);
        vm.expectRevert("OrderBook: invalid routing node");
        orderBook.createOrder{value: payment}(
            driver1,
            PICKUP_LAT,
            PICKUP_LNG,
            DROPOFF_LAT,
            DROPOFF_LNG,
            DISTANCE_METERS,
            address(0)
        );
    }

    // -------------------------
    // Fuzz tests
    // -------------------------

    function testFuzz_FareAlwaysProportionalToDistance(
        uint256 distance
    ) public {
        vm.assume(distance > 0 && distance <= 100_000); // max 100 km

        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (uint256 fare,,) = orderBook.calculateFare(driver1, distance);

        // fare should always be farePerKm × distance / 1000
        assertEq(fare, (FARE_PER_KM * distance) / 1000);
    }

    function testFuzz_RoutingFeeAlways0Point5Percent(
        uint256 distance
    ) public {
        vm.assume(distance > 0 && distance <= 100_000);

        vm.prank(driver1);
        orderBook.publishAsk(FARE_PER_KM, PICKUP_LAT, PICKUP_LNG);

        (uint256 fare, uint256 routingFee,) =
            orderBook.calculateFare(driver1, distance);

        // routingFee should always be 0.5% of fare
        assertEq(routingFee, (fare * 50) / 10000);
    }
}

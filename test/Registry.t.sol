// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Registry.sol";
import "../contracts/interfaces/IRegistry.sol";

contract RegistryTest is Test {

    Registry registry;

    address admin     = makeAddr("admin");
    address driver1   = makeAddr("driver1");
    address driver2   = makeAddr("driver2");
    address passenger1 = makeAddr("passenger1");
    address arbiter1  = makeAddr("arbiter1");
    address arbiter2  = makeAddr("arbiter2");
    address arbiter3  = makeAddr("arbiter3");

    bytes32 constant KYC_HASH_DRIVER    = keccak256("driver1-kyc-documents");
    bytes32 constant KYC_HASH_PASSENGER = keccak256("passenger1-kyc-documents");

    uint256 constant DRIVER_DEPOSIT   = 1 ether;
    uint256 constant ARBITER_DEPOSIT  = 0.5 ether;
    uint256 constant FARE_PER_KM      = 0.001 ether;

    // -------------------------
    // Setup
    // -------------------------

    function setUp() public {
        registry = new Registry(admin);

        // fund test accounts
        vm.deal(driver1,    10 ether);
        vm.deal(driver2,    10 ether);
        vm.deal(passenger1, 10 ether);
        vm.deal(arbiter1,   10 ether);
        vm.deal(arbiter2,   10 ether);
        vm.deal(arbiter3,   10 ether);
    }

    // -------------------------
    // Driver registration
    // -------------------------

    function test_RegisterDriver_Success() public {
        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertEq(d.wallet,        driver1);
        assertEq(d.depositAmount, DRIVER_DEPOSIT);
        assertEq(d.maxOrderValue, DRIVER_DEPOSIT / 2);
        assertEq(d.reputationScore, 500);
        assertTrue(d.active);
        assertEq(d.kycHash, KYC_HASH_DRIVER);
    }

    function test_RegisterDriver_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit IRegistry.DriverRegistered(driver1, KYC_HASH_DRIVER);

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);
    }

    function test_RegisterDriver_RevertIf_NoDeposit() public {
        vm.prank(driver1);
        vm.expectRevert("Registry: deposit required");
        registry.registerDriver{value: 0}(KYC_HASH_DRIVER);
    }

    function test_RegisterDriver_RevertIf_InvalidKYC() public {
        vm.prank(driver1);
        vm.expectRevert("Registry: invalid KYC hash");
        registry.registerDriver{value: DRIVER_DEPOSIT}(bytes32(0));
    }

    function test_RegisterDriver_RevertIf_AlreadyRegistered() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        vm.expectRevert("Registry: already registered");
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);
        vm.stopPrank();
    }

    // -------------------------
    // Driver top-up
    // -------------------------

    function test_TopUpDriverDeposit_Success() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        uint256 topUp = 0.5 ether;
        registry.topUpDriverDeposit{value: topUp}();
        vm.stopPrank();

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertEq(d.depositAmount, DRIVER_DEPOSIT + topUp);
        assertEq(d.maxOrderValue, (DRIVER_DEPOSIT + topUp) / 2);
    }

    function test_TopUpDriverDeposit_RevertIf_NotRegistered() public {
        vm.prank(driver1);
        vm.expectRevert("Registry: not registered");
        registry.topUpDriverDeposit{value: 0.5 ether}();
    }

    // -------------------------
    // Driver fare
    // -------------------------

    function test_SetFarePerKm_Success() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertEq(d.farePerKm, FARE_PER_KM);
    }

    function test_SetFarePerKm_RevertIf_ZeroFare() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        vm.expectRevert("Registry: fare must be greater than zero");
        registry.setFarePerKm(0);
        vm.stopPrank();
    }

    // -------------------------
    // Driver eligibility
    // -------------------------

    function test_IsDriverEligible_True() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        // maxOrderValue = 1 ether / 2 = 0.5 ether
        assertTrue(registry.isDriverEligible(driver1, 0.4 ether));
    }

    function test_IsDriverEligible_False_OrderTooLarge() public {
        vm.startPrank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);
        registry.setFarePerKm(FARE_PER_KM);
        vm.stopPrank();

        assertFalse(registry.isDriverEligible(driver1, 0.6 ether));
    }

    function test_IsDriverEligible_False_NoFareSet() public {
        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        assertFalse(registry.isDriverEligible(driver1, 0.1 ether));
    }

    // -------------------------
    // Passenger registration
    // -------------------------

    function test_RegisterPassenger_Success() public {
        vm.prank(passenger1);
        registry.registerPassenger(KYC_HASH_PASSENGER);

        IRegistry.Passenger memory p = registry.getPassenger(passenger1);
        assertEq(p.wallet, passenger1);
        assertEq(p.reputationScore, 500);
        assertTrue(p.active);
        assertEq(p.kycHash, KYC_HASH_PASSENGER);
    }

    function test_RegisterPassenger_RevertIf_AlreadyRegistered() public {
        vm.startPrank(passenger1);
        registry.registerPassenger(KYC_HASH_PASSENGER);

        vm.expectRevert("Registry: already registered");
        registry.registerPassenger(KYC_HASH_PASSENGER);
        vm.stopPrank();
    }

    // -------------------------
    // Arbiter registration
    // -------------------------

    function test_RegisterArbiter_Success() public {
        vm.prank(arbiter1);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();

        IRegistry.Arbiter memory a = registry.getArbiter(arbiter1);
        assertEq(a.wallet,        arbiter1);
        assertEq(a.depositAmount, ARBITER_DEPOSIT);
        assertEq(a.totalCases,    0);
        assertTrue(a.active);
    }

    function test_RegisterArbiter_RevertIf_NoDeposit() public {
        vm.prank(arbiter1);
        vm.expectRevert("Registry: deposit required");
        registry.registerArbiter{value: 0}();
    }

    // -------------------------
    // Random arbiter selection
    // -------------------------

    function test_GetRandomArbiter_ReturnsActiveArbiter() public {
        _registerArbiters();

        address selected = registry.getRandomArbiter(12345);
        assertTrue(
            selected == arbiter1 ||
            selected == arbiter2 ||
            selected == arbiter3
        );
    }

    function test_GetRandomArbiter_RevertIf_NoArbiters() public {
        vm.expectRevert("Registry: no active arbiters");
        registry.getRandomArbiter(0);
    }

    // -------------------------
    // Reputation
    // -------------------------

    function test_UpdateReputation_Driver() public {
        // grant RIDE_SESSION_ROLE to this test contract
        vm.prank(admin);
        registry.setRideSessionContract(address(this));

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        // first rating: 4 stars
        registry.updateReputation(driver1, 4);

        IRegistry.Driver memory d = registry.getDriver(driver1);
        // (500 × 0 + 400) / 1 = 400
        assertEq(d.reputationScore, 400);
        assertEq(d.totalTrips, 1);
    }

    function test_UpdateReputation_RevertIf_InvalidRating() public {
        vm.prank(admin);
        registry.setRideSessionContract(address(this));

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        vm.expectRevert("Registry: invalid rating");
        registry.updateReputation(driver1, 6);
    }

    // -------------------------
    // Slash
    // -------------------------

    function test_Slash_Driver_Success() public {
        vm.prank(admin);
        registry.setDisputeContract(address(this));

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        uint256 slashAmount    = 0.2 ether;
        uint256 recipientBefore = passenger1.balance;

        registry.slash(driver1, slashAmount, passenger1);

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertEq(d.depositAmount, DRIVER_DEPOSIT - slashAmount);
        assertEq(passenger1.balance, recipientBefore + slashAmount);
    }

    function test_Slash_Driver_RevertIf_InsufficientDeposit() public {
        vm.prank(admin);
        registry.setDisputeContract(address(this));

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        vm.expectRevert("Registry: insufficient deposit");
        registry.slash(driver1, 2 ether, passenger1);
    }

    function test_Slash_Arbiter_BansAfterMaxSlash() public {
        vm.prank(admin);
        registry.setDisputeContract(address(this));

        vm.prank(arbiter1);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();

        // slash 3 times to trigger permanent ban
        for (uint256 i = 0; i < 3; i++) {
            registry.slash(arbiter1, 0.01 ether, passenger1);
        }

        IRegistry.Arbiter memory a = registry.getArbiter(arbiter1);
        assertFalse(a.active);
        assertEq(a.slashCount, 3);
    }

    // -------------------------
    // Fuzz tests
    // -------------------------

    function testFuzz_DepositDeterminesMaxOrder(uint256 deposit) public {
        vm.assume(deposit > 0 && deposit <= 100 ether);

        vm.prank(driver1);
        vm.deal(driver1, deposit);
        registry.registerDriver{value: deposit}(KYC_HASH_DRIVER);

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertEq(d.maxOrderValue, deposit / 2);
    }

    function testFuzz_ReputationNeverExceedsFiveStars(uint256 rating) public {
        vm.assume(rating >= 1 && rating <= 5);

        vm.prank(admin);
        registry.setRideSessionContract(address(this));

        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_HASH_DRIVER);

        registry.updateReputation(driver1, rating);

        IRegistry.Driver memory d = registry.getDriver(driver1);
        assertTrue(d.reputationScore <= 500);
    }

    // -------------------------
    // Helpers
    // -------------------------

    function _registerArbiters() internal {
        vm.prank(arbiter1);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();

        vm.prank(arbiter2);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();

        vm.prank(arbiter3);
        registry.registerArbiter{value: ARBITER_DEPOSIT}();
    }
}

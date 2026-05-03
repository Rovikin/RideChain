// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/Registry.sol";
import "../contracts/ThresholdKYC.sol";
import "../contracts/interfaces/IRegistry.sol";
import "../contracts/interfaces/IThresholdKYC.sol";

contract ThresholdKYCTest is Test {

    Registry     registry;
    ThresholdKYC thresholdKYC;

    address admin      = makeAddr("admin");
    address driver1    = makeAddr("driver1");
    address passenger1 = makeAddr("passenger1");
    address arbiter1   = makeAddr("arbiter1");
    address arbiter2   = makeAddr("arbiter2");
    address arbiter3   = makeAddr("arbiter3");
    address arbiter4   = makeAddr("arbiter4");
    address arbiter5   = makeAddr("arbiter5");

    bytes32 constant KYC_DRIVER    = keccak256("driver1-kyc-documents");
    bytes32 constant KYC_PASSENGER = keccak256("passenger1-kyc-documents");
    bytes32 constant ENC_HASH      = keccak256("encrypted-ipfs-hash");
    bytes32 constant SESSION_ID    = keccak256("active-session-id");

    uint256 constant DRIVER_DEPOSIT  = 2 ether;
    uint256 constant ARBITER_DEPOSIT = 1 ether;

    // -------------------------
    // Setup
    // -------------------------

    function setUp() public {
        registry     = new Registry(admin);
        thresholdKYC = new ThresholdKYC(address(registry), admin);

        vm.deal(driver1,    10 ether);
        vm.deal(passenger1, 10 ether);
        vm.deal(arbiter1,   10 ether);
        vm.deal(arbiter2,   10 ether);
        vm.deal(arbiter3,   10 ether);
        vm.deal(arbiter4,   10 ether);
        vm.deal(arbiter5,   10 ether);

        // register driver and passenger
        vm.prank(driver1);
        registry.registerDriver{value: DRIVER_DEPOSIT}(KYC_DRIVER);

        vm.prank(passenger1);
        registry.registerPassenger(KYC_PASSENGER);

        // register 5 arbiters for V1 3-of-5 schema
        _registerArbiters();
    }

    // -------------------------
    // registerIdentity
    // -------------------------

    function test_RegisterIdentity_Success() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        IThresholdKYC.Identity memory id = thresholdKYC.getIdentity(driver1);
        assertEq(id.wallet,        driver1);
        assertEq(id.encryptedHash, ENC_HASH);
        assertTrue(id.active);
        assertGt(id.registeredAt,  0);
    }

    function test_RegisterIdentity_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit IThresholdKYC.IdentityRegistered(driver1, ENC_HASH);

        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);
    }

    function test_RegisterIdentity_RevertIf_InvalidHash() public {
        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: invalid hash");
        thresholdKYC.registerIdentity(bytes32(0));
    }

    function test_RegisterIdentity_RevertIf_AlreadyRegistered() public {
        vm.startPrank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.expectRevert("ThresholdKYC: already registered");
        thresholdKYC.registerIdentity(ENC_HASH);
        vm.stopPrank();
    }

    // -------------------------
    // updateIdentity
    // -------------------------

    function test_UpdateIdentity_Success() public {
        vm.startPrank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        bytes32 newHash = keccak256("new-encrypted-hash");
        thresholdKYC.updateIdentity(newHash);
        vm.stopPrank();

        IThresholdKYC.Identity memory id = thresholdKYC.getIdentity(driver1);
        assertEq(id.encryptedHash, newHash);
    }

    function test_UpdateIdentity_RevertIf_NotRegistered() public {
        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: not registered");
        thresholdKYC.updateIdentity(keccak256("new-hash"));
    }

    function test_UpdateIdentity_RevertIf_InvalidHash() public {
        vm.startPrank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.expectRevert("ThresholdKYC: invalid hash");
        thresholdKYC.updateIdentity(bytes32(0));
        vm.stopPrank();
    }

    // -------------------------
    // activatePanicButton
    // -------------------------

    function test_ActivatePanicButton_Success() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        bytes32 locationHash = keccak256(abi.encodePacked(
            int256(-6200000),
            int256(106816667),
            block.timestamp
        ));

        vm.prank(driver1);
        thresholdKYC.activatePanicButton(SESSION_ID, locationHash);

        assertTrue(thresholdKYC.isPanicActive(SESSION_ID));
    }

    function test_ActivatePanicButton_EmitsEvent() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        bytes32 locationHash = keccak256("location");

        vm.expectEmit(true, true, false, true);
        emit IThresholdKYC.PanicButtonActivated(driver1, SESSION_ID, block.timestamp);

        vm.prank(driver1);
        thresholdKYC.activatePanicButton(SESSION_ID, locationHash);
    }

    function test_ActivatePanicButton_CreatesAccessRequest() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(driver1);
        thresholdKYC.activatePanicButton(SESSION_ID, keccak256("loc"));

        bytes32[] memory history = thresholdKYC.getAccessHistory(driver1);
        assertEq(history.length, 1);

        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(history[0]);

        assertEq(req.target, driver1);
        assertEq(
            uint8(req.reason),
            uint8(IThresholdKYC.AccessReason.PANIC_BUTTON)
        );
        assertEq(req.sessionId, SESSION_ID);
        assertFalse(req.executed);
    }

    function test_ActivatePanicButton_IsIrrevocable() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(driver1);
        thresholdKYC.activatePanicButton(SESSION_ID, keccak256("loc"));

        // attempt to activate again — must revert
        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: panic already active");
        thresholdKYC.activatePanicButton(SESSION_ID, keccak256("loc2"));
    }

    function test_ActivatePanicButton_RevertIf_InvalidSession() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: invalid session");
        thresholdKYC.activatePanicButton(bytes32(0), keccak256("loc"));
    }

    function test_ActivatePanicButton_RevertIf_InvalidLocation() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: invalid location");
        thresholdKYC.activatePanicButton(SESSION_ID, bytes32(0));
    }

    // -------------------------
    // createAccessRequest
    // -------------------------

    function test_CreateAccessRequest_GovernanceVote() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        bytes32 requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        assertTrue(requestId != bytes32(0));

        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(requestId);

        assertEq(req.target, driver1);
        assertFalse(req.executed);
        assertEq(req.threshold, 3); // V1 3-of-5
    }

    function test_CreateAccessRequest_RevertIf_PanicViaWrongFunction() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        vm.expectRevert(
            "ThresholdKYC: panic button must use activatePanicButton"
        );
        thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.PANIC_BUTTON,
            SESSION_ID
        );
    }

    function test_CreateAccessRequest_RecordsInHistory() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        bytes32 requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        bytes32[] memory history = thresholdKYC.getAccessHistory(driver1);
        assertEq(history.length, 1);
        assertEq(history[0], requestId);
    }

    function test_CreateAccessRequest_RevertIf_TargetNotRegistered() public {
        address unknown = makeAddr("unknown");

        vm.prank(admin);
        vm.expectRevert("ThresholdKYC: target not registered");
        thresholdKYC.createAccessRequest(
            unknown,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );
    }

    // -------------------------
    // submitShard
    // -------------------------

    function test_SubmitShard_Success() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-data-1"));

        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(requestId);
        assertEq(req.shardsSubmitted, 1);
    }

    function test_SubmitShard_EmitsEvent() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.expectEmit(true, true, false, true);
        emit IThresholdKYC.ShardSubmitted(requestId, arbiter1, 0);

        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
    }

    function test_SubmitShard_RevertIf_NotArbiter() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.prank(driver1);
        vm.expectRevert("ThresholdKYC: not an arbiter");
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard"));
    }

    function test_SubmitShard_RevertIf_DoubleSubmission() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.startPrank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));

        vm.expectRevert("ThresholdKYC: shard already submitted");
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1-again"));
        vm.stopPrank();
    }

    function test_SubmitShard_RevertIf_Expired() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.warp(block.timestamp + thresholdKYC.ACCESS_REQUEST_EXPIRY() + 1);

        vm.prank(arbiter1);
        vm.expectRevert("ThresholdKYC: request expired");
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard"));
    }

    // -------------------------
    // executeReconstruction
    // -------------------------

    function test_ExecuteReconstruction_Success() public {
        bytes32 requestId = _createGovernanceRequest();

        // submit M=3 shards
        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
        vm.prank(arbiter2);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-2"));
        vm.prank(arbiter3);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-3"));

        thresholdKYC.executeReconstruction(requestId);

        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(requestId);
        assertTrue(req.executed);
    }

    function test_ExecuteReconstruction_EmitsEvent() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
        vm.prank(arbiter2);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-2"));
        vm.prank(arbiter3);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-3"));

        vm.expectEmit(true, true, false, false);
        emit IThresholdKYC.IdentityReconstructed(requestId, driver1);

        thresholdKYC.executeReconstruction(requestId);
    }

    function test_ExecuteReconstruction_RevertIf_ThresholdNotMet() public {
        bytes32 requestId = _createGovernanceRequest();

        // only 2 shards — threshold is 3
        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
        vm.prank(arbiter2);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-2"));

        vm.expectRevert("ThresholdKYC: threshold not met");
        thresholdKYC.executeReconstruction(requestId);
    }

    function test_ExecuteReconstruction_RevertIf_AlreadyExecuted() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
        vm.prank(arbiter2);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-2"));
        vm.prank(arbiter3);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-3"));

        thresholdKYC.executeReconstruction(requestId);

        vm.expectRevert("ThresholdKYC: already executed");
        thresholdKYC.executeReconstruction(requestId);
    }

    function test_ExecuteReconstruction_RevertIf_Expired() public {
        bytes32 requestId = _createGovernanceRequest();

        vm.prank(arbiter1);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-1"));
        vm.prank(arbiter2);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-2"));
        vm.prank(arbiter3);
        thresholdKYC.submitShard(requestId, abi.encodePacked("shard-3"));

        vm.warp(block.timestamp + thresholdKYC.ACCESS_REQUEST_EXPIRY() + 1);

        vm.expectRevert("ThresholdKYC: request expired");
        thresholdKYC.executeReconstruction(requestId);
    }

    // -------------------------
    // upgradeSchema
    // -------------------------

    function test_UpgradeSchema_V1_To_V2() public {
        assertEq(
            uint8(thresholdKYC.currentSchema()),
            uint8(IThresholdKYC.SchemaVersion.V1_3_OF_5)
        );
        assertEq(thresholdKYC.currentThreshold(), 3);
        assertEq(thresholdKYC.currentTotalShards(), 5);

        vm.prank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);

        assertEq(
            uint8(thresholdKYC.currentSchema()),
            uint8(IThresholdKYC.SchemaVersion.V2_5_OF_9)
        );
        assertEq(thresholdKYC.currentThreshold(), 5);
        assertEq(thresholdKYC.currentTotalShards(), 9);
    }

    function test_UpgradeSchema_V2_To_V3() public {
        vm.startPrank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V3_7_OF_13);
        vm.stopPrank();

        assertEq(thresholdKYC.currentThreshold(), 7);
        assertEq(thresholdKYC.currentTotalShards(), 13);
    }

    function test_UpgradeSchema_EmitsEvent() public {
        vm.expectEmit(false, false, false, true);
        emit IThresholdKYC.SchemaUpgraded(
            IThresholdKYC.SchemaVersion.V1_3_OF_5,
            IThresholdKYC.SchemaVersion.V2_5_OF_9
        );

        vm.prank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);
    }

    function test_UpgradeSchema_RevertIf_Downgrade() public {
        vm.startPrank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);

        vm.expectRevert("ThresholdKYC: can only upgrade to higher version");
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V1_3_OF_5);
        vm.stopPrank();
    }

    function test_UpgradeSchema_RevertIf_NotGovernance() public {
        vm.prank(driver1);
        vm.expectRevert();
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);
    }

    // -------------------------
    // Schema threshold enforcement
    // -------------------------

    function test_ThresholdEnforced_AfterSchemaUpgrade() public {
        // upgrade to V2: 5-of-9
        vm.prank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);

        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        bytes32 requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(requestId);

        // new request must require 5 shards
        assertEq(req.threshold, 5);
    }

    function test_OldRequests_RetainOriginalThreshold() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        // create request under V1 (threshold = 3)
        vm.prank(admin);
        bytes32 requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        // upgrade schema to V2
        vm.prank(admin);
        thresholdKYC.upgradeSchema(IThresholdKYC.SchemaVersion.V2_5_OF_9);

        // old request still requires 3 shards
        IThresholdKYC.AccessRequest memory req =
            thresholdKYC.getAccessRequest(requestId);
        assertEq(req.threshold, 3);
    }

    // -------------------------
    // Access history
    // -------------------------

    function test_AccessHistory_MultipleRequests() public {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        // panic button creates first request
        vm.prank(driver1);
        thresholdKYC.activatePanicButton(SESSION_ID, keccak256("loc"));

        // governance creates second request
        vm.prank(admin);
        thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        bytes32[] memory history = thresholdKYC.getAccessHistory(driver1);
        assertEq(history.length, 2);
    }

    // -------------------------
    // Fuzz tests
    // -------------------------

    function testFuzz_ThresholdAlwaysMetBeforeExecution(
        uint8 shardsToSubmit
    ) public {
        // threshold for V1 is 3
        vm.assume(shardsToSubmit < 3);

        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        bytes32 requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );

        address[5] memory arbiters = [arbiter1, arbiter2, arbiter3, arbiter4, arbiter5];

        for (uint8 i = 0; i < shardsToSubmit; i++) {
            vm.prank(arbiters[i]);
            thresholdKYC.submitShard(
                requestId,
                abi.encodePacked("shard", i)
            );
        }

        // execution must fail — threshold not met
        vm.expectRevert("ThresholdKYC: threshold not met");
        thresholdKYC.executeReconstruction(requestId);
    }

    function testFuzz_PanicButtonAlwaysCreatesAccessRequest(
        bytes32 locationHash
    ) public {
        vm.assume(locationHash != bytes32(0));

        bytes32 uniqueSession = keccak256(abi.encodePacked(locationHash));

        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(driver1);
        thresholdKYC.activatePanicButton(uniqueSession, locationHash);

        assertTrue(thresholdKYC.isPanicActive(uniqueSession));

        bytes32[] memory history = thresholdKYC.getAccessHistory(driver1);
        assertGt(history.length, 0);
    }

    // -------------------------
    // Helpers
    // -------------------------

    function _registerArbiters() internal {
        address[5] memory arbiters = [
            arbiter1, arbiter2, arbiter3, arbiter4, arbiter5
        ];
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(arbiters[i]);
            registry.registerArbiter{value: ARBITER_DEPOSIT}();
        }
    }

    function _createGovernanceRequest() internal returns (bytes32 requestId) {
        vm.prank(driver1);
        thresholdKYC.registerIdentity(ENC_HASH);

        vm.prank(admin);
        requestId = thresholdKYC.createAccessRequest(
            driver1,
            IThresholdKYC.AccessReason.GOVERNANCE_VOTE,
            bytes32(0)
        );
    }
}

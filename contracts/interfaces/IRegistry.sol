// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title IRegistry
/// @notice Interface for participant registration: drivers, passengers, arbiters
interface IRegistry {

    // -------------------------
    // Structs
    // -------------------------

    struct Driver {
        address wallet;
        uint256 depositAmount;      // MATIC deposited (in wei)
        uint256 maxOrderValue;      // max trip value eligible to accept
        uint256 farePerKm;          // fare in wei per km
        uint256 reputationScore;    // cumulative score
        uint256 totalTrips;
        bool active;
        bytes32 kycHash;            // IPFS hash of encrypted identity
    }

    struct Passenger {
        address wallet;
        uint256 reputationScore;
        uint256 totalTrips;
        bool active;
        bytes32 kycHash;
    }

    struct Arbiter {
        address wallet;
        uint256 depositAmount;
        uint256 totalCases;
        uint256 ratingTotal;
        uint256 slashCount;
        bool active;
    }

    // -------------------------
    // Events
    // -------------------------

    event DriverRegistered(address indexed wallet, bytes32 kycHash);
    event PassengerRegistered(address indexed wallet, bytes32 kycHash);
    event ArbiterRegistered(address indexed wallet);

    event DriverDeposited(address indexed wallet, uint256 amount);
    event DriverSlashed(address indexed wallet, uint256 amount, address recipient);

    event ArbiterDeactivated(address indexed wallet, string reason);
    event ReputationUpdated(address indexed wallet, uint256 newScore);

    // -------------------------
    // Driver functions
    // -------------------------

    /// @notice Register as driver with KYC hash and initial deposit
    function registerDriver(bytes32 kycHash) external payable;

    /// @notice Add more deposit to increase max order value
    function topUpDriverDeposit() external payable;

    /// @notice Update fare per km
    function setFarePerKm(uint256 farePerKm) external;

    /// @notice Get driver data
    function getDriver(address wallet) external view returns (Driver memory);

    /// @notice Check if driver is eligible for a given order value
    function isDriverEligible(address wallet, uint256 orderValue) external view returns (bool);

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @notice Register as passenger with KYC hash
    function registerPassenger(bytes32 kycHash) external;

    /// @notice Get passenger data
    function getPassenger(address wallet) external view returns (Passenger memory);

    // -------------------------
    // Arbiter functions
    // -------------------------

    /// @notice Register as arbiter with deposit
    function registerArbiter() external payable;

    /// @notice Get arbiter data
    function getArbiter(address wallet) external view returns (Arbiter memory);

    /// @notice Get a random active arbiter for dispute assignment
    /// @dev Called only by Dispute Contract
    function getRandomArbiter(uint256 seed) external view returns (address);

    // -------------------------
    // Reputation functions
    // -------------------------

    /// @notice Update reputation after trip completion
    /// @dev Called only by RideSession or Dispute Contract
    function updateReputation(address wallet, uint256 rating) external;

    // -------------------------
    // Slash functions
    // -------------------------

    /// @notice Slash participant deposit
    /// @dev Called only by Dispute Contract
    function slash(address wallet, uint256 amount, address recipient) external;
}

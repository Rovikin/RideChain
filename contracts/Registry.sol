// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRegistry.sol";

/// @title Registry
/// @notice Manages registration and reputation of drivers, passengers, and arbiters
contract Registry is IRegistry, AccessControl, ReentrancyGuard {

    // -------------------------
    // Roles
    // -------------------------

    bytes32 public constant RIDE_SESSION_ROLE = keccak256("RIDE_SESSION_ROLE");
    bytes32 public constant DISPUTE_ROLE      = keccak256("DISPUTE_ROLE");

    // -------------------------
    // Constants
    // -------------------------

    /// @notice Deposit multiplier: deposit must be 2× max order value
    uint256 public constant DEPOSIT_MULTIPLIER = 2;

    /// @notice Minimum reputation rating (1–5 scale, stored as × 1e2 for precision)
    /// @dev 350 = 3.50 / 5.00
    uint256 public constant MIN_REPUTATION = 350;

    /// @notice Max slash count before arbiter is permanently banned
    uint256 public constant MAX_ARBITER_SLASH = 3;

    // -------------------------
    // Storage
    // -------------------------

    mapping(address => Driver)  private _drivers;
    mapping(address => Passenger) private _passengers;
    mapping(address => Arbiter) private _arbiters;

    /// @notice List of active arbiter addresses for random selection
    address[] private _activeArbiters;

    /// @notice Index of arbiter in _activeArbiters for O(1) removal
    mapping(address => uint256) private _arbiterIndex;

    // -------------------------
    // Constructor
    // -------------------------

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // -------------------------
    // Driver functions
    // -------------------------

    /// @inheritdoc IRegistry
    function registerDriver(bytes32 kycHash) external payable nonReentrant {
        require(_drivers[msg.sender].wallet == address(0), "Registry: already registered");
        require(msg.value > 0, "Registry: deposit required");
        require(kycHash != bytes32(0), "Registry: invalid KYC hash");

        uint256 maxOrderValue = msg.value / DEPOSIT_MULTIPLIER;

        _drivers[msg.sender] = Driver({
            wallet:          msg.sender,
            depositAmount:   msg.value,
            maxOrderValue:   maxOrderValue,
            farePerKm:       0,
            reputationScore: 500,       // start at 5.00 / 5.00
            totalTrips:      0,
            active:          true,
            kycHash:         kycHash
        });

        emit DriverRegistered(msg.sender, kycHash);
        emit DriverDeposited(msg.sender, msg.value);
    }

    /// @inheritdoc IRegistry
    function topUpDriverDeposit() external payable nonReentrant {
        require(_drivers[msg.sender].wallet != address(0), "Registry: not registered");
        require(msg.value > 0, "Registry: deposit required");

        Driver storage driver = _drivers[msg.sender];
        driver.depositAmount += msg.value;
        driver.maxOrderValue  = driver.depositAmount / DEPOSIT_MULTIPLIER;

        emit DriverDeposited(msg.sender, msg.value);
    }

    /// @inheritdoc IRegistry
    function setFarePerKm(uint256 farePerKm) external {
        require(_drivers[msg.sender].wallet != address(0), "Registry: not registered");
        require(farePerKm > 0, "Registry: fare must be greater than zero");
        _drivers[msg.sender].farePerKm = farePerKm;
    }

    /// @inheritdoc IRegistry
    function getDriver(address wallet) external view returns (Driver memory) {
        return _drivers[wallet];
    }

    /// @inheritdoc IRegistry
    function isDriverEligible(
        address wallet,
        uint256 orderValue
    ) external view returns (bool) {
        Driver memory driver = _drivers[wallet];
        if (!driver.active) return false;
        if (driver.farePerKm == 0) return false;
        if (driver.maxOrderValue < orderValue) return false;
        if (driver.reputationScore < MIN_REPUTATION) return false;
        return true;
    }

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @inheritdoc IRegistry
    function registerPassenger(bytes32 kycHash) external {
        require(_passengers[msg.sender].wallet == address(0), "Registry: already registered");
        require(kycHash != bytes32(0), "Registry: invalid KYC hash");

        _passengers[msg.sender] = Passenger({
            wallet:          msg.sender,
            reputationScore: 500,
            totalTrips:      0,
            active:          true,
            kycHash:         kycHash
        });

        emit PassengerRegistered(msg.sender, kycHash);
    }

    /// @inheritdoc IRegistry
    function getPassenger(address wallet) external view returns (Passenger memory) {
        return _passengers[wallet];
    }

    // -------------------------
    // Arbiter functions
    // -------------------------

    /// @inheritdoc IRegistry
    function registerArbiter() external payable nonReentrant {
        require(_arbiters[msg.sender].wallet == address(0), "Registry: already registered");
        require(msg.value > 0, "Registry: deposit required");

        _arbiters[msg.sender] = Arbiter({
            wallet:        msg.sender,
            depositAmount: msg.value,
            totalCases:    0,
            ratingTotal:   0,
            slashCount:    0,
            active:        true
        });

        _arbiterIndex[msg.sender] = _activeArbiters.length;
        _activeArbiters.push(msg.sender);

        emit ArbiterRegistered(msg.sender);
    }

    /// @inheritdoc IRegistry
    function getArbiter(address wallet) external view returns (Arbiter memory) {
        return _arbiters[wallet];
    }

    /// @inheritdoc IRegistry
    function getRandomArbiter(uint256 seed) external view returns (address) {
        require(_activeArbiters.length > 0, "Registry: no active arbiters");

        uint256 index = seed % _activeArbiters.length;
        return _activeArbiters[index];
    }

    // -------------------------
    // Reputation functions
    // -------------------------

    /// @inheritdoc IRegistry
    function updateReputation(
        address wallet,
        uint256 rating
    ) external onlyRole(RIDE_SESSION_ROLE) {
        require(rating >= 1 && rating <= 5, "Registry: invalid rating");

        // rating stored as × 100 for precision (1–5 becomes 100–500)
        uint256 scaledRating = rating * 100;

        if (_drivers[wallet].wallet != address(0)) {
            Driver storage driver = _drivers[wallet];
            uint256 total = driver.reputationScore * driver.totalTrips + scaledRating;
            driver.totalTrips++;
            driver.reputationScore = total / driver.totalTrips;

            if (driver.reputationScore < MIN_REPUTATION) {
                driver.active = false;
                emit ArbiterDeactivated(wallet, "reputation below minimum");
            }

            emit ReputationUpdated(wallet, driver.reputationScore);

        } else if (_passengers[wallet].wallet != address(0)) {
            Passenger storage passenger = _passengers[wallet];
            uint256 total = passenger.reputationScore * passenger.totalTrips + scaledRating;
            passenger.totalTrips++;
            passenger.reputationScore = total / passenger.totalTrips;

            emit ReputationUpdated(wallet, passenger.reputationScore);

        } else if (_arbiters[wallet].wallet != address(0)) {
            Arbiter storage arbiter = _arbiters[wallet];
            arbiter.ratingTotal += scaledRating;
            arbiter.totalCases++;

            uint256 avgRating = arbiter.ratingTotal / arbiter.totalCases;
            if (avgRating < MIN_REPUTATION) {
                _deactivateArbiter(wallet, "reputation below minimum");
            }

            emit ReputationUpdated(wallet, avgRating);
        }
    }

    // -------------------------
    // Slash functions
    // -------------------------

    /// @inheritdoc IRegistry
    function slash(
        address wallet,
        uint256 amount,
        address recipient
    ) external onlyRole(DISPUTE_ROLE) nonReentrant {
        require(recipient != address(0), "Registry: invalid recipient");

        if (_drivers[wallet].wallet != address(0)) {
            Driver storage driver = _drivers[wallet];
            require(driver.depositAmount >= amount, "Registry: insufficient deposit");

            driver.depositAmount -= amount;
            driver.maxOrderValue  = driver.depositAmount / DEPOSIT_MULTIPLIER;

            // suspend if deposit too low to cover minimum order
            if (driver.depositAmount == 0) {
                driver.active = false;
            }

            emit DriverSlashed(wallet, amount, recipient);

        } else if (_arbiters[wallet].wallet != address(0)) {
            Arbiter storage arbiter = _arbiters[wallet];
            require(arbiter.depositAmount >= amount, "Registry: insufficient deposit");

            arbiter.depositAmount -= amount;
            arbiter.slashCount++;

            emit ArbiterSlashed(wallet, amount);

            if (arbiter.slashCount >= MAX_ARBITER_SLASH) {
                _deactivateArbiter(wallet, "max slash count reached");
            }
        }

        // Checks → Effects → Interactions
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Registry: transfer failed");
    }

    // -------------------------
    // Internal functions
    // -------------------------

    function _deactivateArbiter(address wallet, string memory reason) internal {
        Arbiter storage arbiter = _arbiters[wallet];
        arbiter.active = false;

        // remove from active list: swap with last element
        uint256 index = _arbiterIndex[wallet];
        uint256 lastIndex = _activeArbiters.length - 1;

        if (index != lastIndex) {
            address lastArbiter = _activeArbiters[lastIndex];
            _activeArbiters[index] = lastArbiter;
            _arbiterIndex[lastArbiter] = index;
        }

        _activeArbiters.pop();
        delete _arbiterIndex[wallet];

        emit ArbiterDeactivated(wallet, reason);
    }

    // -------------------------
    // Admin functions
    // -------------------------

    /// @notice Grant RideSession role to deployed RideSession contract
    function setRideSessionContract(address rideSession) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RIDE_SESSION_ROLE, rideSession);
    }

    /// @notice Grant Dispute role to deployed Dispute contract
    function setDisputeContract(address dispute) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DISPUTE_ROLE, dispute);
    }

    // -------------------------
    // Fallback
    // -------------------------

    receive() external payable {
        revert("Registry: use registerDriver or registerArbiter");
    }
}

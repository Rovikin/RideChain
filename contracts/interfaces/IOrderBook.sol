// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title IOrderBook
/// @notice Interface for driver availability and order matching
interface IOrderBook {

    // -------------------------
    // Structs
    // -------------------------

    struct DriverAsk {
        address wallet;
        uint256 farePerKm;          // fare in wei per km
        uint256 maxOrderValue;      // derived from deposit
        int256 lat;                 // latitude × 1e6
        int256 lng;                 // longitude × 1e6
        uint256 reputationScore;    // cached from Registry
        uint256 lastSeen;           // block.timestamp of last update
        bool available;
    }

    struct OrderRequest {
        address passenger;
        int256 pickupLat;
        int256 pickupLng;
        int256 dropoffLat;
        int256 dropoffLng;
        uint256 estimatedDistance;  // in meters, from OSRM
        uint256 estimatedFare;      // farePerKm × estimatedDistance
        uint256 routingFee;         // 0.5% of estimatedFare
        uint256 createdAt;
        bool matched;
    }

    // -------------------------
    // Events
    // -------------------------

    event DriverAskPublished(address indexed wallet, uint256 farePerKm);
    event DriverAskUpdated(address indexed wallet, int256 lat, int256 lng);
    event DriverAskWithdrawn(address indexed wallet);

    event OrderCreated(
        bytes32 indexed orderId,
        address indexed passenger,
        address indexed driver,
        uint256 estimatedFare
    );
    event RoutingFeeDistributed(bytes32 indexed orderId, address routingNode, uint256 amount);

    // -------------------------
    // Driver functions
    // -------------------------

    /// @notice Publish or update driver availability in the order book
    /// @dev Driver must be registered and eligible in Registry
    function publishAsk(
        uint256 farePerKm,
        int256 lat,
        int256 lng
    ) external;

    /// @notice Update driver GPS position only (cheaper than full publishAsk)
    function updatePosition(int256 lat, int256 lng) external;

    /// @notice Withdraw from order book (go offline)
    function withdrawAsk() external;

    /// @notice Get driver ask data
    function getDriverAsk(address wallet) external view returns (DriverAsk memory);

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @notice Create an order and lock escrow
    /// @param driver selected driver address
    /// @param pickupLat pickup latitude × 1e6
    /// @param pickupLng pickup longitude × 1e6
    /// @param dropoffLat dropoff latitude × 1e6
    /// @param dropoffLng dropoff longitude × 1e6
    /// @param estimatedDistance distance in meters from OSRM (submitted by client)
    /// @param routingNode address of routing node to receive fee
    function createOrder(
        address driver,
        int256 pickupLat,
        int256 pickupLng,
        int256 dropoffLat,
        int256 dropoffLng,
        uint256 estimatedDistance,
        address routingNode
    ) external payable returns (bytes32 orderId);

    /// @notice Get order data
    function getOrder(bytes32 orderId) external view returns (OrderRequest memory);

    // -------------------------
    // View functions
    // -------------------------

    /// @notice Calculate estimated fare for a given driver and distance
    function calculateFare(
        address driver,
        uint256 distanceMeters
    ) external view returns (uint256 fare, uint256 routingFee, uint256 total);
}

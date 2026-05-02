// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/IRegistry.sol";

/// @title OrderBook
/// @notice Manages driver availability and order creation
contract OrderBook is IOrderBook, AccessControl, ReentrancyGuard {

    // -------------------------
    // Roles
    // -------------------------

    bytes32 public constant RIDE_SESSION_ROLE = keccak256("RIDE_SESSION_ROLE");

    // -------------------------
    // Constants
    // -------------------------

    /// @notice Routing fee: 0.5% of fare (split 0.25% each side)
    uint256 public constant ROUTING_FEE_BPS = 50;       // 50 / 10000 = 0.5%

    /// @notice Minimum order value to prevent dust/griefing
    uint256 public constant MIN_ORDER_VALUE = 0.001 ether;

    /// @notice Max seconds since lastSeen before driver considered stale
    uint256 public constant DRIVER_STALE_THRESHOLD = 120; // 2 minutes

    /// @notice Gas buffer added to escrow (refunded if unused)
    uint256 public constant GAS_BUFFER = 0.001 ether;

    // -------------------------
    // Storage
    // -------------------------

    IRegistry public immutable registry;

    /// @notice Active driver asks
    mapping(address => DriverAsk) private _asks;

    /// @notice Order storage
    mapping(bytes32 => OrderRequest) private _orders;

    /// @notice Nonce for order ID generation
    uint256 private _nonce;

    // -------------------------
    // Constructor
    // -------------------------

    constructor(address registryAddress, address admin) {
        require(registryAddress != address(0), "OrderBook: invalid registry");
        registry = IRegistry(registryAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // -------------------------
    // Driver functions
    // -------------------------

    /// @inheritdoc IOrderBook
    function publishAsk(
        uint256 farePerKm,
        int256 lat,
        int256 lng
    ) external {
        require(farePerKm > 0, "OrderBook: fare must be greater than zero");
        _requireActiveDriver(msg.sender);

        _asks[msg.sender] = DriverAsk({
            wallet:          msg.sender,
            farePerKm:       farePerKm,
            maxOrderValue:   registry.getDriver(msg.sender).maxOrderValue,
            lat:             lat,
            lng:             lng,
            reputationScore: registry.getDriver(msg.sender).reputationScore,
            lastSeen:        block.timestamp,
            available:       true
        });

        emit DriverAskPublished(msg.sender, farePerKm);
    }

    /// @inheritdoc IOrderBook
    function updatePosition(int256 lat, int256 lng) external {
        require(_asks[msg.sender].wallet != address(0), "OrderBook: ask not found");
        require(_asks[msg.sender].available, "OrderBook: ask not active");

        _asks[msg.sender].lat      = lat;
        _asks[msg.sender].lng      = lng;
        _asks[msg.sender].lastSeen = block.timestamp;

        emit DriverAskUpdated(msg.sender, lat, lng);
    }

    /// @inheritdoc IOrderBook
    function withdrawAsk() external {
        require(_asks[msg.sender].wallet != address(0), "OrderBook: ask not found");

        _asks[msg.sender].available = false;

        emit DriverAskWithdrawn(msg.sender);
    }

    /// @inheritdoc IOrderBook
    function getDriverAsk(address wallet) external view returns (DriverAsk memory) {
        return _asks[wallet];
    }

    // -------------------------
    // Passenger functions
    // -------------------------

    /// @inheritdoc IOrderBook
    function createOrder(
        address driver,
        int256 pickupLat,
        int256 pickupLng,
        int256 dropoffLat,
        int256 dropoffLng,
        uint256 estimatedDistance,
        address routingNode
    ) external payable nonReentrant returns (bytes32 orderId) {
        // --- Checks ---
        _requireActiveDriver(driver);
        _requireAvailableAsk(driver);
        require(routingNode != address(0), "OrderBook: invalid routing node");
        require(estimatedDistance > 0, "OrderBook: invalid distance");

        (uint256 fare, uint256 routingFee, uint256 total) =
            calculateFare(driver, estimatedDistance);

        require(fare >= MIN_ORDER_VALUE, "OrderBook: order value too low");
        require(
            registry.isDriverEligible(driver, fare),
            "OrderBook: driver not eligible"
        );
        require(
            msg.value >= total + GAS_BUFFER,
            "OrderBook: insufficient payment"
        );

        // --- Effects ---
        orderId = _generateOrderId(msg.sender, driver);

        _orders[orderId] = OrderRequest({
            passenger:         msg.sender,
            pickupLat:         pickupLat,
            pickupLng:         pickupLng,
            dropoffLat:        dropoffLat,
            dropoffLng:        dropoffLng,
            estimatedDistance: estimatedDistance,
            estimatedFare:     fare,
            routingFee:        routingFee,
            createdAt:         block.timestamp,
            matched:           true
        });

        // mark driver as unavailable
        _asks[driver].available = false;

        emit OrderCreated(orderId, msg.sender, driver, fare);

        // --- Interactions ---
        // distribute routing fee immediately to routing node
        uint256 driverRoutingFee = routingFee / 2;
        uint256 passengerRoutingFee = routingFee - driverRoutingFee;
        uint256 totalRoutingFee = driverRoutingFee + passengerRoutingFee;

        (bool success, ) = routingNode.call{value: totalRoutingFee}("");
        require(success, "OrderBook: routing fee transfer failed");

        emit RoutingFeeDistributed(orderId, routingNode, totalRoutingFee);

        // refund excess payment
        uint256 escrowNeeded = fare + GAS_BUFFER;
        uint256 excess = msg.value - escrowNeeded - totalRoutingFee;
        if (excess > 0) {
            (bool refunded, ) = msg.sender.call{value: excess}("");
            require(refunded, "OrderBook: refund failed");
        }
    }

    /// @inheritdoc IOrderBook
    function getOrder(bytes32 orderId) external view returns (OrderRequest memory) {
        return _orders[orderId];
    }

    // -------------------------
    // View functions
    // -------------------------

    /// @inheritdoc IOrderBook
    function calculateFare(
        address driver,
        uint256 distanceMeters
    ) public view returns (uint256 fare, uint256 routingFee, uint256 total) {
        DriverAsk memory ask = _asks[driver];
        require(ask.wallet != address(0), "OrderBook: ask not found");

        // farePerKm is in wei per km, distance in meters
        fare       = (ask.farePerKm * distanceMeters) / 1000;
        routingFee = (fare * ROUTING_FEE_BPS) / 10000;
        total      = fare + routingFee;
    }

    // -------------------------
    // Internal functions
    // -------------------------

    function _generateOrderId(
        address passenger,
        address driver
    ) internal returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                passenger,
                driver,
                block.timestamp,
                _nonce++
            )
        );
    }

    function _requireActiveDriver(address driver) internal view {
        IRegistry.Driver memory d = registry.getDriver(driver);
        require(d.wallet != address(0), "OrderBook: driver not registered");
        require(d.active, "OrderBook: driver not active");
    }

    function _requireAvailableAsk(address driver) internal view {
        DriverAsk memory ask = _asks[driver];
        require(ask.wallet != address(0), "OrderBook: ask not found");
        require(ask.available, "OrderBook: driver not available");
        require(
            block.timestamp - ask.lastSeen <= DRIVER_STALE_THRESHOLD,
            "OrderBook: driver position stale"
        );
    }

    // -------------------------
    // Admin functions
    // -------------------------

    /// @notice Set RideSession contract address
    function setRideSessionContract(
        address rideSession
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RIDE_SESSION_ROLE, rideSession);
    }

    // -------------------------
    // Fallback
    // -------------------------

    receive() external payable {
        revert("OrderBook: use createOrder");
    }
}

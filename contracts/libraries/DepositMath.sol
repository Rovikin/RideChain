// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @title DepositMath
/// @notice Helper functions for deposit and fare calculations
library DepositMath {

    // -------------------------
    // Constants
    // -------------------------

    uint256 internal constant DEPOSIT_MULTIPLIER = 2;
    uint256 internal constant ROUTING_FEE_BPS    = 50;    // 0.5%
    uint256 internal constant BPS_DENOMINATOR    = 10000;
    uint256 internal constant CANCEL_PENALTY_BPS = 2000;  // 20%

    // -------------------------
    // Deposit calculations
    // -------------------------

    /// @notice Calculate max order value from a deposit amount
    /// @param depositAmount total MATIC deposited in wei
    /// @return maxOrderValue maximum trip value eligible
    function maxOrderFromDeposit(
        uint256 depositAmount
    ) internal pure returns (uint256 maxOrderValue) {
        return depositAmount / DEPOSIT_MULTIPLIER;
    }

    /// @notice Calculate minimum deposit required for a desired max order value
    /// @param desiredMaxOrder the order value to be covered
    /// @return minimumDeposit required deposit in wei
    function depositForMaxOrder(
        uint256 desiredMaxOrder
    ) internal pure returns (uint256 minimumDeposit) {
        return desiredMaxOrder * DEPOSIT_MULTIPLIER;
    }

    /// @notice Check if deposit covers a given order value
    /// @param depositAmount current deposit in wei
    /// @param orderValue order value to check
    /// @return eligible true if deposit is sufficient
    function isDepositEligible(
        uint256 depositAmount,
        uint256 orderValue
    ) internal pure returns (bool eligible) {
        return depositAmount >= orderValue * DEPOSIT_MULTIPLIER;
    }

    // -------------------------
    // Fare calculations
    // -------------------------

    /// @notice Calculate fare from fare per km and distance
    /// @param farePerKm fare in wei per km
    /// @param distanceMeters distance in meters
    /// @return fare total fare in wei
    function calculateFare(
        uint256 farePerKm,
        uint256 distanceMeters
    ) internal pure returns (uint256 fare) {
        return (farePerKm * distanceMeters) / 1000;
    }

    /// @notice Calculate routing fee from fare
    /// @param fare base fare in wei
    /// @return routingFee total routing fee (0.5% of fare)
    function calculateRoutingFee(
        uint256 fare
    ) internal pure returns (uint256 routingFee) {
        return (fare * ROUTING_FEE_BPS) / BPS_DENOMINATOR;
    }

    /// @notice Calculate each side's share of routing fee
    /// @param routingFee total routing fee
    /// @return driverShare driver's portion (0.25%)
    /// @return passengerShare passenger's portion (0.25%)
    function splitRoutingFee(
        uint256 routingFee
    ) internal pure returns (
        uint256 driverShare,
        uint256 passengerShare
    ) {
        driverShare    = routingFee / 2;
        passengerShare = routingFee - driverShare;
    }

    /// @notice Calculate cancellation penalty
    /// @param escrowAmount total escrow in wei
    /// @return penalty amount to driver
    /// @return refund amount back to passenger
    function cancellationSplit(
        uint256 escrowAmount
    ) internal pure returns (
        uint256 penalty,
        uint256 refund
    ) {
        penalty = (escrowAmount * CANCEL_PENALTY_BPS) / BPS_DENOMINATOR;
        refund  = escrowAmount - penalty;
    }

    /// @notice Calculate proportional payout for mid-trip cancellation
    /// @param fareAmount agreed fare
    /// @param distanceCovered meters covered so far
    /// @param totalDistance total estimated distance
    /// @return driverPayout proportional fare for distance covered
    /// @return passengerRefund remainder back to passenger
    function proportionalSplit(
        uint256 fareAmount,
        uint256 distanceCovered,
        uint256 totalDistance
    ) internal pure returns (
        uint256 driverPayout,
        uint256 passengerRefund
    ) {
        if (totalDistance == 0) {
            return (0, fareAmount);
        }
        driverPayout    = (fareAmount * distanceCovered) / totalDistance;
        passengerRefund = fareAmount - driverPayout;
    }
}

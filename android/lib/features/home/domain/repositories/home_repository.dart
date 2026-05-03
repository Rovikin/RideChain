import '../entities/driver_entity.dart';
import '../entities/balance_entity.dart';

abstract class HomeRepository {
  /// Get wallet MATIC balance
  Future<BalanceEntity> getBalance(String address);

  /// Get nearby available drivers
  Future<List<DriverEntity>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusMeters,
  });

  /// Get current MATIC/IDR exchange rate
  Future<double> getMaticIdrRate();
}

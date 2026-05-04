import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String address);
  Future<void> registerAsDriver(String kycHash, BigInt depositWei);
  Future<void> registerAsPassenger(String kycHash);
  Future<void> setFarePerKm(BigInt farePerKm);
  Future<void> topUpDeposit(BigInt amountWei);
}

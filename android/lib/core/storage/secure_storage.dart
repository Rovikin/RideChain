import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value storage for sensitive data.
/// Uses Android Keystore on Android, Keychain on iOS.
class SecureStorage {
  static const _keyPrivateKey = 'ridechain_private_key';
  static const _keyKycHash    = 'ridechain_kyc_hash';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // -------------------------
  // Private key
  // -------------------------

  Future<void> writePrivateKey(String privateKeyHex) async {
    await _storage.write(key: _keyPrivateKey, value: privateKeyHex);
  }

  Future<String?> readPrivateKey() async {
    return _storage.read(key: _keyPrivateKey);
  }

  Future<void> deletePrivateKey() async {
    await _storage.delete(key: _keyPrivateKey);
  }

  // -------------------------
  // KYC hash
  // -------------------------

  Future<void> writeKycHash(String hash) async {
    await _storage.write(key: _keyKycHash, value: hash);
  }

  Future<String?> readKycHash() async {
    return _storage.read(key: _keyKycHash);
  }

  // -------------------------
  // Clear all
  // -------------------------

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

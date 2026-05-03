import '../entities/wallet_entity.dart';

abstract class AuthRepository {
  /// Check if wallet exists in secure storage
  Future<bool> hasWallet();

  /// Create new wallet, return mnemonic for backup
  Future<String> createWallet();

  /// Import wallet from mnemonic
  Future<void> importWallet(String mnemonic);

  /// Get current wallet info including on-chain status
  Future<WalletEntity> getWalletInfo();

  /// Get current wallet address
  Future<String?> getAddress();

  /// Delete wallet from device
  Future<void> deleteWallet();
}

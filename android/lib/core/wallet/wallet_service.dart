import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:hex/hex.dart';

import '../storage/secure_storage.dart';

/// Manages wallet creation, import, and signing.
/// Private key never leaves this service unencrypted.
class WalletService {
  final SecureStorage _storage;

  EthPrivateKey? _credentials;
  EthereumAddress? _address;

  WalletService(this._storage);

  bool get isInitialized => _credentials != null;
  EthereumAddress? get address => _address;

  // -------------------------
  // Initialization
  // -------------------------

  Future<void> initialize() async {
    final privateKey = await _storage.readPrivateKey();
    if (privateKey != null) {
      _credentials = EthPrivateKey.fromHex(privateKey);
      _address     = _credentials!.address;
    }
  }

  // -------------------------
  // Wallet creation
  // -------------------------

  /// Generate new wallet from random mnemonic.
  /// Returns mnemonic for user to backup.
  Future<String> createWallet() async {
    final mnemonic = bip39.generateMnemonic();
    await _importFromMnemonic(mnemonic);
    return mnemonic;
  }

  /// Import existing wallet from 12/24-word mnemonic.
  Future<void> importWallet(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw WalletException('Invalid mnemonic phrase');
    }
    await _importFromMnemonic(mnemonic);
  }

  /// Import wallet from raw private key hex.
  Future<void> importFromPrivateKey(String privateKeyHex) async {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    await _persistCredentials(credentials);
  }

  // -------------------------
  // Signing
  // -------------------------

  Future<Uint8List> signMessage(Uint8List message) async {
    _requireInitialized();
    return _credentials!.signPersonalMessageToUint8List(message);
  }

  Future<String> signTransaction(Transaction tx, int chainId) async {
    _requireInitialized();
    // actual signing delegated to web3dart client
    // returns signed tx hex
    throw UnimplementedError('Use Web3Client.signTransaction directly');
  }

  // -------------------------
  // Internal helpers
  // -------------------------

  Future<void> _importFromMnemonic(String mnemonic) async {
    final seed    = bip39.mnemonicToSeed(mnemonic);
    final root    = bip32.BIP32.fromSeed(seed);
    // Ethereum derivation path: m/44'/60'/0'/0/0
    final child   = root.derivePath("m/44'/60'/0'/0/0");
    final privKey = HEX.encode(child.privateKey!);
    final credentials = EthPrivateKey.fromHex(privKey);
    await _persistCredentials(credentials);
  }

  Future<void> _persistCredentials(EthPrivateKey credentials) async {
    _credentials = credentials;
    _address     = credentials.address;
    await _storage.writePrivateKey(
      HEX.encode(credentials.privateKey),
    );
  }

  void _requireInitialized() {
    if (_credentials == null) {
      throw WalletException('Wallet not initialized');
    }
  }
}

class WalletException implements Exception {
  final String message;
  const WalletException(this.message);

  @override
  String toString() => 'WalletException: $message';
}

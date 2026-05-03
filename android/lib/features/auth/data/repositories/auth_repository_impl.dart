import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final WalletService  _walletService;
  final SecureStorage  _secureStorage;

  late final Web3Client _web3;

  // minimal ABI for registry queries
  static const _registryAbi = '''[
    {
      "inputs": [{"name": "wallet","type": "address"}],
      "name": "getDriver",
      "outputs": [{"components": [
        {"name": "wallet",          "type": "address"},
        {"name": "depositAmount",   "type": "uint256"},
        {"name": "maxOrderValue",   "type": "uint256"},
        {"name": "farePerKm",       "type": "uint256"},
        {"name": "reputationScore", "type": "uint256"},
        {"name": "totalTrips",      "type": "uint256"},
        {"name": "active",          "type": "bool"},
        {"name": "kycHash",         "type": "bytes32"}
      ], "type": "tuple"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "wallet","type": "address"}],
      "name": "getPassenger",
      "outputs": [{"components": [
        {"name": "wallet",          "type": "address"},
        {"name": "reputationScore", "type": "uint256"},
        {"name": "totalTrips",      "type": "uint256"},
        {"name": "active",          "type": "bool"},
        {"name": "kycHash",         "type": "bytes32"}
      ], "type": "tuple"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]''';

  AuthRepositoryImpl({
    required WalletService walletService,
    required SecureStorage secureStorage,
  })  : _walletService = walletService,
        _secureStorage = secureStorage {
    _web3 = Web3Client(
      AppConstants.polygonRpcUrl,
      http.Client(),
    );
  }

  @override
  Future<bool> hasWallet() async {
    final key = await _secureStorage.readPrivateKey();
    return key != null;
  }

  @override
  Future<String> createWallet() async {
    return _walletService.createWallet();
  }

  @override
  Future<void> importWallet(String mnemonic) async {
    return _walletService.importWallet(mnemonic);
  }

  @override
  Future<String?> getAddress() async {
    return _walletService.address?.hex;
  }

  @override
  Future<WalletEntity> getWalletInfo() async {
    final address = _walletService.address;
    if (address == null) throw Exception('Wallet not initialized');

    bool isDriver    = false;
    bool isPassenger = false;
    bool isRegistered = false;
    int  reputation  = 0;

    if (AppConstants.registryContract.isNotEmpty) {
      try {
        final contract = DeployedContract(
          ContractAbi.fromJson(_registryAbi, 'Registry'),
          EthereumAddress.fromHex(AppConstants.registryContract),
        );

        // check driver
        final driverResult = await _web3.call(
          contract:  contract,
          function:  contract.function('getDriver'),
          params:    [address],
        );
        final driverData = driverResult[0] as List;
        if (driverData[0].toString() != '0x${'0' * 40}') {
          isDriver    = driverData[6] as bool;
          reputation  = (driverData[4] as BigInt).toInt();
          isRegistered = true;
        }

        // check passenger
        final passengerResult = await _web3.call(
          contract:  contract,
          function:  contract.function('getPassenger'),
          params:    [address],
        );
        final passengerData = passengerResult[0] as List;
        if (passengerData[0].toString() != '0x${'0' * 40}') {
          isPassenger  = passengerData[3] as bool;
          isRegistered = true;
          if (reputation == 0) {
            reputation = (passengerData[1] as BigInt).toInt();
          }
        }
      } catch (_) {
        // contract not deployed yet — local wallet only
      }
    }

    return WalletEntity(
      address:            address.hex,
      reputationScore:    reputation,
      isDriver:           isDriver,
      isPassenger:        isPassenger,
      isArbiter:          false,
      isRegisteredOnChain: isRegistered,
    );
  }

  @override
  Future<void> deleteWallet() async {
    await _secureStorage.clearAll();
  }
}

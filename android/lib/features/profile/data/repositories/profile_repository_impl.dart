import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../shared/constants/app_constants.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final WalletService _walletService;
  final Web3Client    _web3;

  static const _registryAbi = '''[
    {
      "inputs": [{"name":"wallet","type":"address"}],
      "name": "getDriver",
      "outputs": [{"components": [
        {"name":"wallet",          "type":"address"},
        {"name":"depositAmount",   "type":"uint256"},
        {"name":"maxOrderValue",   "type":"uint256"},
        {"name":"farePerKm",       "type":"uint256"},
        {"name":"reputationScore", "type":"uint256"},
        {"name":"totalTrips",      "type":"uint256"},
        {"name":"active",          "type":"bool"},
        {"name":"kycHash",         "type":"bytes32"}
      ], "type":"tuple"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name":"wallet","type":"address"}],
      "name": "getPassenger",
      "outputs": [{"components": [
        {"name":"wallet",          "type":"address"},
        {"name":"reputationScore", "type":"uint256"},
        {"name":"totalTrips",      "type":"uint256"},
        {"name":"active",          "type":"bool"},
        {"name":"kycHash",         "type":"bytes32"}
      ], "type":"tuple"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name":"kycHash","type":"bytes32"}],
      "name": "registerPassenger",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"kycHash","type":"bytes32"}],
      "name": "registerDriver",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [{"name":"farePerKm","type":"uint256"}],
      "name": "setFarePerKm",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "topUpDriverDeposit",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    }
  ]''';

  ProfileRepositoryImpl({required WalletService walletService})
      : _walletService = walletService,
        _web3 = Web3Client(AppConstants.polygonRpcUrl, http.Client());

  DeployedContract get _contract => DeployedContract(
    ContractAbi.fromJson(_registryAbi, 'Registry'),
    EthereumAddress.fromHex(AppConstants.registryContract),
  );

  @override
  Future<ProfileEntity> getProfile(String address) async {
    bool   isDriver    = false;
    bool   isPassenger = false;
    int    reputation  = 0;
    int    totalTrips  = 0;
    BigInt deposit     = BigInt.zero;
    BigInt maxOrder    = BigInt.zero;
    BigInt? farePerKm;
    bool   active      = false;

    try {
      final dResult = await _web3.call(
        contract: _contract,
        function: _contract.function('getDriver'),
        params:   [EthereumAddress.fromHex(address)],
      );
      final d = dResult[0] as List;
      if ((d[0] as EthereumAddress).hex.toLowerCase() != '0x${'0' * 40}') {
        isDriver   = true;
        deposit    = d[1] as BigInt;
        maxOrder   = d[2] as BigInt;
        farePerKm  = d[3] as BigInt;
        reputation = (d[4] as BigInt).toInt();
        totalTrips = (d[5] as BigInt).toInt();
        active     = d[6] as bool;
      }
    } catch (_) {}

    try {
      final pResult = await _web3.call(
        contract: _contract,
        function: _contract.function('getPassenger'),
        params:   [EthereumAddress.fromHex(address)],
      );
      final p = pResult[0] as List;
      if ((p[0] as EthereumAddress).hex.toLowerCase() != '0x${'0' * 40}') {
        isPassenger = true;
        if (reputation == 0) reputation = (p[1] as BigInt).toInt();
        if (totalTrips == 0) totalTrips  = (p[2] as BigInt).toInt();
        if (!active)         active      = p[3] as bool;
      }
    } catch (_) {}

    return ProfileEntity(
      address:        address,
      isDriver:       isDriver,
      isPassenger:    isPassenger,
      isArbiter:      false,
      reputationScore: reputation,
      totalTrips:     totalTrips,
      depositAmount:  deposit,
      maxOrderValue:  maxOrder,
      farePerKm:      farePerKm,
      active:         active,
    );
  }

  @override
  Future<void> registerAsDriver(String kycHash, BigInt depositWei) async {
    final credentials = EthPrivateKey.fromHex(await _getKey());
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('registerDriver'),
        parameters: [_toBytes32(kycHash)],
        value:      EtherAmount.inWei(depositWei),
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  @override
  Future<void> registerAsPassenger(String kycHash) async {
    final credentials = EthPrivateKey.fromHex(await _getKey());
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('registerPassenger'),
        parameters: [_toBytes32(kycHash)],
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  @override
  Future<void> setFarePerKm(BigInt farePerKm) async {
    final credentials = EthPrivateKey.fromHex(await _getKey());
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('setFarePerKm'),
        parameters: [farePerKm],
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  @override
  Future<void> topUpDeposit(BigInt amountWei) async {
    final credentials = EthPrivateKey.fromHex(await _getKey());
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('topUpDriverDeposit'),
        parameters: [],
        value:      EtherAmount.inWei(amountWei),
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  List<int> _toBytes32(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = List<int>.filled(32, 0);
    for (int i = 0; i < clean.length ~/ 2 && i < 32; i++) {
      bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  Future<String> _getKey() async {
    throw UnimplementedError('Use WalletService signing');
  }
}

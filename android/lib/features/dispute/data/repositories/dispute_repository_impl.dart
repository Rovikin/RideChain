import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/dispute_entity.dart';
import '../../domain/repositories/dispute_repository.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../shared/constants/app_constants.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  final WalletService _walletService;
  final Web3Client    _web3;

  static const _disputeAbi = '''[
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "getDisputeBySession",
      "outputs": [{"components": [
        {"name":"disputeId",      "type":"bytes32"},
        {"name":"sessionId",      "type":"bytes32"},
        {"name":"driver",         "type":"address"},
        {"name":"passenger",      "type":"address"},
        {"name":"arbiter",        "type":"address"},
        {"name":"arbiterFee",     "type":"uint256"},
        {"name":"arbiterDeposit", "type":"uint256"},
        {"name":"status",         "type":"uint8"},
        {"name":"driverWins",     "type":"bool"},
        {"name":"createdAt",      "type":"uint256"},
        {"name":"updatedAt",      "type":"uint256"},
        {"name":"resolveDeadline","type":"uint256"}
      ], "type":"tuple"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {"name":"disputeId","type":"bytes32"},
        {"name":"rating",   "type":"uint256"}
      ],
      "name": "rateArbiter",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"disputeId","type":"bytes32"}],
      "name": "triggerReassignment",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]''';

  DisputeRepositoryImpl({required WalletService walletService})
      : _walletService = walletService,
        _web3 = Web3Client(AppConstants.polygonRpcUrl, http.Client());

  DeployedContract get _contract => DeployedContract(
    ContractAbi.fromJson(_disputeAbi, 'Dispute'),
    EthereumAddress.fromHex(AppConstants.disputeContract),
  );

  @override
  Future<DisputeEntity> getDisputeBySession(String sessionId) async {
    final result = await _web3.call(
      contract: _contract,
      function: _contract.function('getDisputeBySession'),
      params:   [_toBytes32(sessionId)],
    );
    return _parseDispute(result[0] as List);
  }

  @override
  Future<DisputeEntity> openDispute(
    String sessionId,
    BigInt arbiterFee,
  ) async {
    // dispute is opened via RideSession.openDispute
    // this is a passthrough — actual call is in TripRepository
    throw UnimplementedError('Use TripRepository.openDispute');
  }

  @override
  Future<void> rateArbiter(String disputeId, int rating) async {
    final credentials = EthPrivateKey.fromHex(
      await _getPrivateKeyHex(),
    );
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('rateArbiter'),
        parameters: [_toBytes32(disputeId), BigInt.from(rating)],
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  @override
  Future<void> triggerReassignment(String disputeId) async {
    final credentials = EthPrivateKey.fromHex(
      await _getPrivateKeyHex(),
    );
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function('triggerReassignment'),
        parameters: [_toBytes32(disputeId)],
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  DisputeEntity _parseDispute(List data) {
    final statusIndex = (data[7] as BigInt).toInt();
    return DisputeEntity(
      disputeId:        _bytesToHex(data[0]),
      sessionId:        _bytesToHex(data[1]),
      driverAddress:    (data[2] as EthereumAddress).hex,
      passengerAddress: (data[3] as EthereumAddress).hex,
      arbiterAddress:   (data[4] as EthereumAddress).hex,
      arbiterFee:       data[5] as BigInt,
      status:           DisputeStatus.values[statusIndex],
      driverWins:       data[8] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data[9] as BigInt).toInt() * 1000,
      ),
      resolveDeadline: DateTime.fromMillisecondsSinceEpoch(
        (data[11] as BigInt).toInt() * 1000,
      ),
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

  String _bytesToHex(dynamic bytes) => '0x$bytes';

  Future<String> _getPrivateKeyHex() async {
    throw UnimplementedError('Use WalletService signing');
  }
}

import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../shared/constants/app_constants.dart';

class TripRepositoryImpl implements TripRepository {
  final WalletService _walletService;
  final Web3Client    _web3;

  static const _rideSessionAbi = '''[
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "getSession",
      "outputs": [{"components": [
        {"name":"sessionId",        "type":"bytes32"},
        {"name":"driver",           "type":"address"},
        {"name":"passenger",        "type":"address"},
        {"name":"escrowAmount",     "type":"uint256"},
        {"name":"fareAmount",       "type":"uint256"},
        {"name":"routingFee",       "type":"uint256"},
        {"name":"pickupLat",        "type":"int256"},
        {"name":"pickupLng",        "type":"int256"},
        {"name":"dropoffLat",       "type":"int256"},
        {"name":"dropoffLng",       "type":"int256"},
        {"name":"estimatedDistance","type":"uint256"},
        {"name":"gpsMerkleRoot",    "type":"bytes32"},
        {"name":"state",            "type":"uint8"},
        {"name":"createdAt",        "type":"uint256"},
        {"name":"updatedAt",        "type":"uint256"}
      ], "type":"tuple"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "acceptOrder",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "arrivedAtPickup",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "startTrip",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"name":"sessionId",    "type":"bytes32"},
        {"name":"gpsMerkleRoot","type":"bytes32"}
      ],
      "name": "completeTrip",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "confirmTrip",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "cancelByPassenger",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name":"sessionId","type":"bytes32"}],
      "name": "triggerTimeout",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed":true, "name":"sessionId","type":"bytes32"},
        {"indexed":false,"name":"oldState", "type":"uint8"},
        {"indexed":false,"name":"newState", "type":"uint8"}
      ],
      "name": "StateChanged",
      "type": "event"
    }
  ]''';

  TripRepositoryImpl({required WalletService walletService})
      : _walletService = walletService,
        _web3 = Web3Client(AppConstants.polygonRpcUrl, http.Client());

  DeployedContract get _contract => DeployedContract(
    ContractAbi.fromJson(_rideSessionAbi, 'RideSession'),
    EthereumAddress.fromHex(AppConstants.rideSessionContract),
  );

  @override
  Future<TripEntity> getTrip(String sessionId) async {
    final result = await _web3.call(
      contract: _contract,
      function: _contract.function('getSession'),
      params:   [_toBytes32(sessionId)],
    );

    return _parseSession(result[0] as List, sessionId);
  }

  @override
  Future<void> acceptOrder(String sessionId) =>
      _sendTx('acceptOrder', [_toBytes32(sessionId)]);

  @override
  Future<void> arrivedAtPickup(String sessionId) =>
      _sendTx('arrivedAtPickup', [_toBytes32(sessionId)]);

  @override
  Future<void> startTrip(String sessionId) =>
      _sendTx('startTrip', [_toBytes32(sessionId)]);

  @override
  Future<void> completeTrip(String sessionId, String gpsMerkleRoot) =>
      _sendTx('completeTrip', [
        _toBytes32(sessionId),
        _toBytes32(gpsMerkleRoot),
      ]);

  @override
  Future<void> confirmTrip(String sessionId) =>
      _sendTx('confirmTrip', [_toBytes32(sessionId)]);

  @override
  Future<void> cancelTrip(String sessionId) =>
      _sendTx('cancelByPassenger', [_toBytes32(sessionId)]);

  @override
  Future<void> triggerTimeout(String sessionId) =>
      _sendTx('triggerTimeout', [_toBytes32(sessionId)]);

  @override
  Stream<TripEntity> watchTrip(String sessionId) async* {
    // poll every 5 seconds
    while (true) {
      try {
        yield await getTrip(sessionId);
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // -------------------------
  // Helpers
  // -------------------------

  Future<void> _sendTx(String functionName, List params) async {
    final credentials = EthPrivateKey.fromHex(
      await _getPrivateKeyHex(),
    );
    await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract:   _contract,
        function:   _contract.function(functionName),
        parameters: params,
      ),
      chainId: AppConstants.polygonChainId,
    );
  }

  TripEntity _parseSession(List data, String sessionId) {
    final stateIndex = (data[12] as BigInt).toInt();
    return TripEntity(
      sessionId:               sessionId,
      driverAddress:           (data[1] as EthereumAddress).hex,
      passengerAddress:        (data[2] as EthereumAddress).hex,
      pickupLat:               (data[6] as BigInt).toInt() / 1e6,
      pickupLng:               (data[7] as BigInt).toInt() / 1e6,
      dropoffLat:              (data[8] as BigInt).toInt() / 1e6,
      dropoffLng:              (data[9] as BigInt).toInt() / 1e6,
      pickupLabel:             'Pickup',
      dropoffLabel:            'Dropoff',
      estimatedDistanceMeters: (data[10] as BigInt).toInt(),
      fareAmount:              data[4] as BigInt,
      escrowAmount:            data[3] as BigInt,
      state:                   TripState.values[stateIndex],
      gpsMerkleRoot:           null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data[13] as BigInt).toInt() * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data[14] as BigInt).toInt() * 1000,
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

  Future<String> _getPrivateKeyHex() async {
    throw UnimplementedError('Use WalletService signing');
  }
}

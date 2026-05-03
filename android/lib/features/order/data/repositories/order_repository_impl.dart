import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/network/node_client.dart';
import '../../../../shared/constants/app_constants.dart';

class OrderRepositoryImpl implements OrderRepository {
  final WalletService _walletService;
  final NodeClient    _nodeClient;
  final Web3Client    _web3;

  static const _orderBookAbi = '''[
    {
      "inputs": [
        {"name": "driver",            "type": "address"},
        {"name": "pickupLat",         "type": "int256"},
        {"name": "pickupLng",         "type": "int256"},
        {"name": "dropoffLat",        "type": "int256"},
        {"name": "dropoffLng",        "type": "int256"},
        {"name": "estimatedDistance", "type": "uint256"},
        {"name": "routingNode",       "type": "address"}
      ],
      "name": "createOrder",
      "outputs": [{"name": "orderId", "type": "bytes32"}],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "driver",        "type": "address"},
        {"name": "distanceMeters","type": "uint256"}
      ],
      "name": "calculateFare",
      "outputs": [
        {"name": "fare",       "type": "uint256"},
        {"name": "routingFee", "type": "uint256"},
        {"name": "total",      "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]''';

  OrderRepositoryImpl({
    required WalletService walletService,
    required NodeClient    nodeClient,
  })  : _walletService = walletService,
        _nodeClient    = nodeClient,
        _web3 = Web3Client(AppConstants.polygonRpcUrl, http.Client());

  @override
  Future<Map<String, dynamic>> calculateFare({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    // get route from nodes
    final route = await _nodeClient.getRoute(
      pickupLat:  pickupLat,
      pickupLng:  pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
    );

    // get fare from contract if deployed
    BigInt fare       = BigInt.zero;
    BigInt routingFee = BigInt.zero;
    BigInt total      = BigInt.zero;

    if (AppConstants.orderBookContract.isNotEmpty) {
      final contract = DeployedContract(
        ContractAbi.fromJson(_orderBookAbi, 'OrderBook'),
        EthereumAddress.fromHex(AppConstants.orderBookContract),
      );

      final result = await _web3.call(
        contract: contract,
        function: contract.function('calculateFare'),
        params:   [
          EthereumAddress.fromHex(driverAddress),
          BigInt.from(route.distanceMeters),
        ],
      );

      fare       = result[0] as BigInt;
      routingFee = result[1] as BigInt;
      total      = result[2] as BigInt;
    }

    return {
      'distanceMeters':  route.distanceMeters,
      'durationSeconds': route.durationSeconds,
      'fare':            fare,
      'routingFee':      routingFee,
      'total':           total,
      'source':          route.source,
    };
  }

  @override
  Future<OrderEntity> createOrder({
    required String driverAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String pickupLabel,
    required String dropoffLabel,
    required int    estimatedDistanceMeters,
    required String routingNodeAddress,
  }) async {
    if (AppConstants.orderBookContract.isEmpty) {
      throw Exception('Contract not deployed yet');
    }

    final contract = DeployedContract(
      ContractAbi.fromJson(_orderBookAbi, 'OrderBook'),
      EthereumAddress.fromHex(AppConstants.orderBookContract),
    );

    // calculate total payment
    final fareData = await calculateFare(
      driverAddress: driverAddress,
      pickupLat:     pickupLat,
      pickupLng:     pickupLng,
      dropoffLat:    dropoffLat,
      dropoffLng:    dropoffLng,
    );

    final total      = fareData['total'] as BigInt;
    final gasBuffer  = BigInt.from(10).pow(15); // 0.001 MATIC
    final payment    = total + gasBuffer;

    // encode coordinates as int256 × 1e6
    final pLat = BigInt.from((pickupLat  * 1e6).round());
    final pLng = BigInt.from((pickupLng  * 1e6).round());
    final dLat = BigInt.from((dropoffLat * 1e6).round());
    final dLng = BigInt.from((dropoffLng * 1e6).round());

    final credentials = EthPrivateKey.fromHex(
      await _getPrivateKeyHex(),
    );

    final txHash = await _web3.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: contract.function('createOrder'),
        parameters: [
          EthereumAddress.fromHex(driverAddress),
          pLat, pLng, dLat, dLng,
          BigInt.from(estimatedDistanceMeters),
          EthereumAddress.fromHex(routingNodeAddress),
        ],
        value: EtherAmount.inWei(payment),
      ),
      chainId: AppConstants.polygonChainId,
    );

    return OrderEntity(
      orderId:                 txHash,
      driverAddress:           driverAddress,
      passengerAddress:        _walletService.address?.hex ?? '',
      pickupLat:               pickupLat,
      pickupLng:               pickupLng,
      dropoffLat:              dropoffLat,
      dropoffLng:              dropoffLng,
      pickupLabel:             pickupLabel,
      dropoffLabel:            dropoffLabel,
      estimatedDistanceMeters: estimatedDistanceMeters,
      estimatedFare:           fareData['fare'] as BigInt,
      routingFee:              fareData['routingFee'] as BigInt,
      status:                  OrderStatus.matched,
      createdAt:               DateTime.now(),
    );
  }

  @override
  Future<OrderEntity> getOrder(String orderId) async {
    throw UnimplementedError();
  }

  Future<String> _getPrivateKeyHex() async {
    // delegated to wallet service
    throw UnimplementedError('Use WalletService signing');
  }
}

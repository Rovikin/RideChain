import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../../core/network/node_client.dart';
import '../../../../shared/constants/app_constants.dart';

class HomeRepositoryImpl implements HomeRepository {
  final NodeClient _nodeClient;
  final Web3Client _web3;
  final Dio        _dio;

  HomeRepositoryImpl({required NodeClient nodeClient})
      : _nodeClient = nodeClient,
        _web3 = Web3Client(AppConstants.polygonRpcUrl, http.Client()),
        _dio  = Dio();

  @override
  Future<BalanceEntity> getBalance(String address) async {
    final weiBalance = await _web3.getBalance(
      EthereumAddress.fromHex(address),
    );

    final maticBalance = weiBalance.getValueInUnit(EtherUnit.ether);

    double? idrRate;
    try {
      idrRate = await getMaticIdrRate();
    } catch (_) {}

    return BalanceEntity(
      weiBalance:    weiBalance.getInWei,
      maticBalance:  maticBalance,
      idrEquivalent: idrRate != null ? maticBalance * idrRate : null,
    );
  }

  @override
  Future<List<DriverEntity>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
  }) async {
    final presences = await _nodeClient.getNearbyDrivers(
      lat:          lat,
      lng:          lng,
      radiusMeters: radiusMeters,
    );

    return presences.map((p) => DriverEntity(
      address:        p.address,
      farePerKm:      p.farePerKm,
      depositAmount:  BigInt.zero,
      maxOrderValue:  BigInt.zero,
      reputationScore: p.reputationScore,
      totalTrips:     0,
      active:         true,
      distanceMeters: p.distanceMeters,
    )).toList();
  }

  @override
  Future<double> getMaticIdrRate() async {
    final res = await _dio.get(
      'https://api.coingecko.com/api/v3/simple/price',
      queryParameters: {
        'ids':           'matic-network',
        'vs_currencies': 'idr',
      },
    ).timeout(const Duration(seconds: 5));

    return (res.data['matic-network']['idr'] as num).toDouble();
  }
}

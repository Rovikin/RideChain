import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/usecases/get_balance_usecase.dart';
import '../../domain/usecases/get_nearby_drivers_usecase.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../../core/network/node_client.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final NodeClient _nodeClient;

  late final GetBalanceUsecase       _getBalance;
  late final GetNearbyDriversUsecase _getNearbyDrivers;

  HomeBloc({required NodeClient nodeClient})
      : _nodeClient = nodeClient,
        super(HomeInitial()) {
    final repo = HomeRepositoryImpl(nodeClient: nodeClient);
    _getBalance       = GetBalanceUsecase(repo);
    _getNearbyDrivers = GetNearbyDriversUsecase(repo);

    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeDriversRefreshed>(_onDriversRefreshed);
    on<HomeBalanceRefreshed>(_onBalanceRefreshed);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    try {
      // get balance
      final balance = await _getBalance(event.address);

      // get location and nearby drivers
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}

      List drivers = [];
      if (position != null) {
        drivers = await _getNearbyDrivers(
          lat: position.latitude,
          lng: position.longitude,
        );
      }

      emit(HomeLoaded(
        balance: balance,
        drivers: List.from(drivers),
        userLat: position?.latitude,
        userLng: position?.longitude,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onDriversRefreshed(
    HomeDriversRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    try {
      final drivers = await _getNearbyDrivers(
        lat: event.lat,
        lng: event.lng,
      );
      emit(current.copyWith(drivers: List.from(drivers)));
    } catch (_) {}
  }

  Future<void> _onBalanceRefreshed(
    HomeBalanceRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    try {
      final balance = await _getBalance(event.address);
      emit(current.copyWith(balance: balance));
    } catch (_) {}
  }
}

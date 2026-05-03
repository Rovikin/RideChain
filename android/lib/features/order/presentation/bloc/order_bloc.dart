import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/calculate_fare_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/network/node_client.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  late final CalculateFareUsecase _calculateFare;
  late final CreateOrderUsecase   _createOrder;

  // temp storage between events
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _pickupLabel;
  String? _dropoffLabel;

  OrderBloc({
    required WalletService walletService,
    required NodeClient    nodeClient,
  }) : super(OrderInitial()) {
    final repo = OrderRepositoryImpl(
      walletService: walletService,
      nodeClient:    nodeClient,
    );
    _calculateFare = CalculateFareUsecase(repo);
    _createOrder   = CreateOrderUsecase(repo);

    on<OrderDriverSelected>(_onDriverSelected);
    on<OrderLocationSet>(_onLocationSet);
    on<OrderFareRequested>(_onFareRequested);
    on<OrderSubmitted>(_onSubmitted);
  }

  void _onDriverSelected(
    OrderDriverSelected event,
    Emitter<OrderState> emit,
  ) {
    emit(OrderLocationPicking(event.driver));
  }

  void _onLocationSet(
    OrderLocationSet event,
    Emitter<OrderState> emit,
  ) {
    _pickupLat    = event.pickupLat;
    _pickupLng    = event.pickupLng;
    _dropoffLat   = event.dropoffLat;
    _dropoffLng   = event.dropoffLng;
    _pickupLabel  = event.pickupLabel;
    _dropoffLabel = event.dropoffLabel;

    add(OrderFareRequested());
  }

  Future<void> _onFareRequested(
    OrderFareRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrderLocationPicking) return;
    final driver = (state as OrderLocationPicking).driver;

    emit(OrderFareLoading());

    try {
      final result = await _calculateFare(
        driverAddress: driver.address,
        pickupLat:     _pickupLat!,
        pickupLng:     _pickupLng!,
        dropoffLat:    _dropoffLat!,
        dropoffLng:    _dropoffLng!,
      );

      emit(OrderFareLoaded(
        driver:          driver,
        distanceMeters:  result['distanceMeters'] as int,
        durationSeconds: result['durationSeconds'] as int,
        fare:            result['fare']       as BigInt,
        routingFee:      result['routingFee'] as BigInt,
        total:           result['total']      as BigInt,
        pickupLat:       _pickupLat!,
        pickupLng:       _pickupLng!,
        dropoffLat:      _dropoffLat!,
        dropoffLng:      _dropoffLng!,
        pickupLabel:     _pickupLabel!,
        dropoffLabel:    _dropoffLabel!,
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onSubmitted(
    OrderSubmitted event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrderFareLoaded) return;
    final fareState = state as OrderFareLoaded;

    emit(OrderSubmitting());

    try {
      final order = await _createOrder(
        driverAddress:           fareState.driver.address,
        pickupLat:               fareState.pickupLat,
        pickupLng:               fareState.pickupLng,
        dropoffLat:              fareState.dropoffLat,
        dropoffLng:              fareState.dropoffLng,
        pickupLabel:             fareState.pickupLabel,
        dropoffLabel:            fareState.dropoffLabel,
        estimatedDistanceMeters: fareState.distanceMeters,
        routingNodeAddress:      event.routingNodeAddress,
      );

      emit(OrderSuccess(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}

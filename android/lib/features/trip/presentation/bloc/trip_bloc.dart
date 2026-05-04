import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/get_trip_usecase.dart';
import '../../domain/usecases/confirm_trip_usecase.dart';
import '../../domain/usecases/complete_trip_usecase.dart';
import '../../domain/usecases/watch_trip_usecase.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/crypto/gps_tracker.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripBlocState> {
  late final GetTripUsecase      _getTrip;
  late final ConfirmTripUsecase  _confirmTrip;
  late final CompleteTripUsecase _completeTrip;
  late final WatchTripUsecase    _watchTrip;

  final GpsTracker _gpsTracker = GpsTracker();
  StreamSubscription<TripEntity>? _tripWatcher;

  TripBloc({required WalletService walletService})
      : super(TripInitial()) {
    final repo = TripRepositoryImpl(walletService: walletService);
    _getTrip      = GetTripUsecase(repo);
    _confirmTrip  = ConfirmTripUsecase(repo);
    _completeTrip = CompleteTripUsecase(repo);
    _watchTrip    = WatchTripUsecase(repo);

    on<TripLoadRequested>(_onLoadRequested);
    on<TripWatchStarted>(_onWatchStarted);
    on<TripStateUpdated>(_onStateUpdated);
    on<TripAcceptRequested>(_onAcceptRequested);
    on<TripArrivedAtPickup>(_onArrivedAtPickup);
    on<TripStartRequested>(_onStartRequested);
    on<TripCompleteRequested>(_onCompleteRequested);
    on<TripConfirmRequested>(_onConfirmRequested);
    on<TripCancelRequested>(_onCancelRequested);
  }

  Future<void> _onLoadRequested(
    TripLoadRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    emit(TripLoading());
    try {
      final trip = await _getTrip(event.sessionId);
      emit(TripLoaded(trip));
      add(TripWatchStarted(event.sessionId));
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onWatchStarted(
    TripWatchStarted event,
    Emitter<TripBlocState> emit,
  ) async {
    await _tripWatcher?.cancel();
    _tripWatcher = _watchTrip(event.sessionId).listen(
      (trip) => add(TripStateUpdated(trip)),
    );
  }

  void _onStateUpdated(
    TripStateUpdated event,
    Emitter<TripBlocState> emit,
  ) {
    final trip = event.trip as TripEntity;
    if (trip.isCompleted) {
      emit(TripCompleted(trip));
    } else {
      emit(TripLoaded(trip));
    }
  }

  Future<void> _onAcceptRequested(
    TripAcceptRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'accept'));
    try {
      await TripRepositoryImpl(
        walletService: _walletService!,
      ).acceptOrder(event.sessionId);
      await _gpsTracker.startTracking();
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  Future<void> _onArrivedAtPickup(
    TripArrivedAtPickup event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'arrived'));
    try {
      await TripRepositoryImpl(
        walletService: _walletService!,
      ).arrivedAtPickup(event.sessionId);
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  Future<void> _onStartRequested(
    TripStartRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'start'));
    try {
      await TripRepositoryImpl(
        walletService: _walletService!,
      ).startTrip(event.sessionId);
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  Future<void> _onCompleteRequested(
    TripCompleteRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'complete'));
    try {
      final merkleRoot = _gpsTracker.computeMerkleRoot();
      await _gpsTracker.stopTracking();
      await _completeTrip(event.sessionId, merkleRoot);
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  Future<void> _onConfirmRequested(
    TripConfirmRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'confirm'));
    try {
      await _confirmTrip(event.sessionId);
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  Future<void> _onCancelRequested(
    TripCancelRequested event,
    Emitter<TripBlocState> emit,
  ) async {
    final current = _currentTrip;
    if (current == null) return;
    emit(TripActionLoading(current, 'cancel'));
    try {
      await TripRepositoryImpl(
        walletService: _walletService!,
      ).cancelTrip(event.sessionId);
    } catch (e) {
      emit(TripError(e.toString(), trip: current));
    }
  }

  TripEntity? get _currentTrip {
    final s = state;
    if (s is TripLoaded) return s.trip;
    if (s is TripActionLoading) return s.trip;
    if (s is TripError) return s.trip;
    return null;
  }

  // injected via constructor in real implementation
  WalletService? _walletService;

  @override
  Future<void> close() async {
    await _tripWatcher?.cancel();
    await _gpsTracker.stopTracking();
    return super.close();
  }
}

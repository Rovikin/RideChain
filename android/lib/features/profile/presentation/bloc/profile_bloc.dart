import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/register_driver_usecase.dart';
import '../../domain/usecases/set_fare_usecase.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../../core/wallet/wallet_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileBlocState> {
  final WalletService    _walletService;
  late final GetProfileUsecase      _getProfile;
  late final RegisterDriverUsecase  _registerDriver;
  late final SetFareUsecase         _setFare;

  ProfileBloc({required WalletService walletService})
      : _walletService = walletService,
        super(ProfileInitial()) {
    final repo = ProfileRepositoryImpl(walletService: walletService);
    _getProfile     = GetProfileUsecase(repo);
    _registerDriver = RegisterDriverUsecase(repo);
    _setFare        = SetFareUsecase(repo);

    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileDriverRegistered>(_onDriverRegistered);
    on<ProfilePassengerRegistered>(_onPassengerRegistered);
    on<ProfileFareUpdated>(_onFareUpdated);
    on<ProfileDepositToppedUp>(_onDepositToppedUp);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileBlocState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _getProfile(event.address);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onDriverRegistered(
    ProfileDriverRegistered event,
    Emitter<ProfileBlocState> emit,
  ) async {
    emit(ProfileActionLoading());
    try {
      await _registerDriver(event.kycHash, event.depositWei);
      final address = _walletService.address?.hex ?? '';
      final profile = await _getProfile(address);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onPassengerRegistered(
    ProfilePassengerRegistered event,
    Emitter<ProfileBlocState> emit,
  ) async {
    emit(ProfileActionLoading());
    try {
      await ProfileRepositoryImpl(
        walletService: _walletService,
      ).registerAsPassenger(event.kycHash);
      final address = _walletService.address?.hex ?? '';
      final profile = await _getProfile(address);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onFareUpdated(
    ProfileFareUpdated event,
    Emitter<ProfileBlocState> emit,
  ) async {
    emit(ProfileActionLoading());
    try {
      await _setFare(event.farePerKm);
      final address = _walletService.address?.hex ?? '';
      final profile = await _getProfile(address);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onDepositToppedUp(
    ProfileDepositToppedUp event,
    Emitter<ProfileBlocState> emit,
  ) async {
    emit(ProfileActionLoading());
    try {
      await ProfileRepositoryImpl(
        walletService: _walletService,
      ).topUpDeposit(event.amountWei);
      final address = _walletService.address?.hex ?? '';
      final profile = await _getProfile(address);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}

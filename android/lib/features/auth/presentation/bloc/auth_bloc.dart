import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/check_auth_usecase.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/import_wallet_usecase.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final WalletService _walletService;

  late final CheckAuthUsecase  _checkAuth;
  late final CreateWalletUsecase _createWallet;
  late final ImportWalletUsecase _importWallet;

  AuthBloc({required WalletService walletService})
      : _walletService = walletService,
        super(AuthInitial()) {
    final repo = AuthRepositoryImpl(
      walletService: walletService,
      secureStorage: SecureStorage(),
    );

    _checkAuth    = CheckAuthUsecase(repo);
    _createWallet = CreateWalletUsecase(repo);
    _importWallet = ImportWalletUsecase(repo);

    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthWalletCreated>(_onWalletCreated);
    on<AuthWalletImported>(_onWalletImported);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final wallet = await _checkAuth();
      if (wallet != null) {
        emit(AuthAuthenticated(wallet));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onWalletCreated(
    AuthWalletCreated event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final wallet = await _checkAuth();
      if (wallet != null) {
        emit(AuthAuthenticated(wallet));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onWalletImported(
    AuthWalletImported event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _importWallet(event.mnemonic);
      final wallet = await _checkAuth();
      if (wallet != null) {
        emit(AuthAuthenticated(wallet));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await SecureStorage().clearAll();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final WalletEntity wallet;
  const AuthAuthenticated(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

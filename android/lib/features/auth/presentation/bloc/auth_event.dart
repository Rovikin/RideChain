import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthWalletCreated extends AuthEvent {}

class AuthWalletImported extends AuthEvent {
  final String mnemonic;
  const AuthWalletImported(this.mnemonic);

  @override
  List<Object?> get props => [mnemonic];
}

class AuthLogoutRequested extends AuthEvent {}

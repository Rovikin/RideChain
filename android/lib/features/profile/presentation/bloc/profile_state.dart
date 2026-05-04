import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';

abstract class ProfileBlocState extends Equatable {
  const ProfileBlocState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial       extends ProfileBlocState {}
class ProfileLoading       extends ProfileBlocState {}
class ProfileActionLoading extends ProfileBlocState {}

class ProfileLoaded extends ProfileBlocState {
  final ProfileEntity profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileBlocState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

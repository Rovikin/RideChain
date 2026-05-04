import 'package:equatable/equatable.dart';
import '../../domain/entities/dispute_entity.dart';

abstract class DisputeBlocState extends Equatable {
  const DisputeBlocState();
  @override
  List<Object?> get props => [];
}

class DisputeInitial    extends DisputeBlocState {}
class DisputeLoading    extends DisputeBlocState {}

class DisputeLoaded extends DisputeBlocState {
  final DisputeEntity dispute;
  const DisputeLoaded(this.dispute);
  @override
  List<Object?> get props => [dispute];
}

class DisputeActionLoading extends DisputeBlocState {
  final DisputeEntity? dispute;
  const DisputeActionLoading({this.dispute});
  @override
  List<Object?> get props => [dispute];
}

class DisputeResolved extends DisputeBlocState {
  final DisputeEntity dispute;
  const DisputeResolved(this.dispute);
  @override
  List<Object?> get props => [dispute];
}

class DisputeError extends DisputeBlocState {
  final String         message;
  final DisputeEntity? dispute;
  const DisputeError(this.message, {this.dispute});
  @override
  List<Object?> get props => [message];
}

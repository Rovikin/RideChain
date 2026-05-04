import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_dispute_usecase.dart';
import '../../domain/usecases/open_dispute_usecase.dart';
import '../../domain/usecases/rate_arbiter_usecase.dart';
import '../../data/repositories/dispute_repository_impl.dart';
import '../../../../core/wallet/wallet_service.dart';
import 'dispute_event.dart';
import 'dispute_state.dart';

class DisputeBloc extends Bloc<DisputeEvent, DisputeBlocState> {
  late final GetDisputeUsecase   _getDispute;
  late final OpenDisputeUsecase  _openDispute;
  late final RateArbiterUsecase  _rateArbiter;

  DisputeBloc({required WalletService walletService})
      : super(DisputeInitial()) {
    final repo = DisputeRepositoryImpl(walletService: walletService);
    _getDispute  = GetDisputeUsecase(repo);
    _openDispute = OpenDisputeUsecase(repo);
    _rateArbiter = RateArbiterUsecase(repo);

    on<DisputeLoadRequested>(_onLoadRequested);
    on<DisputeOpenRequested>(_onOpenRequested);
    on<DisputeArbiterRated>(_onArbiterRated);
    on<DisputeReassignmentTriggered>(_onReassignmentTriggered);
  }

  Future<void> _onLoadRequested(
    DisputeLoadRequested event,
    Emitter<DisputeBlocState> emit,
  ) async {
    emit(DisputeLoading());
    try {
      final dispute = await _getDispute(event.sessionId);
      if (dispute.isResolved) {
        emit(DisputeResolved(dispute));
      } else {
        emit(DisputeLoaded(dispute));
      }
    } catch (e) {
      emit(DisputeError(e.toString()));
    }
  }

  Future<void> _onOpenRequested(
    DisputeOpenRequested event,
    Emitter<DisputeBlocState> emit,
  ) async {
    emit(const DisputeActionLoading());
    try {
      final dispute = await _openDispute(event.sessionId, event.arbiterFee);
      emit(DisputeLoaded(dispute));
    } catch (e) {
      emit(DisputeError(e.toString()));
    }
  }

  Future<void> _onArbiterRated(
    DisputeArbiterRated event,
    Emitter<DisputeBlocState> emit,
  ) async {
    final current = state is DisputeResolved
        ? (state as DisputeResolved).dispute
        : null;
    emit(DisputeActionLoading(dispute: current));
    try {
      await _rateArbiter(event.disputeId, event.rating);
      if (current != null) emit(DisputeResolved(current));
    } catch (e) {
      emit(DisputeError(e.toString(), dispute: current));
    }
  }

  Future<void> _onReassignmentTriggered(
    DisputeReassignmentTriggered event,
    Emitter<DisputeBlocState> emit,
  ) async {
    final current = state is DisputeLoaded
        ? (state as DisputeLoaded).dispute
        : null;
    emit(DisputeActionLoading(dispute: current));
    try {
      await DisputeRepositoryImpl(
        walletService: _dummyWallet,
      ).triggerReassignment(event.disputeId);
      if (current != null) {
        emit(DisputeLoaded(current));
      }
    } catch (e) {
      emit(DisputeError(e.toString(), dispute: current));
    }
  }

  // placeholder — injected properly in real impl
  WalletService get _dummyWallet => throw UnimplementedError();
}

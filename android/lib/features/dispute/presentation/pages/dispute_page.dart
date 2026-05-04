import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../../domain/entities/dispute_entity.dart';
import '../bloc/dispute_bloc.dart';
import '../bloc/dispute_event.dart';
import '../bloc/dispute_state.dart';
import '../widgets/dispute_status_card.dart';
import '../widgets/arbiter_rating_widget.dart';

class DisputePage extends StatelessWidget {
  final String sessionId;
  const DisputePage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DisputeBloc(
        walletService: context.read<WalletService>(),
      )..add(DisputeLoadRequested(sessionId)),
      child: _DisputeView(sessionId: sessionId),
    );
  }
}

class _DisputeView extends StatelessWidget {
  final String sessionId;
  const _DisputeView({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sengketa Perjalanan')),
      body: BlocConsumer<DisputeBloc, DisputeBlocState>(
        listener: (context, state) {
          if (state is DisputeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            DisputeInitial() || DisputeLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DisputeLoaded(dispute: final dispute) => _DisputeBody(
                dispute:   dispute,
                sessionId: sessionId,
              ),
            DisputeActionLoading(dispute: final dispute)
                when dispute != null => _DisputeBody(
                dispute:   dispute!,
                sessionId: sessionId,
                isLoading: true,
              ),
            DisputeResolved(dispute: final dispute) => _ResolvedBody(
                dispute: dispute,
              ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}

class _DisputeBody extends StatelessWidget {
  final DisputeEntity dispute;
  final String        sessionId;
  final bool          isLoading;

  const _DisputeBody({
    required this.dispute,
    required this.sessionId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisputeStatusCard(dispute: dispute),
          const SizedBox(height: 24),

          // arbiter info
          _SectionTitle('Arbitrer'),
          _InfoRow('Alamat', '${dispute.arbiterAddress.substring(0, 10)}...'),
          _InfoRow('Status', _statusLabel(dispute.status)),
          _InfoRow(
            'Deadline',
            dispute.resolveDeadline.toLocal().toString().substring(0, 16),
          ),

          const SizedBox(height: 24),

          // parties
          _SectionTitle('Pihak yang Bersengketa'),
          _InfoRow('Pengemudi',  '${dispute.driverAddress.substring(0, 10)}...'),
          _InfoRow('Penumpang', '${dispute.passengerAddress.substring(0, 10)}...'),

          const SizedBox(height: 24),

          // explanation
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proses Sengketa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Arbitrer dipilih secara acak dari komunitas\n'
                  '2. Arbitrer membaca bukti perjalanan (GPS Merkle proof)\n'
                  '3. Arbitrer memutuskan dalam batas waktu\n'
                  '4. Pihak yang kalah dikenakan potongan deposit\n'
                  '5. Pemenang memberikan rating ke arbitrer',
                  style: TextStyle(color: Colors.blue[800], height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // trigger reassignment if expired
          if (dispute.isExpired && !isLoading)
            ElevatedButton.icon(
              onPressed: () => context.read<DisputeBloc>()
                  .add(DisputeReassignmentTriggered(dispute.disputeId)),
              icon:  const Icon(Icons.refresh),
              label: const Text('Ganti Arbitrer (Timeout)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  String _statusLabel(DisputeStatus status) => switch (status) {
    DisputeStatus.pending    => 'Menunggu arbitrer',
    DisputeStatus.inReview   => 'Sedang ditinjau',
    DisputeStatus.resolved   => 'Selesai',
    DisputeStatus.reassigned => 'Dialihkan ke arbitrer baru',
  };
}

class _ResolvedBody extends StatelessWidget {
  final DisputeEntity dispute;
  const _ResolvedBody({required this.dispute});

  @override
  Widget build(BuildContext context) {
    final address  = context.read<WalletService>().address?.hex ?? '';
    final isDriver = address.toLowerCase() == dispute.driverAddress.toLowerCase();
    final iWon     = (isDriver && dispute.driverWins) ||
                     (!isDriver && !dispute.driverWins);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          Icon(
            iWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size:  80,
            color: iWon ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 16),

          Text(
            iWon ? 'Sengketa Dimenangkan' : 'Sengketa Tidak Dimenangkan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            iWon
                ? 'Dana akan dikembalikan ke akun Anda'
                : 'Deposit Anda telah dipotong sesuai keputusan arbitrer',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),

          const SizedBox(height: 48),

          if (iWon) ...[
            Text(
              'Beri Rating Arbitrer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ArbiterRatingWidget(
              onRated: (rating) => context.read<DisputeBloc>().add(
                DisputeArbiterRated(dispute.disputeId, rating),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value,  style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

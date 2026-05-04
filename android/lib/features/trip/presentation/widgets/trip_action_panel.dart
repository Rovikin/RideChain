import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../../domain/entities/trip_entity.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';

class TripActionPanel extends StatelessWidget {
  final TripEntity trip;
  final String     sessionId;
  final bool       isLoading;

  const TripActionPanel({
    super.key,
    required this.trip,
    required this.sessionId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final address   = context.read<WalletService>().address?.hex ?? '';
    final isDriver  = address.toLowerCase() == trip.driverAddress.toLowerCase();

    return Container(
      padding:    const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // route info
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.pickupLabel, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(child: Text(trip.dropoffLabel, overflow: TextOverflow.ellipsis)),
            ],
          ),

          const Divider(height: 24),

          // action buttons
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildActions(context, isDriver),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDriver) {
    return switch (trip.state) {
      TripState.created when isDriver => ElevatedButton.icon(
          onPressed: () => context.read<TripBloc>()
              .add(TripAcceptRequested(sessionId)),
          icon:  const Icon(Icons.check),
          label: const Text('Terima Order'),
        ),
      TripState.accepted when isDriver => ElevatedButton.icon(
          onPressed: () => context.read<TripBloc>()
              .add(TripArrivedAtPickup(sessionId)),
          icon:  const Icon(Icons.where_to_vote),
          label: const Text('Tiba di Lokasi Jemput'),
        ),
      TripState.pickingUp when isDriver => ElevatedButton.icon(
          onPressed: () => context.read<TripBloc>()
              .add(TripStartRequested(sessionId)),
          icon:  const Icon(Icons.navigation),
          label: const Text('Mulai Perjalanan'),
        ),
      TripState.inProgress when isDriver => ElevatedButton.icon(
          onPressed: () => context.read<TripBloc>()
              .add(TripCompleteRequested(sessionId, '')),
          icon:  const Icon(Icons.flag),
          label: const Text('Selesai Antar'),
        ),
      TripState.completed when !isDriver => Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.read<TripBloc>()
                    .add(TripConfirmRequested(sessionId)),
                icon:  const Icon(Icons.check_circle),
                label: const Text('Konfirmasi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home/dispute/$sessionId'),
                icon:  const Icon(Icons.gavel),
                label: const Text('Ajukan Sengketa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      TripState.created when !isDriver => OutlinedButton.icon(
          onPressed: () => context.read<TripBloc>()
              .add(TripCancelRequested(sessionId)),
          icon:  const Icon(Icons.cancel),
          label: const Text('Batalkan'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../../../shared/constants/app_constants.dart';

class FareSummarySheet extends StatelessWidget {
  final OrderFareLoaded state;
  const FareSummarySheet({super.key, required this.state});

  String _formatWei(BigInt wei) {
    if (wei == BigInt.zero) return '0 MATIC';
    final matic = wei / BigInt.from(10).pow(18);
    return '$matic MATIC';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes menit';
    return '${minutes ~/ 60} jam ${minutes % 60} menit';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Perjalanan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // route summary
          _RouteRow(
            pickupLabel:  state.pickupLabel,
            dropoffLabel: state.dropoffLabel,
          ),

          const SizedBox(height: 24),

          // trip details
          _DetailRow(
            label: 'Jarak estimasi',
            value: '${(state.distanceMeters / 1000).toStringAsFixed(1)} km',
          ),
          _DetailRow(
            label: 'Waktu estimasi',
            value: _formatDuration(state.durationSeconds),
          ),

          const Divider(height: 32),

          // fare breakdown
          _DetailRow(
            label: 'Tarif perjalanan',
            value: _formatWei(state.fare),
          ),
          _DetailRow(
            label: 'Biaya routing (0.5%)',
            value: _formatWei(state.routingFee),
          ),

          const Divider(height: 32),

          _DetailRow(
            label:    'Total',
            value:    _formatWei(state.total),
            isBold:   true,
          ),

          const SizedBox(height: 8),

          // escrow notice
          Container(
            padding:    const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dana dikunci di smart contract escrow. '
                    'Dilepaskan ke pengemudi setelah perjalanan selesai.',
                    style: TextStyle(
                      fontSize: 12,
                      color:    Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // driver info
          Container(
            padding:    const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bike),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${state.driver.address.substring(0, 6)}...${state.driver.address.substring(state.driver.address.length - 4)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '⭐ ${state.driver.reputationDisplay}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              // use first available routing node
              // in production: selected from registry
              context.read<OrderBloc>().add(
                const OrderSubmitted(
                  'node1.ridechain.eth',
                ),
              );
            },
            child: const Text('Konfirmasi & Kunci Escrow'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickupLabel;
  final String dropoffLabel;

  const _RouteRow({
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 12, color: Colors.green),
            Container(
              width:  2,
              height: 32,
              color:  Colors.grey[300],
            ),
            const Icon(Icons.location_on, size: 16, color: Colors.red),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickupLabel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Text(
                dropoffLabel,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:      Colors.grey[600],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize:   isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

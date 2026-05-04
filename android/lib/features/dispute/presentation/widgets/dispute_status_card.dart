import 'package:flutter/material.dart';
import '../../domain/entities/dispute_entity.dart';

class DisputeStatusCard extends StatelessWidget {
  final DisputeEntity dispute;
  const DisputeStatusCard({super.key, required this.dispute});

  @override
  Widget build(BuildContext context) {
    final color = switch (dispute.status) {
      DisputeStatus.pending    => Colors.orange,
      DisputeStatus.inReview   => Colors.blue,
      DisputeStatus.resolved   => Colors.green,
      DisputeStatus.reassigned => Colors.purple,
    };

    return Container(
      padding:    const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sengketa Aktif',
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${dispute.disputeId.substring(0, 10)}...',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/trip_entity.dart';

class TripStatusBanner extends StatelessWidget {
  final TripEntity trip;
  const TripStatusBanner({super.key, required this.trip});

  ({String label, Color color, IconData icon}) get _statusInfo {
    return switch (trip.state) {
      TripState.created    => (label: 'Menunggu pengemudi', color: Colors.orange, icon: Icons.hourglass_empty),
      TripState.accepted   => (label: 'Pengemudi menuju lokasi Anda', color: Colors.blue, icon: Icons.directions_bike),
      TripState.pickingUp  => (label: 'Pengemudi tiba — silakan naik', color: Colors.green, icon: Icons.where_to_vote),
      TripState.inProgress => (label: 'Perjalanan berlangsung', color: Colors.green, icon: Icons.navigation),
      TripState.completed  => (label: 'Perjalanan selesai — konfirmasi?', color: Colors.teal, icon: Icons.check_circle_outline),
      TripState.confirmed  => (label: 'Selesai — dana dikirim ke pengemudi', color: Colors.teal, icon: Icons.check_circle),
      TripState.disputed   => (label: 'Dalam proses sengketa', color: Colors.red, icon: Icons.gavel),
      TripState.resolved   => (label: 'Sengketa diselesaikan', color: Colors.grey, icon: Icons.done_all),
      TripState.cancelled  => (label: 'Perjalanan dibatalkan', color: Colors.grey, icon: Icons.cancel),
      TripState.expired    => (label: 'Perjalanan kadaluarsa', color: Colors.grey, icon: Icons.timer_off),
      _ => (label: 'Memuat...', color: Colors.grey, icon: Icons.sync),
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo;
    return SafeArea(
      child: Container(
        margin:     const EdgeInsets.all(16),
        padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        info.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(info.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                info.label,
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

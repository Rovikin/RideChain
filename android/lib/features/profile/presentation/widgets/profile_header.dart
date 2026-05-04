import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileEntity profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // avatar
            CircleAvatar(
              radius:          36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                profile.address.substring(2, 4).toUpperCase(),
                style: TextStyle(
                  fontSize:   24,
                  fontWeight: FontWeight.bold,
                  color:      Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // address
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: profile.address));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alamat disalin')),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.shortAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 14, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: 'Reputasi',
                  value: '⭐ ${profile.reputationDisplay}',
                ),
                _Stat(
                  label: 'Total Trip',
                  value: profile.totalTrips.toString(),
                ),
                _Stat(
                  label: 'Role',
                  value: _roleLabel(profile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(ProfileEntity p) {
    if (p.isDriver && p.isPassenger) return 'Driver & Penumpang';
    if (p.isDriver)    return 'Driver';
    if (p.isPassenger) return 'Penumpang';
    return 'Belum Terdaftar';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize:   16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/profile_entity.dart';

class DriverSettingsCard extends StatefulWidget {
  final ProfileEntity profile;
  final void Function(BigInt farePerKm) onSetFare;

  const DriverSettingsCard({
    super.key,
    required this.profile,
    required this.onSetFare,
  });

  @override
  State<DriverSettingsCard> createState() => _DriverSettingsCardState();
}

class _DriverSettingsCardState extends State<DriverSettingsCard> {
  final _fareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.profile.farePerKm != null) {
      final matic = widget.profile.farePerKm! / BigInt.from(10).pow(18);
      _fareController.text = matic.toString();
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Driver',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller:  _fareController,
              decoration:  const InputDecoration(
                labelText: 'Tarif per km (MATIC)',
                hintText:  '0.001',
                prefixText: 'MATIC ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final matic = double.tryParse(_fareController.text) ?? 0;
                final wei   = BigInt.from((matic * 1e18).round());
                widget.onSetFare(wei);
              },
              child: const Text('Simpan Tarif'),
            ),
          ],
        ),
      ),
    );
  }
}

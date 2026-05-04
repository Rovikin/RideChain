import 'package:flutter/material.dart';

class RegistrationCard extends StatelessWidget {
  final void Function(String kycHash, BigInt deposit) onRegisterDriver;
  final void Function(String kycHash) onRegisterPassenger;

  const RegistrationCard({
    super.key,
    required this.onRegisterDriver,
    required this.onRegisterPassenger,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar ke Protokol',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih peran Anda di jaringan RideChain.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _showDriverRegistration(context),
              icon:  const Icon(Icons.directions_bike),
              label: const Text('Daftar sebagai Driver'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _showPassengerRegistration(context),
              icon:  const Icon(Icons.person_outline),
              label: const Text('Daftar sebagai Penumpang'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverRegistration(BuildContext context) {
    showModalBottomSheet(
      context:     context,
      isScrollControlled: true,
      builder: (_) => _DriverRegistrationSheet(
        onConfirm: onRegisterDriver,
      ),
    );
  }

  void _showPassengerRegistration(BuildContext context) {
    // simplified — KYC hash generated from device in real implementation
    onRegisterPassenger('0x' + 'ab' * 32);
  }
}

class _DriverRegistrationSheet extends StatefulWidget {
  final void Function(String kycHash, BigInt deposit) onConfirm;
  const _DriverRegistrationSheet({required this.onConfirm});

  @override
  State<_DriverRegistrationSheet> createState() =>
      _DriverRegistrationSheetState();
}

class _DriverRegistrationSheetState extends State<_DriverRegistrationSheet> {
  final _depositController = TextEditingController();

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left:   24,
        right:  24,
        top:    24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar sebagai Driver',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Deposit jaminan diperlukan (minimum 2× nilai order maksimal). '
            'Deposit dikembalikan jika Anda tidak aktif.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller:  _depositController,
            decoration:  const InputDecoration(
              labelText:   'Jumlah deposit (MATIC)',
              hintText:    '0.5',
              prefixText:  'MATIC ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final matic  = double.tryParse(_depositController.text) ?? 0;
              final wei    = BigInt.from((matic * 1e18).round());
              final kycHash = '0x' + 'cd' * 32; // placeholder
              Navigator.pop(context);
              widget.onConfirm(kycHash, wei);
            },
            child: const Text('Konfirmasi & Deposit'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

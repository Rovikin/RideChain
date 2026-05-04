import 'package:flutter/material.dart';
import '../../domain/entities/profile_entity.dart';

class DepositCard extends StatefulWidget {
  final ProfileEntity profile;
  final void Function(BigInt amount) onTopUp;

  const DepositCard({
    super.key,
    required this.profile,
    required this.onTopUp,
  });

  @override
  State<DepositCard> createState() => _DepositCardState();
}

class _DepositCardState extends State<DepositCard> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatMatic(BigInt wei) {
    final matic = wei / BigInt.from(10).pow(18);
    return '$matic MATIC';
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
              'Deposit Jaminan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Deposit saat ini',
                    style: TextStyle(color: Colors.grey[600])),
                Text(
                  _formatMatic(widget.profile.depositAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Maks. order value',
                    style: TextStyle(color: Colors.grey[600])),
                Text(
                  _formatMatic(widget.profile.maxOrderValue),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Divider(height: 24),

            TextField(
              controller:  _amountController,
              decoration:  const InputDecoration(
                labelText: 'Tambah deposit (MATIC)',
                hintText:  '0.5',
                prefixText: 'MATIC ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final matic  = double.tryParse(_amountController.text) ?? 0;
                final wei    = BigInt.from((matic * 1e18).round());
                widget.onTopUp(wei);
              },
              child: const Text('Top Up Deposit'),
            ),
          ],
        ),
      ),
    );
  }
}

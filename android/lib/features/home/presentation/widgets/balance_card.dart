import 'package:flutter/material.dart';
import '../../domain/entities/balance_entity.dart';

class BalanceCard extends StatelessWidget {
  final BalanceEntity balance;
  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size:  16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Saldo Wallet',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical:   4,
                ),
                decoration: BoxDecoration(
                  color:        Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Polygon',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            balance.maticDisplay,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (balance.idrEquivalent != null) ...[
            const SizedBox(height: 4),
            Text(
              '≈ ${balance.idrDisplay}',
              style: const TextStyle(
                color:    Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

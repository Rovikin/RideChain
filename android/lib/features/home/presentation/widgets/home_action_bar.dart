import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActionBar extends StatelessWidget {
  final double? userLat;
  final double? userLng;

  const HomeActionBar({
    super.key,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon:    Icons.add_location_alt_outlined,
            label:   'Pesan Ojek',
            onTap:   () => context.push('/home/order'),
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon:  Icons.account_balance_wallet_outlined,
            label: 'Top Up',
            onTap: () {
              // TODO: top-up flow
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon:  Icons.history,
            label: 'Riwayat',
            onTap: () {
              // TODO: history page
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final bool     primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(12),
      child:        Container(
        padding:    const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: primary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      primary
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

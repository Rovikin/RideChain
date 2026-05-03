import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // logo
              Container(
                width:  64,
                height: 64,
                decoration: BoxDecoration(
                  color:        Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_bike,
                  color: Colors.white,
                  size:  32,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'RideChain',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Platform ojek terdesentralisasi.\n'
                'Tidak ada perantara. Tidak ada potongan platform.\n'
                'Reputasi milik pengemudi sendiri.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // feature highlights
              _FeatureItem(
                icon:  Icons.lock_outline,
                title: 'Non-custodial',
                desc:  'Private key tersimpan di perangkat Anda',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon:  Icons.star_outline,
                title: 'Reputasi on-chain',
                desc:  'Rating tidak bisa dihapus oleh platform',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon:  Icons.account_balance_wallet_outlined,
                title: 'Tanpa potongan platform',
                desc:  'Hanya biaya routing 0.5% untuk infrastruktur',
              ),

              const Spacer(),

              // actions
              ElevatedButton(
                onPressed: () => context.push('/wallet/create'),
                child: const Text('Buat Wallet Baru'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => context.push('/wallet/import'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Import Wallet'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   desc;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:      const EdgeInsets.all(8),
          decoration:   BoxDecoration(
            color:        Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size:  20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                desc,
                style: TextStyle(
                  color:    Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  String?  _mnemonic;
  bool     _isLoading    = false;
  bool     _isConfirmed  = false;

  @override
  void initState() {
    super.initState();
    _generateWallet();
  }

  Future<void> _generateWallet() async {
    setState(() => _isLoading = true);
    try {
      final walletService = context.read<WalletService>();
      final mnemonic      = await walletService.createWallet();
      setState(() {
        _mnemonic  = mnemonic;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyMnemonic() {
    if (_mnemonic == null) return;
    Clipboard.setData(ClipboardData(text: _mnemonic!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seed phrase disalin')),
    );
  }

  void _continue() {
    if (!_isConfirmed) return;
    context.read<AuthBloc>().add(AuthWalletCreated());
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Wallet Baru'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // warning banner
                    Container(
                      padding:      const EdgeInsets.all(16),
                      decoration:   BoxDecoration(
                        color:        Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border:       Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Simpan seed phrase ini di tempat yang aman. '
                              'Ini adalah satu-satunya cara memulihkan wallet Anda. '
                              'Jangan bagikan ke siapapun.',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Seed Phrase',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // mnemonic grid
                    if (_mnemonic != null) ...[
                      _MnemonicGrid(mnemonic: _mnemonic!),

                      const SizedBox(height: 12),

                      // copy button
                      TextButton.icon(
                        onPressed: _copyMnemonic,
                        icon:  const Icon(Icons.copy, size: 16),
                        label: const Text('Salin seed phrase'),
                      ),
                    ],

                    const Spacer(),

                    // confirmation checkbox
                    CheckboxListTile(
                      value:    _isConfirmed,
                      onChanged: (v) => setState(() => _isConfirmed = v ?? false),
                      title: const Text(
                        'Saya sudah menyimpan seed phrase di tempat yang aman',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _isConfirmed ? _continue : null,
                      child: const Text('Lanjutkan'),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MnemonicGrid extends StatelessWidget {
  final String mnemonic;

  const _MnemonicGrid({required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');

    return Container(
      padding:      const EdgeInsets.all(16),
      decoration:   BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap:   true,
        physics:      const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing:  8,
        ),
        itemCount: words.length,
        itemBuilder: (context, index) => Container(
          padding:      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration:   BoxDecoration(
            color:        Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  color:    Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  words[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

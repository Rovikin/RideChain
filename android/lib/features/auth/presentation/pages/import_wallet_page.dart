import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ImportWalletPage extends StatefulWidget {
  const ImportWalletPage({super.key});

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final _controller = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    if (!_formKey.currentState!.validate()) return;
    final mnemonic = _controller.text.trim().toLowerCase();
    context.read<AuthBloc>().add(AuthWalletImported(mnemonic));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Wallet'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan Seed Phrase',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Masukkan 12 atau 24 kata seed phrase Anda, '
                    'dipisahkan dengan spasi.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller:  _controller,
                    maxLines:    4,
                    decoration:  const InputDecoration(
                      hintText: 'word1 word2 word3 ...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Seed phrase tidak boleh kosong';
                      }
                      final words = value.trim().split(' ');
                      if (words.length != 12 && words.length != 24) {
                        return 'Seed phrase harus 12 atau 24 kata';
                      }
                      return null;
                    },
                  ),

                  const Spacer(),

                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _import,
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width:  20,
                                child:  CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:       Colors.white,
                                ),
                              )
                            : const Text('Import Wallet'),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

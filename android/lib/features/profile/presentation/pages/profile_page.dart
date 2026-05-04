import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/registration_card.dart';
import '../widgets/driver_settings_card.dart';
import '../widgets/deposit_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final address = context.read<WalletService>().address?.hex ?? '';
    return BlocProvider(
      create: (context) => ProfileBloc(
        walletService: context.read<WalletService>(),
      )..add(ProfileLoadRequested(address)),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: BlocConsumer<ProfileBloc, ProfileBlocState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            ProfileInitial() || ProfileLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProfileActionLoading() => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memproses transaksi...'),
                  ],
                ),
              ),
            ProfileLoaded(profile: final profile) => RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(
                    ProfileLoadRequested(profile.address),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ProfileHeader(profile: profile),
                      const SizedBox(height: 16),

                      if (!profile.isDriver && !profile.isPassenger)
                        RegistrationCard(
                          onRegisterDriver:    (kycHash, deposit) =>
                              context.read<ProfileBloc>().add(
                                ProfileDriverRegistered(kycHash, deposit),
                              ),
                          onRegisterPassenger: (kycHash) =>
                              context.read<ProfileBloc>().add(
                                ProfilePassengerRegistered(kycHash),
                              ),
                        ),

                      if (profile.isDriver) ...[
                        const SizedBox(height: 16),
                        DriverSettingsCard(
                          profile:   profile,
                          onSetFare: (fare) =>
                              context.read<ProfileBloc>().add(
                                ProfileFareUpdated(fare),
                              ),
                        ),
                        const SizedBox(height: 16),
                        DepositCard(
                          profile:    profile,
                          onTopUp:    (amount) =>
                              context.read<ProfileBloc>().add(
                                ProfileDepositToppedUp(amount),
                              ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ProfileError(message: final msg) => Center(
                child: Text(msg),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

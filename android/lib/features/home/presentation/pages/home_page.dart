import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/node_client.dart';
import '../../../../core/wallet/wallet_service.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/driver_list.dart';
import '../widgets/home_action_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        nodeClient: context.read<NodeClient>(),
      )..add(HomeLoadRequested(
          context.read<WalletService>().address?.hex ?? '',
        )),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RideChain'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.person_outline),
            onPressed: () => context.push('/home/profile'),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final address = context
                          .read<WalletService>()
                          .address?.hex ?? '';
                      context.read<HomeBloc>()
                          .add(HomeLoadRequested(address));
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                final address = context
                    .read<WalletService>()
                    .address?.hex ?? '';
                context.read<HomeBloc>()
                    .add(HomeLoadRequested(address));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BalanceCard(balance: state.balance),
                          const SizedBox(height: 16),
                          HomeActionBar(
                            userLat: state.userLat,
                            userLng: state.userLng,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Pengemudi Terdekat',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  DriverList(drivers: state.drivers),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

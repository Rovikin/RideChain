import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../../../../core/network/node_client.dart';
import '../../../home/domain/entities/driver_entity.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/fare_summary_sheet.dart';
import '../widgets/location_picker.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = GoRouterState.of(context).extra as DriverEntity?;

    return BlocProvider(
      create: (context) {
        final bloc = OrderBloc(
          walletService: context.read<WalletService>(),
          nodeClient:    context.read<NodeClient>(),
        );
        if (driver != null) {
          bloc.add(OrderDriverSelected(driver));
        }
        return bloc;
      },
      child: const _OrderView(),
    );
  }
}

class _OrderView extends StatelessWidget {
  const _OrderView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderSuccess) {
          context.go('/home/trip/${state.order.orderId}');
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:         Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pesan Ojek'),
          ),
          body: switch (state) {
            OrderInitial() => const Center(
                child: Text('Pilih pengemudi dari halaman utama'),
              ),
            OrderLocationPicking() => LocationPicker(
                driver: state.driver,
                onLocationConfirmed: (
                  pickupLat, pickupLng,
                  dropoffLat, dropoffLng,
                  pickupLabel, dropoffLabel,
                ) {
                  context.read<OrderBloc>().add(
                    OrderLocationSet(
                      pickupLat:    pickupLat,
                      pickupLng:    pickupLng,
                      dropoffLat:   dropoffLat,
                      dropoffLng:   dropoffLng,
                      pickupLabel:  pickupLabel,
                      dropoffLabel: dropoffLabel,
                    ),
                  );
                },
              ),
            OrderFareLoading() => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Menghitung estimasi tarif...'),
                  ],
                ),
              ),
            OrderFareLoaded() => FareSummarySheet(state: state),
            OrderSubmitting() => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mengunci escrow di blockchain...'),
                  ],
                ),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

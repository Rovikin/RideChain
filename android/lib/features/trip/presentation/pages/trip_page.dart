import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/wallet/wallet_service.dart';
import '../../domain/entities/trip_entity.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import '../widgets/trip_map_view.dart';
import '../widgets/trip_action_panel.dart';
import '../widgets/trip_status_banner.dart';

class TripPage extends StatelessWidget {
  final String sessionId;
  const TripPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripBloc(
        walletService: context.read<WalletService>(),
      )..add(TripLoadRequested(sessionId)),
      child: _TripView(sessionId: sessionId),
    );
  }
}

class _TripView extends StatelessWidget {
  final String sessionId;
  const _TripView({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripBlocState>(
      listener: (context, state) {
        if (state is TripCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perjalanan selesai')),
          );
        } else if (state is TripError) {
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
          body: switch (state) {
            TripInitial() || TripLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            TripLoaded(trip: final trip) => _TripBody(
                trip:      trip,
                sessionId: sessionId,
              ),
            TripActionLoading(trip: final trip) => _TripBody(
                trip:        trip,
                sessionId:   sessionId,
                isLoading:   true,
              ),
            TripCompleted(trip: final trip) => _TripBody(
                trip:      trip,
                sessionId: sessionId,
              ),
            TripError(trip: final trip) when trip != null => _TripBody(
                trip:      trip!,
                sessionId: sessionId,
              ),
            _ => const Center(child: Text('Terjadi kesalahan')),
          },
        );
      },
    );
  }
}

class _TripBody extends StatelessWidget {
  final TripEntity trip;
  final String     sessionId;
  final bool       isLoading;

  const _TripBody({
    required this.trip,
    required this.sessionId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // map
        TripMapView(trip: trip),

        // status banner at top
        Positioned(
          top:   0,
          left:  0,
          right: 0,
          child: TripStatusBanner(trip: trip),
        ),

        // action panel at bottom
        Positioned(
          bottom: 0,
          left:   0,
          right:  0,
          child:  TripActionPanel(
            trip:      trip,
            sessionId: sessionId,
            isLoading: isLoading,
          ),
        ),

        // panic button — always visible during active trip
        if (trip.isActive)
          Positioned(
            right:  16,
            bottom: 220,
            child:  _PanicButton(sessionId: sessionId),
          ),
      ],
    );
  }
}

class _PanicButton extends StatelessWidget {
  final String sessionId;
  const _PanicButton({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Aktifkan Tombol Darurat?'),
            content: const Text(
              'Lokasi Anda akan dikirim ke kontak darurat dan '
              'dicatat permanen di blockchain. '
              'Tindakan ini tidak dapat dibatalkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<TripBloc>().add(
                    TripPanicActivated(sessionId, 'location_hash'),
                  );
                },
                child: const Text(
                  'Aktifkan SOS',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width:      56,
        height:     56,
        decoration: BoxDecoration(
          color:       Colors.red,
          shape:       BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:       Colors.red.withOpacity(0.4),
              blurRadius:  12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.sos, color: Colors.white, size: 28),
      ),
    );
  }
}

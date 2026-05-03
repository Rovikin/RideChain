import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/create_wallet_page.dart';
import 'features/auth/presentation/pages/import_wallet_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/order/presentation/pages/order_page.dart';
import 'features/trip/presentation/pages/trip_page.dart';
import 'features/dispute/presentation/pages/dispute_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isAuth    = authState is AuthAuthenticated;
    final isOnboard = state.matchedLocation.startsWith('/onboarding') ||
                      state.matchedLocation.startsWith('/wallet');

    if (!isAuth && !isOnboard) return '/onboarding';
    if (isAuth && isOnboard)   return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/wallet/create',
      builder: (context, state) => const CreateWalletPage(),
    ),
    GoRoute(
      path: '/wallet/import',
      builder: (context, state) => const ImportWalletPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'order',
          builder: (context, state) => const OrderPage(),
        ),
        GoRoute(
          path: 'trip/:sessionId',
          builder: (context, state) => TripPage(
            sessionId: state.pathParameters['sessionId']!,
          ),
        ),
        GoRoute(
          path: 'dispute/:sessionId',
          builder: (context, state) => DisputePage(
            sessionId: state.pathParameters['sessionId']!,
          ),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

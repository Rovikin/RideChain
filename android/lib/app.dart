import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/wallet/wallet_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'shared/theme/app_theme.dart';
import 'router.dart';

class RideChainApp extends StatelessWidget {
  const RideChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        walletService: context.read<WalletService>(),
      )..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title:        'RideChain',
        theme:        AppTheme.light,
        darkTheme:    AppTheme.dark,
        themeMode:    ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

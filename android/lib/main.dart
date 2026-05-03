import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/wallet/wallet_service.dart';
import 'core/network/node_client.dart';
import 'core/storage/secure_storage.dart';
import 'shared/theme/app_theme.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // initialize core services
  final secureStorage = SecureStorage();
  final walletService = WalletService(secureStorage);
  final nodeClient    = NodeClient();

  await walletService.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: walletService),
        RepositoryProvider.value(value: nodeClient),
        RepositoryProvider.value(value: secureStorage),
      ],
      child: const RideChainApp(),
    ),
  );
}

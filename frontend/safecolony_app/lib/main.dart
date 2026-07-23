import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';


import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.initialize();

  runApp(
    const ProviderScope(
      child: SafeColonyApp(),
    ),
  );
}

class SafeColonyApp extends StatelessWidget {
  const SafeColonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'SafeColony AI',
  theme: AppTheme.lightTheme,
  home: const SplashScreen(),
);
  }
}
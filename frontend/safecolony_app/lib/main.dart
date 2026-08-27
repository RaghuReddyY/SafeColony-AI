import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before using Firebase services
  await Firebase.initializeApp();

  // Initialize API client
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
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
      home: const LoginScreen(),
    );
  }
}
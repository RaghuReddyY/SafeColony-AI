import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';

import 'routes/app_router.dart';

import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/visitors/screens/add_visitor_screen.dart';
import 'features/visitors/screens/visitor_list_screen.dart';
import 'features/guard/screens/guard_dashboard_screen.dart';

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
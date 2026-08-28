import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before using Firebase services
  await Firebase.initializeApp();

  // Initialize API client
  ApiClient.initialize();

  // Load the previously selected application language
  await AppLocaleController.instance.load();

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
    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SafeColony AI',

          theme: AppTheme.lightTheme,

          // Current SafeColony application locale
          locale: AppLocaleController.instance.locale,

          // Locales supported by SafeColony
          supportedLocales:
              SafeColonyLocalizations.supportedLocales,

          // SafeColony custom translations + Flutter's
          // built-in Material/Widgets/Cupertino translations.
          localizationsDelegates: const [
            SafeColonyLocalizationsDelegate(),

            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const SplashScreen(),
        );
      },
    );
  }
}
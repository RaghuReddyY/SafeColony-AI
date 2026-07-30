import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../../routes/role_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ref.read(authProvider.notifier).checkLogin();

    if (!mounted) return;

    final auth = ref.read(authProvider);

    if (!auth.isLoggedIn || auth.user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoleRouter.getHomeScreen(
          role: auth.user!.role,
          residentStatus: auth.residentStatus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff0F172A),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
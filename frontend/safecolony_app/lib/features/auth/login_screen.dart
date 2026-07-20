import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();


  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }



  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

       try {
      final success = await ref.read(authProvider.notifier).login(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);

if (!success) {
  if (!mounted) return;

  final error = ref.read(authProvider).error ?? "Login failed";

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Text(error),
    ),
  );

  return;
}

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

  }

@override
Widget build(BuildContext context) {
  final authState = ref.watch(authProvider);

  final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/login_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: .70),
                    Colors.black.withValues(alpha: .35),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              if (width > 1000)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "SafeColony AI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Smarter Communities.\nSafer Together.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: Center(
                  child: GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield,
                            size: 70,
                            color: Colors.white,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 40),

                          AppTextField(
                            controller: _emailController,
                            hint: "Email",
                            icon: Icons.email,
                          ),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return "Password is required";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Password",
                              prefixIcon:
                                  const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
  width: double.infinity,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      authState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : PrimaryButton(
              title: "LOGIN",
              onPressed: _login,
            ),

      const SizedBox(height: 20),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account?",
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                ),
              );
            },
            child: const Text("Create Account"),
          ),
        ],
      ),
    ],
  ),
),

                        
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
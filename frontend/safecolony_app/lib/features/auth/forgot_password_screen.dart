import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import 'providers/auth_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _submitted = false;
  String? _devToken;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _show('Enter a valid email address.');
      return;
    }
    final token = await ref.read(authProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      _show(error);
      return;
    }
    setState(() {
      _submitted = true;
      _devToken = token;
    });
    if (token != null) {
      _show('Development reset token received.');
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 500,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Reset your password', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Enter your registered email. If the account exists, SafeColony will send a one-time reset code.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    title: loading ? 'SENDING...' : 'SEND RESET CODE',
                    onPressed: loading ? () {} : _submit,
                  ),
                  if (_submitted) ...[
                    const SizedBox(height: 16),
                    const Text('Check your email for the one-time reset code. The code expires automatically.', style: TextStyle(color: Colors.white70)),
                    if (_devToken != null) ...[
                      const SizedBox(height: 10),
                      SelectableText('Development token: $_devToken', style: const TextStyle(color: Colors.white)),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: _email.text.trim(), initialToken: _devToken))),
                      child: const Text('I have the reset code'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

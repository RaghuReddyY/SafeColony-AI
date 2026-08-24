import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import 'providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String? initialToken;
  const ResetPasswordScreen({super.key, required this.email, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _email;
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
    _token = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_token.text.trim().length < 16) { _show('Enter the reset code from your email.'); return; }
    if (_password.text.length < 8 || !RegExp(r'[A-Z]').hasMatch(_password.text) || !RegExp(r'[a-z]').hasMatch(_password.text) || !RegExp(r'\d').hasMatch(_password.text)) { _show('Password needs 8+ characters with uppercase, lowercase and a number.'); return; }
    if (_password.text != _confirm.text) { _show('Passwords do not match.'); return; }
    final ok = await ref.read(authProvider.notifier).resetPassword(email: _email.text.trim(), token: _token.text.trim(), newPassword: _password.text);
    if (!mounted) return;
    if (!ok) { _show(ref.read(authProvider).error ?? 'Unable to reset password.'); return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully. Please log in.')));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 500,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.password, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Create a new password', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(controller: _email, readOnly: true, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _token, decoration: const InputDecoration(labelText: 'Reset code', prefixIcon: Icon(Icons.key), border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _password, obscureText: _obscure, decoration: InputDecoration(labelText: 'New password', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())),
                  const SizedBox(height: 14),
                  TextField(controller: _confirm, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
                  const SizedBox(height: 18),
                  PrimaryButton(title: loading ? 'RESETTING...' : 'RESET PASSWORD', onPressed: loading ? () {} : _reset),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../routes/role_router.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';
import 'organization_registration_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _useOtp = false;
  bool _otpSent = false;
  bool _rememberMe = true;

  bool _showResendVerification = false;
  bool _resendVerificationInProgress = false;

  DateTime? _verificationResendAvailableAt;
  Timer? _verificationResendTimer;

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  Future<void> _passwordLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide the resend section while starting a new login attempt.
    setState(() {
      _showResendVerification = false;
    });

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).error ?? 'Login failed';

      debugPrint('SafeColony LOGIN ERROR: $error');

      final normalizedError = error.toLowerCase();

      /*
       * Do NOT depend on one exact backend error message.
       *
       * Different FastAPI/http exception paths can produce messages such as:
       *
       *   Email not verified
       *   Email is not verified
       *   Email address is not verified
       *   Please verify your email
       *   Please verify your email address
       *   email verification required
       *
       * The resend option should be available for all of these.
       */
      final emailVerificationRequired =
          normalizedError.contains('not verified') ||
          normalizedError.contains('unverified') ||
          normalizedError.contains('verify your email') ||
          normalizedError.contains('email verification') ||
          normalizedError.contains('email is not verified') ||
          normalizedError.contains('email address is not verified') ||
          normalizedError.contains('verification required') ||
          normalizedError.contains('verification link');

      setState(() {
        _showResendVerification = emailVerificationRequired;
      });

      _showError(error);
      return;
    }

    setState(() {
      _showResendVerification = false;
    });

    _goHome();
  }

  // ============================================================
  // RESEND EMAIL VERIFICATION
  // ============================================================

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError(
        'Enter your registered email address first.',
      );
      return;
    }

    final now = DateTime.now();

    if (_verificationResendAvailableAt != null &&
        now.isBefore(_verificationResendAvailableAt!)) {
      final seconds = _verificationResendAvailableAt!
          .difference(now)
          .inSeconds
          .clamp(1, 60);

      _showError(
        'Please wait $seconds seconds before requesting another email.',
      );
      return;
    }

    setState(() {
      _resendVerificationInProgress = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .resendEmailVerification(email);

    if (!mounted) return;

    setState(() {
      _resendVerificationInProgress = false;
    });

    if (!success) {
      _showError(
        ref.read(authProvider).error ??
            'Unable to resend the verification email. Please try again.',
      );
      return;
    }

    // Allow another request after 60 seconds.
    setState(() {
      _verificationResendAvailableAt =
          DateTime.now().add(const Duration(seconds: 60));
    });

    _verificationResendTimer?.cancel();

    _verificationResendTimer = Timer(
      const Duration(seconds: 60),
      () {
        if (!mounted) return;

        setState(() {
          _verificationResendAvailableAt = null;
        });
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification email sent. Please check your inbox and spam folder.',
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST OTP
  // ============================================================

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.length < 10) {
      _showError('Enter a valid mobile number.');
      return;
    }

    final devOtp =
        await ref.read(authProvider.notifier).requestOtp(phone);

    if (!mounted) return;

    final error = ref.read(authProvider).error;

    if (error != null) {
      _showError(error);
      return;
    }

    setState(() {
      _otpSent = true;
    });

    if (devOtp != null) {
      _otpController.text = devOtp;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Development OTP: $devOtp',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OTP sent to your mobile number.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      _showError('Enter the OTP.');
      return;
    }

    final success =
        await ref.read(authProvider.notifier).loginWithOtp(
              phone: _phoneController.text.trim(),
              otp: otp,
            );

    if (!mounted) return;

    if (!success) {
      _showError(
        ref.read(authProvider).error ?? 'OTP login failed',
      );
      return;
    }

    _goHome();
  }

  // ============================================================
  // NAVIGATE TO ROLE DASHBOARD
  // ============================================================

  void _goHome() {
    final auth = ref.read(authProvider);

    if (auth.user == null) {
      _showError(
        'Unable to load user information.',
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoleRouter.getHomeScreen(
          role: auth.user!.role,
          residentStatus: auth.residentStatus,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // ------------------------------------------------------
          // BACKGROUND
          // ------------------------------------------------------

          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
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

          // ------------------------------------------------------
          // LOGIN CONTENT
          // ------------------------------------------------------

          Row(
            children: [
              // --------------------------------------------------
              // LEFT BRANDING
              // --------------------------------------------------

              if (width > 1000)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 80,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SafeColony AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Smarter Communities.\nSafer Together.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --------------------------------------------------
              // LOGIN CARD
              // --------------------------------------------------

              Expanded(
                child: Center(
                  child: GlassCard(
                    child: SingleChildScrollView(
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
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ------------------------------------------------
                            // LOGIN MODE
                            // ------------------------------------------------

                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text(
                                    'Email + Password',
                                  ),
                                  icon: Icon(
                                    Icons.email_outlined,
                                  ),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text(
                                    'Mobile OTP',
                                  ),
                                  icon: Icon(
                                    Icons.sms_outlined,
                                  ),
                                ),
                              ],
                              selected: {
                                _useOtp,
                              },
                              onSelectionChanged: (value) {
                                setState(() {
                                  _useOtp = value.first;
                                  _otpSent = false;
                                  _otpController.clear();
                                  _showResendVerification = false;
                                });
                              },
                            ),

                            const SizedBox(height: 22),

                            // ==================================================
                            // EMAIL LOGIN
                            // ==================================================

                            if (!_useOtp) ...[
                              AppTextField(
                                controller:
                                    _emailController,
                                hint: 'Email',
                                icon: Icons.email,
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller:
                                    _passwordController,
                                obscureText:
                                    _obscurePassword,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Password is required';
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock),
                                  suffixIcon:
                                      IconButton(
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

                              CheckboxListTile(
                                value: _rememberMe,
                                onChanged: authState.isLoading
                                    ? null
                                    : (value) => setState(
                                          () => _rememberMe = value ?? true,
                                        ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text(
                                  'Remember me',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Keep me signed in on this device',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),

                              const SizedBox(height: 8),

                              _button(
                                authState.isLoading,
                                'LOGIN',
                                _passwordLogin,
                              ),

                              Align(
                                alignment:
                                    Alignment.centerRight,
                                child: TextButton(
                                  onPressed:
                                      authState.isLoading
                                          ? null
                                          : () =>
                                              Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          ),
                                  child:
                                      const Text(
                                    'Forgot Password?',
                                  ),
                                ),
                              ),

                              // ==================================================
                              // EMAIL VERIFICATION / RESEND
                              // ==================================================

                              if (_showResendVerification) ...[
                                const SizedBox(height: 4),

                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(12),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.10),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Your email address is not verified.',
                                        textAlign:
                                            TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      const Text(
                                        'Check your inbox or request a new verification link.',
                                        textAlign:
                                            TextAlign.center,
                                        style: TextStyle(
                                          color:
                                              Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      TextButton.icon(
                                        onPressed:
                                            authState.isLoading ||
                                                    _resendVerificationInProgress
                                                ? null
                                                : _resendVerificationEmail,
                                        icon:
                                            _resendVerificationInProgress
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth:
                                                          2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .mark_email_read_outlined,
                                                  ),
                                        label: Text(
                                          _verificationResendAvailableAt !=
                                                      null &&
                                                  DateTime.now()
                                                      .isBefore(
                                                    _verificationResendAvailableAt!,
                                                  )
                                              ? 'Verification email sent'
                                              : 'Resend Verification Link',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ]

                            // ==================================================
                            // MOBILE OTP LOGIN
                            // ==================================================

                            else ...[
                              AppTextField(
                                controller:
                                    _phoneController,
                                hint: 'Mobile Number',
                                icon: Icons.phone,
                              ),

                              const SizedBox(height: 14),

                              if (_otpSent)
                                TextFormField(
                                  controller:
                                      _otpController,
                                  keyboardType:
                                      TextInputType.number,
                                  maxLength: 6,
                                  decoration:
                                      const InputDecoration(
                                    hintText:
                                        'Enter OTP',
                                    prefixIcon:
                                        Icon(
                                      Icons.password,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              _button(
                                authState.isLoading,
                                _otpSent
                                    ? 'VERIFY OTP'
                                    : 'SEND OTP',
                                _otpSent
                                    ? _verifyOtp
                                    : _requestOtp,
                              ),

                              if (_otpSent)
                                TextButton(
                                  onPressed:
                                      authState.isLoading
                                          ? null
                                          : _requestOtp,
                                  child:
                                      const Text(
                                    'Resend OTP',
                                  ),
                                ),
                            ],

                            // --------------------------------------------------
                            // REGISTRATION
                            // --------------------------------------------------

                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              child: Divider(
                                color: Colors.white24,
                              ),
                            ),

                            const Text(
                              'New Community?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OrganizationRegistrationScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Register Organization',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Already have an Organization Code?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Join Existing Community',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _button(
    bool loading,
    String title,
    Future<void> Function() onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : PrimaryButton(
              title: title,
              onPressed: () {
                onPressed();
              },
            ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _verificationResendTimer?.cancel();

    super.dispose();
  }
}
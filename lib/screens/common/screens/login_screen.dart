import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vvs_app/screens/common/controllers/auth_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui_components.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.put(AuthController());

  // UI state
  bool _acceptedTerms = false;
  bool _obscure = true;

  // Safe validation state (do NOT call validate() in build)
  bool _isFormValid = false;
  late final VoidCallback _emailListener;
  late final VoidCallback _passListener;

  // Replace with your real URLs
  static const String _termsUrl = 'https://www.varshneyvikassangathan.com/';
  static const String _privacyUrl = 'https://www.varshneyvikassangathan.com/';

  // Validators
  String? _loginIdValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter Login ID';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter Password';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailListener = _scheduleValidate;
    _passListener = _scheduleValidate;
    _authController.emailController.addListener(_emailListener);
    _authController.passwordController.addListener(_passListener);
    // First validation after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleValidate());
  }

  @override
  void dispose() {
    _authController.emailController.removeListener(_emailListener);
    _authController.passwordController.removeListener(_passListener);
    super.dispose();
  }

  void _scheduleValidate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ok = _formKey.currentState?.validate() ?? false;
      if (ok != _isFormValid) {
        setState(() => _isFormValid = ok);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background
          Positioned.fill(child: CustomPaint(painter: _SoftBackdropPainter())),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.25),
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const AppTitle('Welcome to VVS'),
                              const SizedBox(height: 6),
                              const AppSubTitle('संस्कार • एकता • जनसेवा'),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Login ID
                          AppInput(
                            controller: _authController.emailController,
                            label: 'Username / Phone Number',
                            hint: 'Enter your registered email or phone',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: _loginIdValidator,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                          const SizedBox(height: 14),

                          // Password (with visibility toggle)
                          AppInput(
                            controller: _authController.passwordController,
                            label: 'Password',
                            obscureText: _obscure,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                            validator: _passwordValidator,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _tryLogin(),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordSheet,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Terms & Conditions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox.adaptive(
                                value: _acceptedTerms,
                                onChanged: (v) =>
                                    setState(() => _acceptedTerms = v ?? false),
                                activeColor: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    const Text(
                                      'I agree to the ',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _launchUrl(Uri.parse(_termsUrl)),
                                      child: const Text(
                                        'Terms & Conditions',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      ' and ',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _launchUrl(Uri.parse(_privacyUrl)),
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '.',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Login Button
                          // (Enable as soon as T&Cs are accepted; we validate on press.)
                          Obx(() {
                            final loading = _authController.isLoading.value;
                            final disabled = loading || !_acceptedTerms;

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: disabled ? 0.6 : 1,
                              child: AbsorbPointer(
                                absorbing: disabled,
                                child: AppButton(
                                  text: loading ? 'Please wait…' : 'LOGIN',
                                  onPressed: _tryLogin,
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const AppLabel('New User?'),
                              AppTextButton(
                                text: 'CREATE NEW ACCOUNT',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay (smooth, non-blocky)
          Obx(() {
            if (!_authController.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /* ===================== Forgot Password Bottom Sheet ===================== */

  void _showForgotPasswordSheet() {
    final prefill = _authController.emailController.text.trim();
    final emailCtrl = TextEditingController(
      text: prefill.contains('@') ? prefill : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email to receive a password reset link.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                onSubmitted: (_) => _sendReset(ctx, emailCtrl.text.trim()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send reset link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _sendReset(ctx, emailCtrl.text.trim()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReset(BuildContext ctx, String email) async {
    if (!_isValidEmail(email)) {
      _toast(context, 'Please enter a valid email address.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        Navigator.pop(ctx);
        _toast(context, 'Reset link sent to $email');
      }
    } catch (e) {
      _toast(context, 'Could not send reset link. Please try again.');
    }
  }

  /* ============================= Helpers ============================= */

  Future<void> _tryLogin() async {
    HapticFeedback.selectionClick();

    if (!_acceptedTerms) {
      _toast(context, 'Please accept the Terms & Conditions first.');
      return;
    }

    // Validate fields (safe to do on press)
    if (!(_formKey.currentState?.validate() ?? false)) {
      _scheduleValidate(); // show validation errors after frame
      return;
    }

    // Resolve email from login ID (email OR phone)
    final rawLoginId = _authController.emailController.text.trim();
    final resolvedEmail = await _resolveEmailFromLoginId(rawLoginId);

    if (resolvedEmail == null) {
      _toast(context, 'We could not find an account for that ID.');
      return;
    }

    // Update controller text so AuthController.login() uses the resolved email
    if (resolvedEmail != rawLoginId) {
      _authController.emailController.text = resolvedEmail;
    }

    await _authController.login();
  }

  /// If the user enters an email, returns it.
  /// If the user enters a 10-digit phone, we look up the user's email in Firestore.
  /// Otherwise returns null.
  Future<String?> _resolveEmailFromLoginId(String loginId) async {
    final id = loginId.trim();
    if (id.isEmpty) return null;

    if (id.contains('@')) return id; // already an email

    // Try phone (10 digits)
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      try {
        final qs = await FirebaseFirestore.instance
            .collection('users')
            .where('mobile', isEqualTo: digits)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) {
          final data = qs.docs.first.data();
          final email = (data['email'] ?? '').toString().trim();
          if (email.isNotEmpty) return email;
        }
      } catch (_) {
        // swallow and fall through to null
      }
    }

    return null;
  }

  static bool _isValidEmail(String v) =>
      v.isNotEmpty && v.contains('@') && v.contains('.');

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _launchUrl(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast(context, 'Unable to open link');
    } catch (_) {
      _toast(context, 'Unable to open link');
    }
  }
}

/* ========================== Background Painter ========================== */

class _SoftBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient fill
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x0AFFFFFF), Color(0x00000000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Soft circles (blur-like bokeh)
    void blob(Offset c, double r, Color color) {
      final p = Paint()..color = color;
      canvas.drawCircle(c, r, p);
    }

    blob(
      Offset(size.width * 0.15, size.height * 0.18),
      80,
      AppColors.primary.withOpacity(0.10),
    );
    blob(
      Offset(size.width * 0.85, size.height * 0.12),
      60,
      AppColors.primary.withOpacity(0.08),
    );
    blob(
      Offset(size.width * 0.8, size.height * 0.85),
      100,
      AppColors.primary.withOpacity(0.06),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

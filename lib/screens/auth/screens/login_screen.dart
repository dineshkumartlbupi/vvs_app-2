import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vvs_app/screens/auth/controllers/auth_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui_components.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.put(AuthController());

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI state
  bool _acceptedTerms = false;
  bool _obscure = true;
  bool _rememberMe = false;

  // Replace with your real URLs
  static const String _termsUrl = 'https://www.varshneyvikassangathan.com/';
  static const String _privacyUrl = 'https://www.varshneyvikassangathan.com/';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Validators
  String? _loginIdValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter your email or mobile number';
    }
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background
          Positioned.fill(
            child: CustomPaint(painter: _EnhancedBackdropPainter()),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 40,
                  vertical: 20,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Card(
                        elevation: 12,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: AppColors.border.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo and Header
                                _buildHeader(),

                                const SizedBox(height: 32),

                                // Login ID Input
                                _buildLoginIdInput(),

                                const SizedBox(height: 20),

                                // Password Input
                                _buildPasswordInput(),

                                const SizedBox(height: 12),

                                // Forgot Password & Remember Me
                                _buildForgotPasswordRow(),

                                const SizedBox(height: 24),

                                // Terms & Conditions
                                _buildTermsCheckbox(),

                                const SizedBox(height: 24),

                                // Login Button
                                _buildLoginButton(),

                                const SizedBox(height: 20),

                                // Divider
                                _buildDivider(),

                                const SizedBox(height: 20),

                                // Register Link
                                _buildRegisterLink(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          Obx(() {
            if (!_authController.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Signing you in...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
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

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with enhanced animation
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue to Varshney Samaj',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginIdInput() {
    return AppInput(
      controller: _authController.emailController,
      label: 'Email or Mobile Number',
      hint: 'Enter registered email or 10-digit mobile',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.person_outline_rounded,
      validator: _loginIdValidator,
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
    );
  }

  Widget _buildPasswordInput() {
    return AppInput(
      controller: _authController.passwordController,
      label: 'Password',
      hint: 'Enter your password',
      obscureText: _obscure,
      prefixIcon: Icons.lock_outline_rounded,
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: AppColors.subtitle,
        ),
      ),
      validator: _passwordValidator,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _tryLogin(),
    );
  }

  Widget _buildForgotPasswordRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Remember me',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Forgot Password
        TextButton(
          onPressed: _showForgotPasswordSheet,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'I agree to the ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(Uri.parse(_termsUrl)),
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                ' and ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(Uri.parse(_privacyUrl)),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Obx(() {
      final loading = _authController.isLoading.value;
      final disabled = loading || !_acceptedTerms;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : _tryLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled ? AppColors.border : Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            loading ? 'SIGNING IN...' : 'SIGN IN',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border.withOpacity(0.5),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            fontSize: 15,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RegisterScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ===================== Forgot Password Bottom Sheet ===================== */

  void _showForgotPasswordSheet() {
    HapticFeedback.mediumImpact();
    final prefill = _authController.emailController.text.trim();
    final emailCtrl = TextEditingController(
      text: prefill.contains('@') ? prefill : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your registered email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              AppInput(
                controller: emailCtrl,
                label: 'Email Address',
                hint: 'Enter your registered email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _sendReset(ctx, emailCtrl.text.trim()),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReset(BuildContext ctx, String email) async {
    if (!_isValidEmail(email)) {
      _showSnackbar(
        'Invalid Email',
        'Please enter a valid email address.',
        isError: true,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        Navigator.pop(ctx);
        _showSnackbar(
          'Email Sent',
          'Password reset link has been sent to $email',
          isError: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Could not send reset link. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email address.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }
      _showSnackbar('Error', message, isError: true);
    } catch (e) {
      _showSnackbar(
        'Error',
        'Something went wrong. Please try again.',
        isError: true,
      );
    }
  }

  /* ============================= Helpers ============================= */

  Future<void> _tryLogin() async {
    HapticFeedback.mediumImpact();

    if (!_acceptedTerms) {
      _showSnackbar(
        'Terms Required',
        'Please accept the Terms & Conditions to continue.',
        isError: true,
      );
      return;
    }

    // Validate fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Resolve email from login ID (email OR phone)
    final rawLoginId = _authController.emailController.text.trim();
    final resolvedEmail = await _resolveEmailFromLoginId(rawLoginId);

    if (resolvedEmail == null) {
      _showSnackbar(
        'Account Not Found',
        'We could not find an account with this email or mobile number.',
        isError: true,
      );
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
    final id = loginId.trim().toLowerCase();
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

  void _showSnackbar(String title, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _launchUrl(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnackbar(
          'Error',
          'Unable to open link',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackbar(
        'Error',
        'Unable to open link',
        isError: true,
      );
    }
  }
}

/* ========================== Enhanced Background Painter ========================== */

class _EnhancedBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final rect = Offset.zero & size;
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.background,
          AppColors.background.withOpacity(0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, gradient);

    // Decorative circles with blur effect
    void drawCircle(Offset center, double radius, Color color) {
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(center, radius, paint);
    }

    // Top left
    drawCircle(
      Offset(size.width * 0.1, size.height * 0.15),
      100,
      AppColors.primary.withOpacity(0.12),
    );

    // Top right
    drawCircle(
      Offset(size.width * 0.9, size.height * 0.1),
      80,
      AppColors.accent.withOpacity(0.1),
    );

    // Bottom left
    drawCircle(
      Offset(size.width * 0.15, size.height * 0.9),
      70,
      AppColors.primary.withOpacity(0.08),
    );

    // Bottom right
    drawCircle(
      Offset(size.width * 0.85, size.height * 0.85),
      120,
      AppColors.accent.withOpacity(0.06),
    );

    // Center decoration
    drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      150,
      AppColors.gold.withOpacity(0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vvs_app/screens/common/screens/login_screen.dart';
import 'package:vvs_app/widgets/app_dropdown.dart';
import 'package:vvs_app/widgets/bottom_footer.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui_components.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  // Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _fatherHusbandNameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _professionController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dropdowns
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedBloodGroup;

  final List<String> _genderOptions = const ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = const [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];
  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // UI state
  bool _loading = false;
  bool _obscure = true;
  double _pwdScore = 0.0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _fatherHusbandNameController.dispose();
    _occupationController.dispose();
    _qualificationController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _aadhaarNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /* ------------------------ Validators & helpers ------------------------ */

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Enter valid email';
  }

  String? _mobileValidator(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.length != 10) return 'Enter valid 10-digit mobile number';
    return null;
  }

  String? _aadhaarValidator(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.length != 12) return 'Enter valid 12-digit Aadhaar';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  void _onPasswordChanged(String v) {
    setState(() => _pwdScore = _passwordStrength(v));
  }

  double _passwordStrength(String v) {
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 6) score++;
    if (v.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
    return (score / 5).clamp(0, 1).toDouble();
  }

  Color _strengthColor(double s) {
    if (s < 0.34) return Colors.redAccent;
    if (s < 0.67) return Colors.orange;
    return Colors.green;
  }

  String _strengthLabel(double s) {
    if (s < 0.34) return 'Weak';
    if (s < 0.67) return 'Okay';
    return 'Strong';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    final first = DateTime(now.year - 110, 1, 1);
    final last = DateTime(now.year, now.month, now.day);

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select Date of Birth',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (d != null) {
      _dobController.text =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      setState(() {});
    }
  }

  /* ------------------------------- Submit ------------------------------- */

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userData = {
      'name':
          '${_firstNameController.text.trim()} ${_middleNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim(),
      'dob': _dobController.text.trim(),
      'fatherHusbandName': _fatherHusbandNameController.text.trim(),
      'gender': _selectedGender,
      'maritalStatus': _selectedMaritalStatus,
      'occupation': _occupationController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'profession': _professionController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _mobileController.text.replaceAll(RegExp(r'\D'), ''),
      'address': _addressController.text.trim(),
      'bloodGroup': _selectedBloodGroup,
      'aadhaarNumber': _aadhaarNumberController.text.replaceAll(
        RegExp(r'\D'),
        '',
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
    };

    setState(() => _loading = true);
    final error = await _auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      userData: userData,
    );
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful')));
      if (mounted) Navigator.pop(context);
    }
  }

  /* -------------------------------- UI -------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New User Registration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const AppTitle('Join the VVS Network', size: 20),
                    const SizedBox(height: 6),
                    const AppSubTitle(
                      'Connect with your Varshney Samaj. Strengthen Our Roots.',
                    ),
                    const SizedBox(height: 18),

                    // Basic Info
                    _SectionCard(
                      title: 'Basic Information',
                      children: [
                        AppInput(
                          controller: _firstNameController,
                          label: 'First Name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: _required, // Required
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _middleNameController,
                          label: 'Middle Name',
                          prefixIcon: Icons.person_outline,
                          // NOT required
                          validator: (_) => null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _lastNameController,
                          label: 'Last Name',
                          prefixIcon: Icons.person_outline,
                          // NOT required
                          validator: (_) => null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickDob,
                          child: AbsorbPointer(
                            child: AppInput(
                              controller: _dobController,
                              label: 'Date of Birth (dd/mm/yyyy)',
                              prefixIcon: Icons.cake_outlined,
                              validator: _required,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _fatherHusbandNameController,
                          label: 'Father / Husband Name',
                          prefixIcon: Icons.family_restroom_rounded,
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppDropdown(
                          label: 'Gender',
                          items: _genderOptions,
                          value: _selectedGender,
                          onChanged: (val) =>
                              setState(() => _selectedGender = val),
                          validator: (val) =>
                              (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppDropdown(
                          label: 'Marital Status',
                          items: _maritalStatusOptions,
                          value: _selectedMaritalStatus,
                          onChanged: (val) =>
                              setState(() => _selectedMaritalStatus = val),
                          validator: (val) =>
                              (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Contact
                    _SectionCard(
                      title: 'Contact',
                      children: [
                        AppInput(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          validator: _emailValidator,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _mobileController,
                          label: 'Mobile (10 digits)',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_iphone_rounded,
                          validator: _mobileValidator,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _addressController,
                          label: 'Address',
                          prefixIcon: Icons.location_on_outlined,
                          validator: _required,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Education & Work
                    _SectionCard(
                      title: 'Education & Work',
                      children: [
                        AppInput(
                          controller: _qualificationController,
                          label: 'Qualification',
                          prefixIcon: Icons.school_outlined,
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _professionController,
                          label: 'Profession',
                          prefixIcon: Icons.work_outline_rounded,
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _occupationController,
                          label: 'Occupation',
                          prefixIcon: Icons.badge_outlined,
                          validator: _required,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Identity
                    _SectionCard(
                      title: 'Identity',
                      children: [
                        AppDropdown(
                          label: 'Blood Group',
                          items: _bloodGroups,
                          value: _selectedBloodGroup,
                          onChanged: (val) =>
                              setState(() => _selectedBloodGroup = val),
                          validator: (val) =>
                              (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _aadhaarNumberController,
                          label: 'Aadhaar Number (12 digits)',
                          prefixIcon: Icons.perm_identity_rounded,
                          keyboardType: TextInputType.number,
                          validator: _aadhaarValidator,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Security
                    _SectionCard(
                      title: 'Security',
                      children: [
                        AppInput(
                          controller: _passwordController,
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
                          // onChanged: _onPasswordChanged,
                        ),
                        const SizedBox(height: 8),
                        _PasswordStrengthBar(score: _pwdScore),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Actions
                    _loading
                        ? const CircularProgressIndicator()
                        : AppButton(text: 'SUBMIT', onPressed: _submit),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLabel('Already have an account?'),
                        AppTextButton(
                          text: 'SIGN IN',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const BottomFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================ UI Helpers ============================ */

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double score;
  const _PasswordStrengthBar({required this.score});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    if (score < 0.34) {
      c = Colors.redAccent;
      label = 'Weak';
    } else if (score < 0.67) {
      c = Colors.orange;
      label = 'Okay';
    } else {
      c = Colors.green;
      label = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(c),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: $label',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

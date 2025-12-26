import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vvs_app/models/user_model.dart';
import 'package:vvs_app/screens/auth/screens/login_screen.dart';
import 'package:vvs_app/utils/indian_locations_data.dart';
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

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Basic Info Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _fatherHusbandNameController = TextEditingController();

  // Contact Controllers
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  // Address Controllers
  final _houseNumberController = TextEditingController();
  final _streetAreaController = TextEditingController();
  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  // Education & Work Controllers
  final _occupationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _professionController = TextEditingController();

  // Identity Controllers
  final _aadhaarNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdowns
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedBloodGroup;
  String? _selectedState;

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _pwdScore = 0.0;
  final int _currentStep = 0;
  final _scrollController = ScrollController();

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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    _passwordController.addListener(() {
      _onPasswordChanged(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _fatherHusbandNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _houseNumberController.dispose();
    _streetAreaController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _occupationController.dispose();
    _qualificationController.dispose();
    _professionController.dispose();
    _aadhaarNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /* ------------------------ Validators & helpers ------------------------ */

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Please enter a valid email address';
  }

  String? _mobileValidator(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.length != 10) return 'Please enter a valid 10-digit mobile number';
    return null;
  }

  String? _pinCodeValidator(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.length != 6) return 'Please enter a valid 6-digit PIN code';
    return null;
  }

  String? _aadhaarValidator(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.length != 12) return 'Please enter a valid 12-digit Aadhaar number';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
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

  Future<void> _pickDob() async {
    HapticFeedback.mediumImpact();
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
    HapticFeedback.mediumImpact();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackbar(
        'Incomplete Form',
        'Please fill all required fields correctly',
        isError: true,
      );
      return;
    }

    // Create user model
    final userModel = UserModel(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      dob: _dobController.text.trim(),
      fatherHusbandName: _fatherHusbandNameController.text.trim(),
      gender: _selectedGender!,
      maritalStatus: _selectedMaritalStatus!,
      occupation: _occupationController.text.trim(),
      qualification: _qualificationController.text.trim(),
      profession: _professionController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      mobile: _mobileController.text.replaceAll(RegExp(r'\D'), ''),
      houseNumber: _houseNumberController.text.trim(),
      streetArea: _streetAreaController.text.trim(),
      village: _villageController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      state: _selectedState!,
      pinCode: _pinCodeController.text.replaceAll(RegExp(r'\D'), ''),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      bloodGroup: _selectedBloodGroup!,
      aadhaarNumber:
          _aadhaarNumberController.text.replaceAll(RegExp(r'\D'), ''),
    );

    setState(() => _loading = true);

    final error = await _auth.register(
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
      userData: userModel.toMap(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackbar(
        'Registration Failed',
        error,
        isError: true,
      );
    } else {
      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                'Welcome to Varshney Samaj! Your account has been created successfully.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.subtitle,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Verification Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A verification email has been sent to ${_emailController.text.trim()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

  /* -------------------------------- UI -------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Decorative background
          Positioned.fill(
            child: CustomPaint(painter: _RegistrationBackdropPainter()),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 4),

                            // Header
                            _buildHeader(),

                            const SizedBox(height: 24),

                            // Progress Indicator
                            _buildProgressIndicator(),

                            const SizedBox(height: 20),

                            // Basic Info
                            _SectionCard(
                              title: 'Basic Information',
                              icon: Icons.person_outline_rounded,
                              children: [
                                AppInput(
                                        controller: _firstNameController,
                                        label: 'First Name',
                                        prefixIcon: Icons.person_outline_rounded,
                                        validator: _required,
                                        textInputAction: TextInputAction.next,
                                      ),
                                        const SizedBox(height: 12),
                                      AppInput(
                                        controller: _middleNameController,
                                        label: 'Middle Name',
                                        prefixIcon: Icons.person_outline,
                                        validator: (_) => null,
                                        textInputAction: TextInputAction.next,
                                      ),
                             
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _lastNameController,
                                  label: 'Last Name (Surname)',
                                  prefixIcon: Icons.person_outline,
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
                                  validator: (val) => (val == null || val.isEmpty)
                                      ? 'Please select gender'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                AppDropdown(
                                  label: 'Marital Status',
                                  items: _maritalStatusOptions,
                                  value: _selectedMaritalStatus,
                                  onChanged: (val) => setState(
                                      () => _selectedMaritalStatus = val),
                                  validator: (val) => (val == null || val.isEmpty)
                                      ? 'Please select marital status'
                                      : null,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Contact
                            _SectionCard(
                              title: 'Contact Information',
                              icon: Icons.contact_phone_outlined,
                              children: [
                                AppInput(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  validator: _emailValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _mobileController,
                                  label: 'Mobile Number (10 digits)',
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_iphone_rounded,
                                  validator: _mobileValidator,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Address Details
                            _SectionCard(
                              title: 'Address Details',
                              icon: Icons.location_on_outlined,
                              children: [
                           AppInput(
                                        controller: _houseNumberController,
                                        label: 'House/Flat No.',
                                        prefixIcon: Icons.home_outlined,
                                        validator: _required,
                                        textInputAction: TextInputAction.next,
                                      ),
                                         const SizedBox(height: 12),
                                AppInput(
                                        controller: _streetAreaController,
                                        label: 'Street/Area',
                                        prefixIcon: Icons.add_road_outlined,
                                        validator: _required,
                                        textInputAction: TextInputAction.next,
                                      ),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _villageController,
                                  label: 'Village/Town',
                                  prefixIcon: Icons.apartment_outlined,
                                  validator: _required,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                        controller: _cityController,
                                        label: 'City',
                                        prefixIcon: Icons.location_city_outlined,
                                        validator: _required,
                                        textInputAction: TextInputAction.next,
                                      ),
                                         const SizedBox(height: 12),
                                      AppInput(
                                        controller: _districtController,
                                        label: 'District',
                                        prefixIcon: Icons.map_outlined,
                                        validator: _required,
                                        textInputAction: TextInputAction.next,
                                      ),
                               
                                const SizedBox(height: 12),
                                AppDropdown(
                                  label: 'State',
                                  items: IndianLocationsData.states,
                                  value: _selectedState,
                                  onChanged: (val) => setState(() {
                                    _selectedState = val;
                                  }),
                                  validator: (val) => (val == null || val.isEmpty)
                                      ? 'Please select state'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                        controller: _pinCodeController,
                                        label: 'PIN Code',
                                        prefixIcon: Icons.pin_outlined,
                                        keyboardType: TextInputType.number,
                                        validator: _pinCodeValidator,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                      ),
                                         const SizedBox(height: 16),
                                      AppInput(
                                        controller: _landmarkController,
                                        label: 'Landmark (Optional)',
                                        prefixIcon: Icons.place_outlined,
                                        validator: (_) => null,
                                        textInputAction: TextInputAction.next,
                                      ),
                        
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Education & Work
                            _SectionCard(
                              title: 'Education & Work',
                              icon: Icons.school_outlined,
                              children: [
                                AppInput(
                                  controller: _qualificationController,
                                  label: 'Highest Qualification',
                                  prefixIcon: Icons.school_outlined,
                                  validator: _required,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _professionController,
                                  label: 'Profession/Field',
                                  prefixIcon: Icons.work_outline_rounded,
                                  validator: _required,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _occupationController,
                                  label: 'Current Occupation',
                                  prefixIcon: Icons.badge_outlined,
                                  validator: _required,
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Identity
                            _SectionCard(
                              title: 'Identity Information',
                              icon: Icons.perm_identity_rounded,
                              children: [
                                AppDropdown(
                                  label: 'Blood Group',
                                  items: _bloodGroups,
                                  value: _selectedBloodGroup,
                                  onChanged: (val) =>
                                      setState(() => _selectedBloodGroup = val),
                                  validator: (val) => (val == null || val.isEmpty)
                                      ? 'Please select blood group'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _aadhaarNumberController,
                                  label: 'Aadhaar Number (12 digits)',
                                  prefixIcon: Icons.perm_identity_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: _aadhaarValidator,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Security
                            _SectionCard(
                              title: 'Security',
                              icon: Icons.lock_outline_rounded,
                              children: [
                                AppInput(
                                  controller: _passwordController,
                                  label: 'Password',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                  validator: _passwordValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 8),
                                _PasswordStrengthBar(score: _pwdScore),
                                const SizedBox(height: 12),
                                AppInput(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  obscureText: _obscureConfirmPassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirmPassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                  validator: _confirmPasswordValidator,
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            _buildSubmitButton(),

                            const SizedBox(height: 16),

                            // Login Link
                            _buildLoginLink(),

                            const SizedBox(height: 8),
                            const BottomFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_loading)
            Positioned.fill(
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
                          'Creating your account...',
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
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join the Varshney One Network',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Connect with your Varshney Samaj. Strengthen Our Roots.',
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Please fill all sections carefully and accurately',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _loading
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: _loading
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
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading ? AppColors.border : Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _loading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: const Text(
              'Sign In',
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
}

/* ============================ UI Helpers ============================ */

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    IconData icon;
    if (score < 0.34) {
      c = Colors.redAccent;
      label = 'Weak';
      icon = Icons.error;
    } else if (score < 0.67) {
      c = Colors.orange;
      label = 'Okay';
      icon = Icons.warning;
    } else {
      c = Colors.green;
      label = 'Strong';
      icon = Icons.check_circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.border.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(c),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: c,
            ),
            const SizedBox(width: 4),
            Text(
              'Password strength: $label',
              style: TextStyle(
                fontSize: 12,
                color: c,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ========================== Background Painter ========================== */

class _RegistrationBackdropPainter extends CustomPainter {
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

    // Decorative circles
    void drawCircle(Offset center, double radius, Color color) {
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(center, radius, paint);
    }

    drawCircle(
      Offset(size.width * 0.1, size.height * 0.1),
      80,
      AppColors.primary.withOpacity(0.1),
    );

    drawCircle(
      Offset(size.width * 0.9, size.height * 0.15),
      60,
      AppColors.accent.withOpacity(0.08),
    );

    drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      70,
      AppColors.gold.withOpacity(0.06),
    );

    drawCircle(
      Offset(size.width * 0.85, size.height * 0.8),
      100,
      AppColors.primary.withOpacity(0.07),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

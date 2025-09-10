import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final _bloodGroupController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userData = {
      'name':
          _firstNameController.text.trim() +
          ' ' +
          _middleNameController.text.trim() +
          ' ' +
          _lastNameController.text.trim(),
      'dob': _dobController.text.trim(),
      'fatherHusbandName': _fatherHusbandNameController.text.trim(),
      'gender': _selectedGender,
      'maritalStatus': _selectedMaritalStatus,
      'occupation': _occupationController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'profession': _professionController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'address': _addressController.text.trim(),
      'bloodGroup': _bloodGroupController.text.trim(),
      'aadhaarNumber': _aadhaarNumberController.text.trim(),
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New User Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AppTitle('Join the VVS Network'),
              const SizedBox(height: 8),
              const AppSubTitle(
                'Connect with your Varshney Samaj. Strengthen Our Roots.',
              ),
              const SizedBox(height: 24),

              AppInput(
                controller: _firstNameController,
                label: 'First Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _middleNameController,
                label: 'Middle Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _lastNameController,
                label: 'Last Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _dobController,
                label: 'DOB (dd/mm/yyyy)',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _fatherHusbandNameController,
                label: 'Father / Husband Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              /// Gender Dropdown
              AppDropdown(
                label: 'Gender',
                items: _genderOptions,
                value: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              /// Marital Status Dropdown
              AppDropdown(
                label: 'Marital Status',
                items: _maritalStatusOptions,
                value: _selectedMaritalStatus,
                onChanged: (val) =>
                    setState(() => _selectedMaritalStatus = val),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              AppInput(
                controller: _occupationController,
                label: 'Occupation',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _qualificationController,
                label: 'Qualification',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _professionController,
                label: 'Profession',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _addressController,
                label: 'Address',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Enter valid email',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _mobileController,
                label: 'Mobile',
                keyboardType: TextInputType.phone,
                validator: (v) => v != null && v.length == 10
                    ? null
                    : 'Enter valid mobile number',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _bloodGroupController,
                label: 'Blood Group',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _aadhaarNumberController,
                label: 'Aadhaar Number',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Minimum 6 characters',
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : AppButton(text: 'SUBMIT', onPressed: _submit),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLabel('Already have an account?'),
                  AppTextButton(
                    text: 'SIGN IN',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
              const BottomFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

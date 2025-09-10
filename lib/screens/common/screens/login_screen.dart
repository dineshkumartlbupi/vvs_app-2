import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', width: 120, height: 120),
                  const SizedBox(height: 24),
                  const AppTitle('Welcome to VVS'),
                  const SizedBox(height: 8),
                  const AppSubTitle('संस्कार • एकता • सेवा'),
                  const SizedBox(height: 24),

                  // Login ID
                  AppInput(
                    controller: _authController.emailController,
                    label: 'Login ID',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter Login ID' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  AppInput(
                    controller: _authController.passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter Password' : null,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  Obx(
                    () => _authController.isLoading.value
                        ? const CircularProgressIndicator()
                        : AppButton(
                            text: 'LOGIN',
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                              await  _authController.login();
                              }
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLabel('New User?'),
                      AppTextButton(
                        text: 'CREATE NEW ACCOUNT',
                        onPressed: () {
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/auth/modals/auth_modal.dart';
import 'package:vvs_app/screens/dashboard_screen.dart';
import 'package:vvs_app/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final RxBool isLoading = false.obs;
  final RxString message = "".obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🔹 Login Function
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please enter both Login ID and Password",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authService.login(
        logindata: LoginRequest(email: email, password: password),
      );

      isLoading.value = false;

      if (response == null) {
        // ✅ Login success
        Get.offAll(() => const DashboardScreen());
        Get.snackbar("Success", "Login Successful",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else {
        Get.snackbar("Login Failed", response,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // 🔹 Register Function
  Future<void> register(Map<String, dynamic> userData) async {
    final email = userData['email']?.toString().trim() ?? '';
    final password = userData['password']?.toString().trim() ?? '';

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        userData: userData,
      );

      isLoading.value = false;

      if (response == null) {
        Get.offAll(() => const DashboardScreen());
        Get.snackbar("Success", "Registration Successful",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else {
        Get.snackbar("Registration Failed", response,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }
}

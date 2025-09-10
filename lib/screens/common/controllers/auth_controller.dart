import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/common/modals/auth_modal.dart';
import 'package:vvs_app/screens/dashboard_screen.dart';
import 'package:vvs_app/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final RxBool isLoading = false.obs;
  final RxString message = "".obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      //customWidget("type","message")
      Get.snackbar(
        "Error",
        "Please enter both Login ID and Password",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final LoginRequest logindata = LoginRequest(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _authService.login(logindata: logindata);

      isLoading.value = false;

      Get.snackbar(
        "Success",
        "Login Successful",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );

      Get.offAll(() => const DashboardScreen());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;

      String errorMessage;
      switch (e.code) {
        case "user-not-found":
          errorMessage = "No user found with this email.";
          break;
        case "wrong-password":
          errorMessage = "Incorrect password.";
          break;
        case "invalid-email":
          errorMessage = "Invalid email format.";
          break;
        case "user-disabled":
          errorMessage = "This account has been disabled.";
          break;
        default:
          errorMessage = "Login failed. Please try again.";
      }

      message.value = errorMessage;

      Get.snackbar(
        "Login Failed",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } catch (e) {
      
      isLoading.value = false;
      message.value = e.toString();

      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );

      print("Error from auth controller ${e.toString()}");
    }
  }
}

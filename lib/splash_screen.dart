import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vvs_app/screens/dashboard_screen.dart';
import 'package:vvs_app/screens/common/screens/login_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    Future.delayed(const Duration(seconds: 2), _checkAuthState);
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.png', width: 140, height: 140),
              const SizedBox(height: 32),
              const AppTitle('WELCOME TO VVS'),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: AppSubTitle('एकता • संस्कार • जन सेवा'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: AppSubTitle('(Unity • Values • Public Service)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

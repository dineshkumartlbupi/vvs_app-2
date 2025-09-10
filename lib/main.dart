import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/route_manager.dart';
import 'package:vvs_app/splash_screen.dart';
import 'package:vvs_app/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VVSApp());
}

class VVSApp extends StatelessWidget {
  const VVSApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VVS App',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

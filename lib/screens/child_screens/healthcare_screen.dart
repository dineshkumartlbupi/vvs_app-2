import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class HealthCareScreen extends StatelessWidget {
  const HealthCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Health Care')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppTitle('Health & Medical Support'),
            SizedBox(height: 16),
            Text(
              'The Varshney Vaishy Samaj Health Care initiative is dedicated to ensuring the well-being of our community members. '
              'We believe that a healthy community is a strong community.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Services We Support'),
            SizedBox(height: 8),
            Text(
              '• Blood donation assistance and urgent requirements\n'
              '• Connecting with verified doctors and hospitals\n'
              '• Health awareness programs and webinars\n'
              '• Emergency contact coordination\n'
              '• Support for medical aid and treatment information',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Be a Donor'),
            SizedBox(height: 8),
            Text(
              'If you’re willing to donate blood or volunteer in medical initiatives, register with us and become a health hero within Varshney One.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

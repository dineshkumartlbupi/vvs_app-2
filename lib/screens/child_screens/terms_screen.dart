import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2025',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitle.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to the Varshney Vaishy Samaj App. By accessing or using our mobile application, you agree to be bound by these Terms and Conditions.',
            ),
            _buildSection(
              '2. User Registration',
              'To access certain features of the App, you may be required to register for an account. You agree to provide accurate, current, and complete information during the registration process.',
            ),
            _buildSection(
              '3. Privacy Policy',
              'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and share your personal information.',
            ),
            _buildSection(
              '4. Community Guidelines',
              'Users must behave respectfully towards other members. Harassment, hate speech, or inappropriate content will not be tolerated and may result in account suspension.',
            ),
            _buildSection(
              '5. Intellectual Property',
              'All content included on the App, such as text, graphics, logos, images, and software, is the property of Varshney Vaishy Samaj or its content suppliers.',
            ),
            _buildSection(
              '6. Limitation of Liability',
              'In no event shall Varshney Vaishy Samaj be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the App.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2025 Varshney Vaishy Samaj. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.subtitle.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

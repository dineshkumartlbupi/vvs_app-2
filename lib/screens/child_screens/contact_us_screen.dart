import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We are here to help you. Reach out to us for any queries or support.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Contact Info Cards
            _buildContactCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email Us',
              content: 'support@vvsamaj.com',
              actionText: 'Send Email',
              onTap: () {
                // TODO: Implement email launch
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              icon: Icons.phone_rounded,
              title: 'Call Us',
              content: '+91 98765 43210',
              actionText: 'Call Now',
              onTap: () {
                // TODO: Implement phone launch
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context,
              icon: Icons.location_on_rounded,
              title: 'Visit Us',
              content: '123, Varshney Bhawan, Gandhi Nagar, Delhi - 110031',
              actionText: 'View on Map',
              onTap: () {
                // TODO: Implement map launch
                HapticFeedback.selectionClick();
              },
            ),

            const SizedBox(height: 40),
            const Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AppInput(
                    controller: TextEditingController(),
                    label: 'Your Name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: TextEditingController(),
                    label: 'Email Address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: TextEditingController(),
                    label: 'Message',
                    prefixIcon: Icons.message_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'SEND MESSAGE',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message sent successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

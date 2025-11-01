import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Education')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppTitle('Empowering Through Education'),
            SizedBox(height: 16),
            Text(
              'Education is the foundation of a progressive society. The Varshney Vaishy Samaj is committed '
              'to nurturing young minds and supporting lifelong learners across our community.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Our Initiatives'),
            SizedBox(height: 8),
            Text(
              '• Scholarships and financial aid for deserving students\n'
              '• Career guidance and mentorship by professionals\n'
              '• Educational seminars and workshops\n'
              '• Coaching and exam preparation resources\n'
              '• Promoting digital literacy and skill development',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Mentor & Support'),
            SizedBox(height: 8),
            Text(
              'Are you an educator, professional, or academician? Join our mentor network and inspire the next generation.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

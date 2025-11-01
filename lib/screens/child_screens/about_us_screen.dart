import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppTitle('Varshney Vaishy Samaj'),
            SizedBox(height: 16),
            Text(
              'The Varshney Vaishy Samaj  is a community-led platform that brings together '
              'members of the Varshney (Bania) community from across regions, promoting values '
              'of unity, tradition, service, and progress.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Our Vision'),
            SizedBox(height: 8),
            Text(
              'To unite Varshney families under one digital roof, preserve our cultural heritage, '
              'and empower members through information sharing, education, and social initiatives.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Our Mission'),
            SizedBox(height: 8),
            Text(
              '• Build a connected directory of families\n'
              '• Facilitate blood donation and medical aid\n'
              '• Promote educational and career guidance\n'
              '• Celebrate cultural events and traditions\n'
              '• Foster mutual support and Jan Sewa',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            SizedBox(height: 16),
            AppTitle('Motto'),
            SizedBox(height: 8),
            Text(
              'संस्कार • एकता • सेवा\nSanskars • Unity • Service',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

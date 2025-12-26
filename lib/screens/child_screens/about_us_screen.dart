import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'About Us',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.groups_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: 'Varshney Vaishy Samaj',
                    icon: Icons.verified_user_rounded,
                    content:
                        'The Varshney Vaishy Samaj is a community-led platform that brings together members of the Varshney (Bania) community from across regions, promoting values of unity, tradition, service, and progress.',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Our Vision',
                    icon: Icons.visibility_rounded,
                    content:
                        'To unite Varshney families under one digital roof, preserve our cultural heritage, and empower members through information sharing, education, and social initiatives.',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Our Mission',
                    icon: Icons.track_changes_rounded,
                    content:
                        '• Build a connected directory of families\n• Facilitate blood donation and medical aid\n• Promote educational and career guidance\n• Celebrate cultural events and traditions\n• Foster mutual support and Jan Sewa',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Motto',
                    icon: Icons.format_quote_rounded,
                    content: 'संस्कार • एकता • सेवा\nSanskars • Unity • Service',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Jai Varshney Samaj',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String content,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isHighlight ? AppColors.primary : AppColors.subtitle,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

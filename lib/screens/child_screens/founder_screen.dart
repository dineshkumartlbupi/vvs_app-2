import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';

class FounderScreen extends StatelessWidget {
  const FounderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leadership'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionHeader('Visionary Founder'),
            const SizedBox(height: 20),
            _buildFounderCard(
              name: 'RAHUL VARSHNEY',
              role: 'Founder',
              imageUrl:
                  'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2Frahul.jpeg?alt=media&token=a4a9d287-8510-42e5-b530-dc23356ae417',
              isMain: true,
            ),
            const SizedBox(height: 40),
            _buildSectionHeader('Co-Founders'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFounderCard(
                    name: 'ANIL VARSHNEY',
                    role: 'Co-Founder',
                    imageUrl:
                        'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2FANIL.jpeg?alt=media&token=9226f326-a7fd-4574-a8cc-d45617f93634',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFounderCard(
                    name: 'PIYUSH VARSHNEY',
                    role: 'Co-Founder',
                    imageUrl:
                        'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2Fpiyush.jpeg?alt=media&token=6b768437-b571-4f52-b754-970cd34bbe8f',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFounderCard({
    required String name,
    required String role,
    required String imageUrl,
    bool isMain = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Container
          Container(
            height: isMain ? 280 : 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Info Container
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMain ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: isMain ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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

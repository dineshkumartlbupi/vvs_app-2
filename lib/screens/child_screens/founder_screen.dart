import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';

class FounderScreen extends StatelessWidget {
  const FounderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Founders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('FOUNDER'),
            const SizedBox(height: 12),
            _buildFounderCard(
              name: 'RAHUL VARSHNEY',
              imageUrl:'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2Frahul.jpeg?alt=media&token=a4a9d287-8510-42e5-b530-dc23356ae417',
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('CO-FOUNDERS'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFounderCard(
                  name: 'ANIL VARSHNEY',
                  imageUrl:
                      'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2FANIL.jpeg?alt=media&token=9226f326-a7fd-4574-a8cc-d45617f93634',
                ),
                _buildFounderCard(
                  name: 'PIYUSH VARSHNEY',
                  imageUrl:
                      'https://firebasestorage.googleapis.com/v0/b/vvsamajapp.firebasestorage.app/o/founders%2Fpiyush.jpeg?alt=media&token=6b768437-b571-4f52-b754-970cd34bbe8f',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFounderCard({required String name, required String imageUrl}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/theme/app_colors.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileDetailScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? 'Unnamed';
    final profession = userData['profession'] ?? 'Not specified';
    final address = userData['address'] ?? 'Not specified';
    final bio = userData['bio'] ?? 'No bio available.';
    final photoUrl = userData['photoUrl'];
    final joinedAt = userData['createdAt'] is Timestamp
        ? DateFormat.yMMMd().format((userData['createdAt'] as Timestamp).toDate())
        : 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(photoUrl),
              )
            else
              const CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              profession,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              address,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Joined on $joinedAt', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

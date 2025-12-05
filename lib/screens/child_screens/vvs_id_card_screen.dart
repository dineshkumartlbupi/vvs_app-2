// lib/screens/vvs_id_card_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class VvsIdCardScreen extends StatelessWidget {
  const VvsIdCardScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc('__missing__')
          .get()
          .asStream()
          .map((s) => s as DocumentSnapshot<Map<String, dynamic>>);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  String _formatJoin(dynamic ts) {
    if (ts == null) return '—';
    try {
      if (ts is Timestamp) return DateFormat.yMMMd().format(ts.toDate());
      if (ts is int)
        return DateFormat.yMMMd()
            .format(DateTime.fromMillisecondsSinceEpoch(ts));
      if (ts is String) {
        final parsed = DateTime.tryParse(ts);
        if (parsed != null) return DateFormat.yMMMd().format(parsed);
      }
    } catch (_) {}
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Varshney One ID'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data;
          final data = doc?.data() ?? <String, dynamic>{};

          final name = (data['name'] ?? data['displayName'] ?? '').toString();
          final regCode =
              (data['registrationCode'] ?? data['regCode'] ?? '').toString();
          final vvsId =
              (data['vvsId'] ?? data['memberId'] ?? currentUid ?? '').toString();
          final phone = (data['phone'] ?? data['mobile'] ?? '').toString();
          final email = (data['email'] ?? '').toString();
          final photo = (data['photoUrl'] ?? data['avatar'] ?? '').toString();
          final status = (data['status'] ?? 'Unverified').toString();
          final profession =
              (data['profession'] ?? data['occupation'] ?? '').toString();
          final address = (data['address'] ?? '').toString();
          final joined = _formatJoin(data['createdAt'] ?? data['joinedAt']);

          if ((doc == null || !doc.exists) && currentUid.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // The ID Card
                _buildIdCard(
                  context,
                  name: name,
                  photo: photo,
                  profession: profession,
                  status: status,
                  joined: joined,
                  vvsId: vvsId,
                  regCode: regCode,
                ),
                const SizedBox(height: 32),

                // Details Section
                _buildDetailsSection(phone, email, address),

                const SizedBox(height: 32),

                // Actions
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded,
              size: 64, color: AppColors.subtitle.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Not Signed In',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text),
          ),
          const SizedBox(height: 8),
          const Text('Please sign in to view your ID card.',
              style: TextStyle(color: AppColors.subtitle)),
        ],
      ),
    );
  }

  Widget _buildIdCard(
    BuildContext context, {
    required String name,
    required String photo,
    required String profession,
    required String status,
    required String joined,
    required String vvsId,
    required String regCode,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            top: -50,
            right: -50,
            child: Icon(
              Icons.verified_user_outlined,
              size: 250,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Ensure you have a logo asset or use Icon
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'OFFICIAL MEMBER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Info
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: photo.isNotEmpty
                            ? NetworkImage(photo)
                            : null,
                        child: photo.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Member Name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profession.isNotEmpty ? profession : 'Member',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'verified'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: status.toLowerCase() == 'verified'
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status.toLowerCase() == 'verified'
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ID Details Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIdField('ID Number', vvsId.isNotEmpty ? vvsId : '---'),
                      _buildIdField('Reg. Code', regCode.isNotEmpty ? regCode : '---'),
                      _buildIdField('Joined', joined),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: vvsId.isNotEmpty ? vvsId : 'VVS-APP',
                    version: QrVersions.auto,
                    size: 80,
                    gapless: true,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan to verify',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(String phone, String email, String address) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.phone_rounded, phone.isNotEmpty ? phone : 'Not provided'),
          const Divider(height: 24),
          _buildDetailRow(Icons.email_rounded, email.isNotEmpty ? email : 'Not provided'),
          const Divider(height: 24),
          _buildDetailRow(Icons.location_on_rounded, address.isNotEmpty ? address : 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.subtitle),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Share ID',
            leadingIcon: Icons.share_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing feature coming soon!')),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppOutlinedButton(
            text: 'Download',
            leadingIcon: Icons.download_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
          ),
        ),
      ],
    );
  }
}

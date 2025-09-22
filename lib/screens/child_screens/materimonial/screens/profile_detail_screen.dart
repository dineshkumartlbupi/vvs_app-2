import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/theme/app_colors.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileDetailScreen({super.key, required this.userData});

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  int? _ageOf(dynamic dob) {
    DateTime? d;
    if (dob is Timestamp) {
      d = dob.toDate();
    } else if (dob is DateTime) {
      d = dob;
    } else if (dob is String) {
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('MM/dd/yyyy'),
      ];
      for (final f in formats) {
        try {
          d = f.parseStrict(dob);
          break;
        } catch (_) {}
      }
    }
    if (d == null) return null;

    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsapp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _sms(String phone) async {
    await launchUrl(Uri.parse('sms:$phone'));
  }

  void _chat(
    BuildContext context,
    String uid,
    String name,
    String photo,
    String phone,
  ) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'peerId': uid,
        'peerName': name,
        'peerPhoto': photo,
        'peerPhone': phone,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _cap(userData['name']?.toString());
    final profession = _cap(userData['profession']?.toString());
    final address = _cap(userData['address']?.toString());
    final bio = (userData['bio'] ?? 'No bio available.').toString();
    final photoUrl = (userData['photoUrl'] ?? '').toString();
    final joinedAt = userData['createdAt'] is Timestamp
        ? DateFormat.yMMMd().format(
            (userData['createdAt'] as Timestamp).toDate(),
          )
        : 'N/A';
    final age = _ageOf(userData['dob']);
    final height = (userData['height'] ?? '').toString();
    final gotra = (userData['gotra'] ?? '').toString();
    final gender = (userData['gender'] ?? '').toString();
    final phone = (userData['mobile'] ?? userData['phone'] ?? '').toString();
    final uid = (userData['_id'] ?? userData['uid'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? 'Profile' : name)),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (age != null || gender.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (gender.isNotEmpty) gender,
                  if (age != null) '$age yrs',
                ].join(' • '),
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            const SizedBox(height: 6),
            if (profession.isNotEmpty)
              Text(profession, style: const TextStyle(color: Colors.black87)),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black54),
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(text: ' $address'),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Joined on $joinedAt',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            // Quick facts
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (height.isNotEmpty) _chip(height, Icons.height_rounded),
                if (gotra.isNotEmpty)
                  _chip('Gotra: $gotra', Icons.family_restroom_rounded),
              ],
            ),

            // Bio
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bio",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bio,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            // Connect buttons
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: phone.isEmpty ? null : () => _call(phone),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: phone.isEmpty ? null : () => _whatsapp(phone),
                    icon: const Icon(Icons.call),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: phone.isEmpty ? null : () => _sms(phone),
                    icon: const Icon(Icons.sms_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () => _chat(context, uid, name, photoUrl, phone),
                    icon: const Icon(Icons.chat_bubble_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

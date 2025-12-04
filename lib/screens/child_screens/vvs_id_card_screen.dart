// lib/screens/vvs_id_card_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vvs_app/theme/app_colors.dart';

class VvsIdCardScreen extends StatelessWidget {
  const VvsIdCardScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // If not signed in, return an empty stream of a missing doc so UI shows graceful empty state.
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
      if (ts is int) return DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(ts));
      if (ts is String) {
        final parsed = DateTime.tryParse(ts);
        if (parsed != null) return DateFormat.yMMMd().format(parsed);
      }
    } catch (_) {}
    return '—';
  }

  Widget _avatar(String? url, String name, double size) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primary.withOpacity(0.08),
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox.shrink(),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Varshney One ID Card'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data;
          final data = doc?.data() ?? <String, dynamic>{};

          // fields with safe fallbacks
          final name = (data['name'] ?? data['displayName'] ?? '').toString();
          final regCode = (data['registrationCode'] ?? data['regCode'] ?? '').toString();
          // primary VVS id: prefer explicit field, else use Firebase uid
          final vvsId = (data['vvsId'] ?? data['memberId'] ?? currentUid ?? '').toString();
          final phone = (data['phone'] ?? data['mobile'] ?? '').toString();
          final email = (data['email'] ?? '').toString();
          final photo = (data['photoUrl'] ?? data['avatar'] ?? '').toString();
          final status = (data['status'] ?? 'Unverified').toString();
          final profession = (data['profession'] ?? data['occupation'] ?? '').toString();
          final address = (data['address'] ?? '').toString();
          final joined = _formatJoin(data['createdAt'] ?? data['joinedAt']);

          // If no real user loaded (doc missing), show helpful empty state
          if ((doc == null || !doc.exists) && currentUid.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Not signed in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Please sign in to view your VVS ID card.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 1080;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                     width: 1000,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _avatar(photo, name, 112),
                              const SizedBox(height: 12),
                              Text(name.isNotEmpty ? name : 'Unnamed Member', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(profession.isNotEmpty ? profession : '—', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                                Chip(
                                  backgroundColor: status.toLowerCase() == 'verified' ? Colors.green.shade50 : Colors.orange.shade50,
                                  label: Text(status, style: TextStyle(color: status.toLowerCase() == 'verified' ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.w700)),
                                ),
                               
                              ]),
                               Text('Joined $joined', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 12),
                              // id block + qr below
                              _idAndQrBlock(vvsId: vvsId, regCode: regCode),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _avatar(photo, name, 112),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name.isNotEmpty ? name : 'Unnamed Member', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 6),
                                          Text(profession.isNotEmpty ? profession : '—', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            Chip(
                                              backgroundColor: status.toLowerCase() == 'verified' ? Colors.green.shade50 : Colors.orange.shade50,
                                              label: Text(status, style: TextStyle(color: status.toLowerCase() == 'verified' ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.w700)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('Joined $joined', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // right side: id block + qr
                              SizedBox(width: 210, child: _idAndQrBlock(vvsId: vvsId, regCode: regCode)),
                            ],
                          ),
                  ),

                  const SizedBox(height: 18),

                  // Contact & details card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 980),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(child: Text(phone.isNotEmpty ? phone : '—')),
                            const SizedBox(width: 12),
                            const Icon(Icons.mail_outline, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Flexible(child: Text(email.isNotEmpty ? email : '—', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(child: Text(address.isNotEmpty ? address : '—')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action buttons (safe layout to avoid infinite constraints)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Align(
                      alignment: Alignment.center,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: implement share as image (RepaintBoundary -> toImage)
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share ID'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(140, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: implement download / print
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download feature coming soon')));
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Download'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(140, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  // Extracted helper for ID block + QR
  Widget _idAndQrBlock({required String vvsId, required String regCode}) {
    final qrData = (vvsId.isNotEmpty) ? vvsId : (regCode.isNotEmpty ? regCode : '');
    final showQr = qrData.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('VVS MEMBER', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
          ),
          child: Column(
            children: [
              Text('Reg. Code', style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 12)),
              const SizedBox(height: 6),
              Text(regCode.isNotEmpty ? regCode : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('VVS ID', style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 12)),
              const SizedBox(height: 6),
              Text(vvsId.isNotEmpty ? vvsId : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        showQr
            ? Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 70,
                    gapless: true,
                    backgroundColor: Colors.white,
                  ),
                ),
              )
            : Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('QR', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
      ],
    );
  }
}

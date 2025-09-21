import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsDetailScreen.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsPostScreen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class NewsBulletinScreen extends StatelessWidget {
  NewsBulletinScreen({super.key});
  final NewsBulletinController controller = Get.put(NewsBulletinController());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userSnap.data!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final bool isAdmin = (userData?['role'] == 'admin');

            return Scaffold(
              backgroundColor: AppColors.background,

              body: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final newsDocs = controller.newsList;
                if (newsDocs.isEmpty) {
                  return const Center(child: Text('No news available.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: newsDocs.length,
                  itemBuilder: (context, index) {
                    final doc = newsDocs[index];
                    final raw = doc.data();

                    // --- Safe field reads ---
                    final title = (raw['title'] as String? ?? '').trim();
                    final content = (raw['content'] as String? ?? '').trim();
                    final imageUrl = (raw['imageUrl'] as String? ?? '').trim();
                    Timestamp? createdTs;
                    final t1 = raw['timestamp'];
                    final t2 = raw['createdAt'];
                    if (t1 is Timestamp)
                      createdTs = t1;
                    else if (t2 is Timestamp)
                      createdTs = t2;

                    final updatedTs = raw['updatedAt'];
                    final tsUpdated = (updatedTs is Timestamp)
                        ? updatedTs
                        : null;
                    String _fmt(Timestamp? ts) => ts == null
                        ? ''
                        : DateFormat.yMMMd().format(ts.toDate());

                    final whenLabel = tsUpdated != null
                        ? 'Updated on ${_fmt(tsUpdated)}'
                        : 'Posted on ${_fmt(createdTs)}';

                    return GestureDetector(
                      onTap: () {
                        Get.to(() => NewsDetailScreen(newsData: raw));
                      },
                      child: _NewsCard(
                        title: title.isEmpty ? 'Untitled' : title,
                        content: content,
                        imageUrl: imageUrl,
                        whenLabel: whenLabel,
                        isAdmin: isAdmin,
                        onEdit: isAdmin
                            ? () {
                                Get.to(
                                  () => NewsPostScreen(
                                    existingData: raw,
                                    docId: doc.id,
                                  ),
                                );
                              }
                            : null,
                        onDelete: isAdmin
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete News'),
                                    content: const Text(
                                      'Are you sure you want to delete this news item?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await controller.deleteNews(doc.id);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                );
              }),
              floatingActionButton: isAdmin
                  ? FloatingActionButton(
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Get.to(
                          () =>
                              const NewsPostScreen(existingData: {}, docId: ''),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

/* ==================== Card / Item ==================== */

class _NewsCard extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;
  final String whenLabel;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _NewsCard({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.whenLabel,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(imageUrl: imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title only (no content preview)
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          whenLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        _PillButton(
                          label: 'Edit',
                          color: Colors.blue,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 6),
                        _PillButton(
                          label: 'Delete',
                          color: Colors.red,
                          onTap: onDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== Thumbnail ==================== */

class _Thumb extends StatelessWidget {
  final String imageUrl;
  const _Thumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final radius = BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: 84,
        height: 84,
        color: Colors.white10,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ImgFallback(),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const _ImgFallback();
                },
              )
            : const _ImgFallback(),
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Colors.white54),
    );
  }
}

/* ==================== Small Pill Buttons ==================== */

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PillButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.11),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

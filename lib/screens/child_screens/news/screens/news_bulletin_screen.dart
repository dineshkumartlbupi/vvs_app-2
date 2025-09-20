import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsPostScreen.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsDetailScreen.dart';
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
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
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

            final bool isAdmin = userData?['role'] == 'admin';

            return Scaffold(
             
              body: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final newsDocs = controller.newsList;
                if (newsDocs.isEmpty) {
                  return const Center(child: Text('No news available.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: newsDocs.length,
                  itemBuilder: (context, index) {
                    final doc = newsDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    String capitalizeFirst(String text) {
                      if (text.isEmpty) return text;
                      return text[0].toUpperCase() + text.substring(1);
                    }

                    final title = capitalizeFirst(data['title'] as String? ?? '');
                    final content = capitalizeFirst(data['content'] as String? ?? '');
                    final imageUrl = data['imageUrl'] as String? ?? '';

                    final timestamp = data['timestamp'] as Timestamp? ?? data['createdAt'] as Timestamp?;
                    final date = timestamp != null
                        ? DateFormat.yMMMd().format(timestamp.toDate())
                        : '';

                    return GestureDetector(
                      onTap: () {
                        // navigate to detail
                        Get.to(() => NewsDetailScreen(newsData: data));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (imageUrl.isNotEmpty)
                                const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      content,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Posted on $date",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (isAdmin) ...[
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              Get.to(() => NewsPostScreen(
                                                    existingData: data,
                                                    docId: doc.id,
                                                  ));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "Edit",
                                                style: TextStyle(fontSize: 12, color: Colors.blue),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete News'),
                                                  content: const Text('Are you sure you want to delete this news item?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
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
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(fontSize: 12, color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        Get.to(() => NewsPostScreen(existingData: {}, docId: ''));
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

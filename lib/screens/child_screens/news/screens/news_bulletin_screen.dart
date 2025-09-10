import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsPostScreen.dart';


class NewsBulletinScreen extends StatelessWidget {
  // NewsBulletinScreen({Key? key}) : super(key: key);
   NewsBulletinScreen({super.key});
  final NewsBulletinController controller = Get.put(NewsBulletinController());

  void _openPostScreen({Map<String, dynamic>? existingData, String docId = ''}) {
    Get.to(() => NewsPostScreen
    (
          existingData: existingData ?? {},
          docId: docId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       
      ),
      floatingActionButton: Obx(() {
        if (controller.isAdmin.value) {
          return FloatingActionButton(
            onPressed: () => _openPostScreen(),
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.newsList.isEmpty) {
          return const Center(child: Text('No news available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.newsList.length,
          itemBuilder: (context, index) {
            final doc = controller.newsList[index];
            final data = doc.data();

            final title = data['title'] ?? 'No title';
            final content = data['content'] ?? 'No content';
            final imageUrl = data['imageUrl'] ?? '';
            final timestamp = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (timestamp != null)
                      Text(
                        'Posted on: ${timestamp.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: Obx(() {
                  if (controller.isAdmin.value) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _openPostScreen(existingData: data, docId: doc.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await Get.defaultDialog<bool>(
                              title: 'Delete News',
                              middleText: 'Are you sure you want to delete this news?',
                              textConfirm: 'Delete',
                              textCancel: 'Cancel',
                              confirmTextColor: Colors.white,
                              onConfirm: () {
                                Get.back(result: true);
                              },
                              onCancel: () {
                                Get.back(result: false);
                              },
                            );
                            if (confirmed == true) {
                              await controller.deleteNews(doc.id);
                            }
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ),
            );
          },
        );
      }),
    );
  }
}

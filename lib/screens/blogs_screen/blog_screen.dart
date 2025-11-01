import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'add_blog_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteBlog(String id) async {
    await _firestore.collection('blogs').doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Blog deleted successfully')));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight:48,
          title: const Text('Community Blogs'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            dividerHeight: 0,
            indicatorColor: Colors.white,
          labelColor: Colors.white, // active tab text color
          unselectedLabelColor: Colors.white70, // inactive tab text color
            tabs: [
              Tab(text: "All Blogs"),
              Tab(text: "My Blogs"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBlogScreen()),
            );
          },
          backgroundColor: Theme.of(context).primaryColor,
          tooltip: 'Add Blog',
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            // All Blogs tab (no edit/delete)
            _buildBlogList(
              query:
                  _firestore.collection('blogs').orderBy('createdAt', descending: true),
              showActions: false,
              uid: uid,
            ),
            // My Blogs tab (with edit/delete)
            _buildBlogList(
              query: _firestore
                  .collection('blogs')
                  .where('authorId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true),
              showActions: true,
              uid: uid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogList({
    required Query query,
    required bool showActions,
    required String? uid,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No blogs yet. Be the first to write one!'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final title = _capitalize(data['title'] ?? '');
            final content = _capitalize(data['content'] ?? '');
            final author = data['authorName'] ?? 'Anonymous';
            final imageUrl = data['imageUrl'];
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      if (showActions)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddBlogScreen(
                                      blogId: id,
                                      existingData: data,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      width: 1, color: AppColors.primary),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit,
                                        size: 18, color: Colors.blueAccent),
                                    SizedBox(width: 4),
                                    Text("Edit",
                                        style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _deleteBlog(id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      width: 1, color: AppColors.primary),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.redAccent),
                                    SizedBox(width: 4),
                                    Text("Delete",
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'By $author ${createdAt != null ? '• ${_formatDate(createdAt)}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 10),
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageUrl != null) const SizedBox(height: 10),

                  Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

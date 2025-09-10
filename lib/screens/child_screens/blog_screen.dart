import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
//import 'package:vvs_app/widgets/ui_components.dart'; // For AppTitle

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final List<Map<String, String>> _blogs = [
    {
      'title': 'Unity in Diversity',
      'content': 'Our community events have shown how cultural diversity strengthens our unity.'
    },
    {
      'title': 'Seva Stories',
      'content': 'Read inspiring stories of members who contributed to blood donation and Jan Sewa.'
    },
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _showAddBlogDialog() {
    _titleController.clear();
    _contentController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Blog'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                final title = _titleController.text.trim();
                final content = _contentController.text.trim();
                if (title.isNotEmpty && content.isNotEmpty) {
                  setState(() {
                    _blogs.insert(0, {'title': title, 'content': content});
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blog Section'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBlogDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Add Blog',
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _blogs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final blog = _blogs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  blog['content'] ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

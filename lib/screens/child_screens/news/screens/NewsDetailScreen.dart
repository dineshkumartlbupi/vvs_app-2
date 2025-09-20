import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsData;

  const NewsDetailScreen({super.key, required this.newsData});

  @override
  Widget build(BuildContext context) {
    String capitalizeFirst(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }

    final title = capitalizeFirst(newsData['title'] ?? '');
    final content = capitalizeFirst(newsData['content'] ?? '');
    final imageUrl = newsData['imageUrl'] ?? '';
    final ts = newsData['createdAt'];
    final date = ts != null ? DateFormat('MMMM dd, yyyy').format(ts.toDate()) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('News Details'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, width: double.infinity, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(date, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
        ]),
      ),
    );
  }
}

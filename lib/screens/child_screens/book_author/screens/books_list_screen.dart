import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vvs_app/screens/child_screens/book_author/controller/book_upload_controller.dart';
import 'package:vvs_app/screens/child_screens/book_author/screens/add_book_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  @override
  void initState() {
    super.initState();
    BookUploadController.fetchUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Books & Authors'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: BookUploadController.getBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 80, color: AppColors.subtitle.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    "No books available yet.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            );
          }

          final books = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final book = books[index];
              final title = book['title'] ?? 'Untitled';
              final author = book['author'] ?? 'Unknown Author';
              // final pdfUrl = book['pdfUrl']; // Use when implementing open

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "By $author",
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppColors.accent),
                  ),
                  onTap: () {
                    // TODO: Implement PDF viewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reading feature coming soon!')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: BookUploadController.isAdmin,
        builder: (context, isAdmin, _) {
          return isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddBookScreen()),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Book'),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

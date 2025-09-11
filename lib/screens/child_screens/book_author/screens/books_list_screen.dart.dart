import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vvs_app/screens/child_screens/book_author/controller/book_upload_controller.dart';
import 'package:vvs_app/screens/child_screens/book_author/screens/Add_Book_Screendart.dart'; // Fix casing if needed

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Fetch and listen to user's role
    BookUploadController.fetchUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books & Authors'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: BookUploadController.getBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No books found."));
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(book['title']),
                  subtitle: Text("Author: ${book['author']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      final url = book['pdfUrl'];
                      // TODO: Launch PDF URL using url_launcher or PDF viewer
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      // ✅ Show FAB only if user is admin
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: BookUploadController.isAdmin,
        builder: (context, isAdmin, _) {
          return isAdmin
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddBookScreen()),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : const SizedBox.shrink(); // No button for non-admins
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:vvs_app/services/fire_store_services.dart';

class BookUploadController {
  static final FirestoreService _firestoreService = FirestoreService();

  // ✅ ValueNotifier to track admin state
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);

  /// ✅ Uploads a book with title, author, and PDF to Firestore + Storage
  static Future<bool> uploadBook({
    required String title,
    required String author,
    required PlatformFile pdfFile,
  }) async {
    try {
      final file = File(pdfFile.path!);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('books_pdfs/${DateTime.now().millisecondsSinceEpoch}_${pdfFile.name}');

      final uploadTask = await storageRef.putFile(file);
      final pdfUrl = await uploadTask.ref.getDownloadURL();

      final Map<String, dynamic> data = {
        'title': title,
        'author': author,
        'pdfUrl': pdfUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.addDocument(
        collection: 'books',
        data: data,
      );

      return true;
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  /// ✅ Listen to books collection in Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getBooksStream() {
    return _firestoreService.listenToCollection(collection: 'books');
  }

  /// ✅ Fetch and listen to current user's role
  static void fetchUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isAdmin.value = false;
      return;
    }

    _firestoreService
        .listenToDocument(collection: 'users', docId: user.uid)
        .listen((doc) {
      final data = doc.data();
      isAdmin.value = (data?['role'] == 'admin');
    });
  }
}

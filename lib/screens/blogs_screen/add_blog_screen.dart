import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AddBlogScreen extends StatefulWidget {
  final String? blogId;
  final Map<String, dynamic>? existingData;

  const AddBlogScreen({super.key, this.blogId, this.existingData});

  @override
  State<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _contentController.text = widget.existingData!['content'] ?? '';
      _existingImageUrl = widget.existingData!['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadOrUpdateBlog() async {
    final title = _capitalize(_titleController.text.trim());
    final content = _capitalize(_contentController.text.trim());
    if (title.isEmpty || content.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final ref = _storage.ref().child(
          'blog_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final uid = _auth.currentUser?.uid ?? 'guest';
      final name = _auth.currentUser?.displayName ?? 'Anonymous';

      if (widget.blogId == null) {
        // 🟢 Create new blog
        await _firestore.collection('blogs').add({
          'title': title,
          'content': content,
          'authorId': uid,
          'authorName': name,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showMessage('Blog added successfully!');
      } else {
        // 🟡 Update existing blog
        await _firestore.collection('blogs').doc(widget.blogId).update({
          'title': title,
          'content': content,
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _showMessage('Blog updated successfully!');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving blog: $e');
      _showMessage('Error saving blog');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.blogId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Blog' : 'Add New Blog'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _existingImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Tap to upload image'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              AppInput(controller: _titleController, label: 'Title'),
              const SizedBox(height: 20),
              AppInput(
                controller: _contentController,
                maxLines: 6,
                label: "Description",
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadOrUpdateBlog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Update Blog' : 'Publish Blog',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

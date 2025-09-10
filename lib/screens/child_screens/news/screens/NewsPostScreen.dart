import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';

class NewsPostScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  final String docId;

  const NewsPostScreen({super.key, required this.existingData, required this.docId});

  @override
  _NewsPostScreenState createState() => _NewsPostScreenState();
}

class _NewsPostScreenState extends State<NewsPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _contentC = TextEditingController();
  File? _imageFile;
  bool _loading = false;
  final controller = Get.find<NewsBulletinController>();

  @override
  void initState() {
    super.initState();
    if (widget.existingData.isNotEmpty) {
      _titleC.text = widget.existingData['title'] ?? '';
      _contentC.text = widget.existingData['content'] ?? '';
      // No local image initially, only URL
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage() async {
    if (_imageFile == null) {
      // Use existing URL if no new image picked
      return widget.existingData['imageUrl'] ?? '';
    }

    final fileName =
        'news_images/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    final uploadTask = ref.putFile(_imageFile!);
    final snapshot = await uploadTask;

    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null &&
        (widget.existingData['imageUrl'] == null || widget.existingData['imageUrl'] == '')) {
      Get.snackbar('Error', 'Please pick an image');
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadImage();

      final data = <String, dynamic>{
        'title': _titleC.text.trim(),
        'content': _contentC.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (widget.docId.isEmpty) {
        // New post
        await controller.postNews(
          title: data['title']!,
          content: data['content']!,
          imageUrl: imageUrl,
        );
      } else {
        // Update existing post
        await controller.updateNews(docId: widget.docId, data: data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News saved!')));
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save news: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _contentC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.existingData['imageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId.isEmpty ? 'Add News' : 'Edit News'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
                )
              else if (existingImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(existingImageUrl, height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentC,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveNews,
                      child: Text(widget.docId.isEmpty ? 'Post News' : 'Update News'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

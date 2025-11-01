import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AddEventScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? existingData;

  const AddEventScreen({super.key, this.eventId, this.existingData});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _eventDate;
  File? _selectedImage;
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _descController.text = widget.existingData!['description'] ?? '';
      _locationController.text = widget.existingData!['location'] ?? '';
      _eventDate = (widget.existingData!['eventDate'] as Timestamp?)?.toDate();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<String?> _uploadImage(String eventId) async {
    if (_selectedImage == null) return widget.existingData?['imageUrl'];
    final ref = FirebaseStorage.instance.ref().child(
      'event_images/$eventId.jpg',
    );
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    final isEditing = widget.eventId != null;

    try {
      final eventId = isEditing
          ? widget.eventId!
          : _firestore.collection('events').doc().id;

      final imageUrl = await _uploadImage(eventId);

      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'eventDate': Timestamp.fromDate(_eventDate!),
        'imageUrl': imageUrl ?? '',
        'organizerId': user?.uid,
        'organizerName': user?.displayName ?? user?.email ?? 'Organizer',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await _firestore.collection('events').doc(eventId).update(data);
      } else {
        await _firestore.collection('events').doc(eventId).set(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Event updated' : 'Event added')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.eventId != null ? 'Edit Event' : 'Add Event'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppInput(
                controller: _titleController,
                hint: 'Event Title',
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                label: 'Event Title',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _descController,
                label: 'Description',
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _locationController,
            
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null, label:'Location',
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.withOpacity(0.4)),borderRadius: BorderRadius.all(Radius.circular(16))),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _eventDate == null
                            ? 'Select event date'
                            : 'Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : (widget.existingData?['imageUrl'] != null &&
                          widget.existingData!['imageUrl'].isNotEmpty)
                    ? Image.network(
                        widget.existingData!['imageUrl'],
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_a_photo, size: 40),
                      ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(widget.eventId != null ? 'Update' : 'Save'),
                      onPressed: _saveEvent,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Event updated' : 'Event added')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.eventId != null ? 'Edit Event' : 'Add Event'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _titleController,
                label: 'Event Title',
                prefixIcon: Icons.event_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _descController,
                label: 'Description',
                prefixIcon: Icons.description_rounded,
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.location_on_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              
              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _eventDate == null
                              ? 'Select Event Date'
                              : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _eventDate == null ? AppColors.subtitle : AppColors.text,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.subtitle),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : (widget.existingData?['imageUrl'] != null &&
                                widget.existingData!['imageUrl'].isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(widget.existingData!['imageUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (_selectedImage == null &&
                          (widget.existingData?['imageUrl'] == null ||
                              widget.existingData!['imageUrl'].isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 48, color: AppColors.primary.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Add Event Image',
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 32),
              
              AppButton(
                text: widget.eventId != null ? 'Update Event' : 'Save Event',
                onPressed: _saveEvent,
                isLoading: _isLoading,
                leadingIcon: Icons.save_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

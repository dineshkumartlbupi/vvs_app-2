import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vvs_app/screens/child_screens/materimonial/controller/profile_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileController controller = Get.put(ProfileController());
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    controller.checkProfileExists().then((_) {
      if (controller.hasProfile.value) {
        // show dialog that profile exists
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Profile Exists'),
              content: const Text('You already have a profile.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(); // go back
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (controller.hasProfile.value) {
      // optionally show a toast / dialog that already exists
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Profile Exists'),
            content: const Text('You already have a profile.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String photoUrl = '';
      if (_imageFile != null) {
        final url = await controller.uploadImage(_imageFile!);
        if (url != null) {
          photoUrl = url;
        }
      }
      await controller.addProfile(
        name: _nameController.text.trim(),
        profession: _professionController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hasProfile.value) {
        // maybe show a message that profile exists instead of form
        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Profile'),
            backgroundColor: AppColors.primary,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You already have a profile.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Otherwise show form
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Profile'),
          backgroundColor: AppColors.primary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.5),
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _professionController,
                  decoration: const InputDecoration(labelText: 'Profession'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter profession' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter bio' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Profile'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

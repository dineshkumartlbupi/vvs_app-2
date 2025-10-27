// add_organization_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vvs_app/screens/marketplace/controller/marketplace_ctrl.dart';
import 'package:vvs_app/theme/app_theme.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/app_dropdown.dart';
import 'package:vvs_app/widgets/ui_components.dart'; // <-- AppInput / AppDropdown

class AddOrganizationScreen extends StatefulWidget {
  /// If editing, pass the existing document data and the docId.
  final Map<String, dynamic> existingData;
  final String docId;

  const AddOrganizationScreen({
    super.key,
    this.existingData = const {},
    this.docId = '',
  });

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Get marketplace controller (categories/subcategories map)
  final MarketplaceCtrl _mpCtrl = Get.put(MarketplaceCtrl());

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  // Image
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  String _uploadedImageUrl = '';
  bool _imageRemoved = false; // user explicitly removed existing image

  // UI state
  bool _loading = false;

  // Local selection for category/subcategory (uses controller's map)
  String _category = '';
  String _subcategory = '';

  bool get _isEdit => widget.docId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initFromExisting();
  }

  void _initFromExisting() {
    final d = widget.existingData;
    if (d.isEmpty) return;

    _nameCtrl.text = (d['name'] ?? '').toString();
    _typeCtrl.text = (d['type'] ?? '').toString();
    _addressCtrl.text = (d['address'] ?? '').toString();
    _cityCtrl.text = (d['city'] ?? '').toString();
    _phoneCtrl.text = (d['phone'] ?? '').toString();
    _emailCtrl.text = (d['email'] ?? '').toString();
    _websiteCtrl.text = (d['website'] ?? '').toString();
    _hoursCtrl.text = (d['hours'] ?? '').toString();
    _descCtrl.text = (d['description'] ?? '').toString();

    final cat = (d['category'] ?? '').toString();
    final sub = (d['subcategory'] ?? '').toString();

    // If category not in controller map, add it (keeps it selectable)
    if (cat.isNotEmpty && !_mpCtrl.categoriesMap.containsKey(cat)) {
      // add dynamically - preserve existing subcategory if any
      _mpCtrl.categoriesMap[cat] = sub.isNotEmpty ? [sub] : ['Other'];
    }

    _category = cat;
    if (sub.isNotEmpty) {
      _subcategory = sub;
    } else {
      // fallback: first subcategory for category or empty
      final subs = _mpCtrl.subcategoriesFor(_category);
      _subcategory = subs.isNotEmpty ? subs.first : '';
    }

    _uploadedImageUrl = (d['imageUrl'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _hoursCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;
    final source = result == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _imageRemoved = false; // we have a new image
      });
    }
  }

  Future<String> _uploadImageIfNeeded() async {
    // If user removed image and did not pick a new one -> return empty
    if (_imageRemoved && _pickedImage == null) {
      _uploadedImageUrl = '';
      return '';
    }

    // If user picked a new image — upload
    if (_pickedImage != null) {
      final fileName =
          'organizations/${DateTime.now().millisecondsSinceEpoch}_${_pickedImage!.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(_pickedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final url = await snapshot.ref.getDownloadURL();
      _uploadedImageUrl = url;
      return url;
    }

    // No new image and not removed -> keep existing URL (if any)
    return _uploadedImageUrl;
  }

  bool _isValidUrl(String? value) {
    if (value == null || value.trim().isEmpty) return true; // optional
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_category.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a category')));
      return;
    }
    if (_subcategory.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a subcategory')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadImageIfNeeded();

      final user = FirebaseAuth.instance.currentUser;
      final collection = FirebaseFirestore.instance.collection('marketplaces');

      final docData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'category': _category.trim(),
        'subcategory': _subcategory.trim(),
        'type': _typeCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'hours': _hoursCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': imageUrl,
      };

      if (_isEdit) {
        // Keep createdBy/createdAt if present; only set updatedAt
        docData['updatedAt'] = FieldValue.serverTimestamp();
        await collection.doc(widget.docId).update(docData);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Organization updated')));
          Navigator.of(context).pop();
        }
      } else {
        docData['createdAt'] = FieldValue.serverTimestamp();
        docData['createdBy'] = user?.uid;
        await collection.add(docData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Organization added successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('AddOrg error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImageCard() {
    final hasPicked = _pickedImage != null;
    final hasExisting = _uploadedImageUrl.isNotEmpty && !_imageRemoved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Image',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.light.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: GestureDetector(
            onTap: _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.white10,
                  child: hasPicked
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : hasExisting
                      ? Image.network(_uploadedImageUrl, fit: BoxFit.cover)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tap to add image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.light.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                label: Text(
                  hasPicked || hasExisting ? 'Change image' : 'Add image',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (hasPicked || hasExisting)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _pickedImage = null;
                    _uploadedImageUrl = '';
                    _imageRemoved = true;
                  });
                },
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitLabel = _isEdit ? 'Update Marketplace' : 'Submit Marketplace';
    final categories = _mpCtrl.categoriesMap.keys.toList().toSet().toList();
    final currentSubcats = _mpCtrl.subcategoriesFor(_category).toSet().toList();
    // Ensure the dropdown value is null if not found in items
    final categoryValue = categories.contains(_category) ? _category : null;
    final subcategoryValue = currentSubcats.contains(_subcategory)
        ? _subcategory
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Marketplace' : 'Add Marketplace'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.business, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Add Marketplace',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Help the community discover local services',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Image
                        _buildImageCard(),
                        const SizedBox(height: 16),

                        // Name -> using AppInput
                        AppInput(
                          controller: _nameCtrl,
                          label: 'Name *',
                          prefixIcon: Icons.business_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a name'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        // Category selector -> using AppDropdown
                        AppDropdown(
                          label: 'Category *',
                          items: categories,
                          value: categoryValue, // pass null if not present
                          onChanged: (val) {
                            setState(() {
                              _category = val ?? '';
                              final subs = _mpCtrl
                                  .subcategoriesFor(_category)
                                  .toSet()
                                  .toList();
                              _subcategory = subs.isNotEmpty ? subs.first : '';
                            });
                          },
                          validator: (val) => (val == null || val.isEmpty)
                              ? 'Please select a category'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Subcategory selector (dependent)
                        AppDropdown(
                          label: 'Subcategory *',
                          items: currentSubcats,
                          value: subcategoryValue, // safe value
                          onChanged: (val) =>
                              setState(() => _subcategory = val ?? ''),
                          validator: (val) => (val == null || val.isEmpty)
                              ? 'Please select a subcategory'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _typeCtrl,
                          label: 'Type or Tagline (optional)',
                          prefixIcon: Icons.type_specimen,
                          // validator: (v) => (v == null || v.trim().isEmpty)
                          //     ? 'Please enter a name'
                          //     : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        AppInput(
                          controller: _addressCtrl,
                          label: 'Address *',
                          prefixIcon: Icons.location_city,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter address'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        AppInput(
                          controller: _cityCtrl,
                          label: 'City *',
                          prefixIcon: Icons.location_city,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter city'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        AppInput(
                          keyboardType: TextInputType.phone,
                          controller: _phoneCtrl,
                          label: 'Phone *',
                          prefixIcon: Icons.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter phone'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        AppInput(
                          controller: _emailCtrl,
                          label: 'Email (optional)',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return v.contains('@') ? null : 'Enter valid email';
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        AppInput(
                          controller: _websiteCtrl,
                          label: 'Website (optional)',
                          prefixIcon: Icons.web,
                          keyboardType: TextInputType.url,
                          validator: (v) => _isValidUrl(v)
                              ? null
                              : 'Enter valid URL (http/https)',
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),
                        AppInput(
                          controller: _hoursCtrl,
                          label: 'Opening hours (optional)',
                          prefixIcon: Icons.calendar_month,
                          hint: '9:00 AM - 6:00 PM',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        AppInput(
                          controller: _descCtrl,
                          label: 'Short description *',
                          prefixIcon: Icons.description,
                          hint: 'Enter a short description',
                          keyboardType: TextInputType.text,
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a short description'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 18),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    submitLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By submitting you agree that the details are accurate. The community will be able to see this listing.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                child: const Center(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

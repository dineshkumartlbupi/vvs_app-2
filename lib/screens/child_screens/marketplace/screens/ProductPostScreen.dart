import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vvs_app/screens/child_screens/marketplace/controllers/marketplace_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class ProductPostScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  final String docId;

  const ProductPostScreen({
    super.key,
    required this.existingData,
    required this.docId,
  });

  @override
  State<ProductPostScreen> createState() => _ProductPostScreenState();
}

class _ProductPostScreenState extends State<ProductPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceController controller = Get.put(MarketplaceController());

  final _picker = ImagePicker();
  bool _dirty = false; // track unsaved changes

  @override
  void initState() {
    super.initState();
    controller.initializeForm(widget.existingData);

    // Mark dirty if user edits anything
    controller.nameController.addListener(_markDirty);
    controller.priceController.addListener(_markDirty);
    controller.descriptionController.addListener(_markDirty);
    controller.qtyController.addListener(_markDirty);
  }

  @override
  void dispose() {
    controller.nameController.removeListener(_markDirty);
    controller.priceController.removeListener(_markDirty);
    controller.descriptionController.removeListener(_markDirty);
    controller.qtyController.removeListener(_markDirty);
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickImageSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    final source = (choice == 'camera')
        ? ImageSource.camera
        : ImageSource.gallery;
    await _pickAndUploadImage(source);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    controller.isLoadingMarketplace.value = true;
    final file = File(picked.path);
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'product_images/$fileName',
      );
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      controller.imageUrl.value = downloadUrl;
      _markDirty();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      controller.isLoadingMarketplace.value = false;
    }
  }

  void _removeImage() {
    controller.imageUrl.value = '';
    _markDirty();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Do you really want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _onSubmit() {
    if (controller.isLoadingMarketplace.value) return;
    if (_formKey.currentState?.validate() ?? false) {
      controller.submitProduct(context: context, docId: widget.docId);
      _dirty = false;
    }
  }

  InputDecoration _inputDeco({
    required String label,
    String? hint,
    String? helper,
    IconData? icon,
    String? prefixText,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon, size: 22),
      prefixText: prefixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.border, width: 1.0),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.border, width: 1.1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docId.isNotEmpty;
    final title = isEditing ? 'Edit Product' : 'Add New Product';

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: Text(title),
        ),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    color: AppColors.card,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover image
                              _HeaderImage(
                                imageUrl: controller.imageUrl.value,
                                onPick: _pickImageSheet,
                                onRemove: controller.imageUrl.value.isNotEmpty
                                    ? _removeImage
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              // Category
                              DropdownButtonFormField<String>(
                                value: controller.category.value.isEmpty
                                    ? null
                                    : controller.category.value,
                                items: controller.categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  controller.category.value = v ?? '';
                                  _markDirty();
                                },
                                decoration: _inputDeco(
                                  label: 'Category',
                                  hint: 'Select a category',
                                  icon: Icons.category_rounded,
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please select category'
                                    : null,
                              ),

                              const SizedBox(height: 16),

                              // Name
                              TextFormField(
                                controller: controller.nameController,
                                maxLength: 80,
                                decoration: _inputDeco(
                                  label: 'Product Name',
                                  hint: 'e.g. Redmi Note 13 Pro 8/256GB',
                                  icon: Icons.inventory_2_outlined,
                                ).copyWith(counterText: ''),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Please enter product name'
                                    : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller.qtyController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      decoration: _inputDeco(
                                        label: 'Quantity',
                                        hint: 'e.g. 1',
                                        icon:
                                            Icons.confirmation_number_outlined,
                                      ),
                                      validator: (v) {
                                        final t = (v ?? '').trim();
                                        if (t.isEmpty)
                                          return 'Please enter quantity';
                                        final n = int.tryParse(t);
                                        if (n == null || n <= 0)
                                          return 'Quantity must be > 0';
                                        return null;
                                      },
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: controller.unit.value.isEmpty
                                          ? null
                                          : controller.unit.value,
                                      items: controller.units
                                          .map(
                                            (u) => DropdownMenuItem(
                                              value: u,
                                              child: Text(u),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        controller.unit.value = v ?? '';
                                        _markDirty();
                                      },
                                      decoration: _inputDeco(
                                        label: 'Units',
                                        hint: 'Select units',
                                        icon: Icons.straighten_rounded,
                                      ),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Select units'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Condition
                              DropdownButtonFormField<String>(
                                value: controller.condition.value.isEmpty
                                    ? null
                                    : controller.condition.value,
                                items: controller.conditions
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  controller.condition.value = v ?? 'New';
                                  _markDirty();
                                },
                                decoration: _inputDeco(
                                  label: 'Condition',
                                  hint: 'Select condition',
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Please select condition'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Price
                              TextFormField(
                                controller: controller.priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: _inputDeco(
                                  label: 'Price ',
                                  hint: 'e.g. 24999',
                                  helper:
                                      'Only numbers, up to 2 decimal places',
                                  icon: Icons.currency_rupee_rounded,
                                  prefixText: '₹ ',
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return 'Please enter price';
                                  final n = double.tryParse(t);
                                  if (n == null) return 'Enter a valid number';
                                  if (n <= 0)
                                    return 'Price must be greater than 0';
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),

                              // Negotiable
                              Row(
                                children: [
                                  Obx(
                                    () => Switch.adaptive(
                                      value: controller.negotiable.value,
                                      onChanged: (v) {
                                        controller.negotiable.value = v;
                                        _markDirty();
                                      },
                                      activeColor: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Price negotiable'),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Description
                              TextFormField(
                                controller: controller.descriptionController,
                                maxLength: 100,
                                maxLines: 1,
                                decoration: _inputDeco(
                                  label: 'Description',
                                  hint:
                                      'Describe condition, features, what’s included, pickup/delivery, etc.',
                                  icon: Icons.notes_rounded,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Please enter description'
                                    : null,
                                textInputAction: TextInputAction.newline,
                              ),
                              const SizedBox(height: 12),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: Obx(() {
                                  final loading =
                                      controller.isLoadingMarketplace.value;
                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: loading ? 0.6 : 1,
                                    child: AppButton(
                                      text: loading
                                          ? 'Please wait…'
                                          : (isEditing ? 'Update' : 'Submit'),
                                      onPressed: _onSubmit,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay
            Obx(() {
              if (!controller.isLoadingMarketplace.value)
                return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    child: const Center(
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/* ======================= Header Image ======================= */

class _HeaderImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _HeaderImage({
    required this.imageUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return _placeholder();
                        },
                      )
                    : _placeholder(),
              ),

              // Top-right: Add/Change
              Positioned(
                top: 8,
                right: 8,
                child: _ActionChip(
                  icon: Icons.image_rounded,
                  label: hasImage ? 'Change' : 'Add image',
                  onTap: onPick,
                ),
              ),
              if (onRemove == null)
                Positioned(
                  right: 0,
                  bottom: 70,
                  left: 0,
                  child: Text("Upload image", textAlign: TextAlign.center),
                ),

              // Top-left: Remove
              if (onRemove != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _ActionChip(
                    icon: Icons.delete_forever_rounded,
                    label: 'Remove',
                    onTap: onRemove!,
                    isDestructive: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image_outlined, size: 42, color: Colors.white54),
          SizedBox(height: 6),
          Text('Add a cover image', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDestructive
        ? Colors.red.withOpacity(0.9)
        : AppColors.primary.withOpacity(0.9);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.image, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

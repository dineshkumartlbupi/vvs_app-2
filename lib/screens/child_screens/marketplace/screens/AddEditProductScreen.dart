import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vvs_app/screens/child_screens/marketplace/controllers/marketplace_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddEditProductScreen({
    super.key,
    this.existingData,
    this.docId,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceController controller = Get.put(MarketplaceController());
  final _picker = ImagePicker();
  bool _dirty = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    controller.initializeForm(widget.existingData ?? {});

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
    _animationController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickImageSheet() async {
    HapticFeedback.mediumImpact();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, 'gallery');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, 'camera');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;
    final source =
        (choice == 'camera') ? ImageSource.camera : ImageSource.gallery;
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
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Image uploaded successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Upload failed: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      controller.isLoadingMarketplace.value = false;
    }
  }

  void _removeImage() {
    HapticFeedback.mediumImpact();
    controller.imageUrl.value = '';
    _markDirty();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Discard changes?'),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Do you really want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _onSubmit() {
    if (controller.isLoadingMarketplace.value) return;
    HapticFeedback.heavyImpact();
    if (_formKey.currentState?.validate() ?? false) {
      controller.submitProduct(
        context: context,
        docId: widget.docId ?? '',
      );
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
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: AppColors.primary),
      prefixText: prefixText,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: AppColors.border.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: AppColors.border.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = (widget.docId?.isNotEmpty ?? false);
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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              HapticFeedback.selectionClick();
              final canPop = await _confirmDiscard();
              if (canPop && mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Section
                        _EnhancedHeaderImage(
                          imageUrl: controller.imageUrl.value,
                          onPick: _pickImageSheet,
                          onRemove: controller.imageUrl.value.isNotEmpty
                              ? _removeImage
                              : null,
                        ),

                        const SizedBox(height: 24),

                        // Basic Info Section
                        _buildSectionHeader(
                          Icons.info_outline_rounded,
                          'Basic Information',
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
                            HapticFeedback.selectionClick();
                            controller.category.value = v ?? '';
                            _markDirty();
                          },
                          decoration: _inputDeco(
                            label: 'Category *',
                            hint: 'Select a category',
                            icon: Icons.category_rounded,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please select a category'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Product Name
                        TextFormField(
                          controller: controller.nameController,
                          maxLength: 80,
                          decoration: _inputDeco(
                            label: 'Product Name *',
                            hint: 'e.g., Redmi Note 13 Pro 8/256GB',
                            icon: Icons.inventory_2_outlined,
                          ).copyWith(counterText: ''),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter product name'
                                  : v.trim().length < 3
                                      ? 'Name must be at least 3 characters'
                                      : null,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 24),

                        // Quantity & Units Section
                        _buildSectionHeader(
                          Icons.inventory_rounded,
                          'Quantity & Condition',
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: controller.qtyController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                decoration: _inputDeco(
                                  label: 'Quantity *',
                                  hint: 'e.g., 1',
                                  icon: Icons.confirmation_number_outlined,
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return 'Enter quantity';
                                  final n = int.tryParse(t);
                                  if (n == null || n <= 0) {
                                    return 'Must be > 0';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
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
                                  HapticFeedback.selectionClick();
                                  controller.unit.value = v ?? '';
                                  _markDirty();
                                },
                                decoration: _inputDeco(
                                  label: 'Units *',
                                  hint: 'Select',
                                  icon: Icons.straighten_rounded,
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Select units'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

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
                            HapticFeedback.selectionClick();
                            controller.condition.value = v ?? 'New';
                            _markDirty();
                          },
                          decoration: _inputDeco(
                            label: 'Condition *',
                            hint: 'Select condition',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please select condition'
                              : null,
                        ),

                        const SizedBox(height: 24),

                        // Pricing Section
                        _buildSectionHeader(
                          Icons.currency_rupee_rounded,
                          'Pricing',
                        ),
                        const SizedBox(height: 12),

                        // Price
                        TextFormField(
                          controller: controller.priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: _inputDeco(
                            label: 'Price *',
                            hint: 'e.g., 24999',
                            helper: 'Only numbers, up to 2 decimal places',
                            icon: Icons.currency_rupee_rounded,
                            prefixText: '₹ ',
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Please enter price';
                            final n = double.tryParse(t);
                            if (n == null) return 'Enter a valid number';
                            if (n <= 0) return 'Price must be > 0';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 16),

                        // Negotiable
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.handshake_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Price negotiable',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Switch.adaptive(
                                  value: controller.negotiable.value,
                                  onChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    controller.negotiable.value = v;
                                    _markDirty();
                                  },
                                  activeColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description Section
                        _buildSectionHeader(
                          Icons.description_rounded,
                          'Description',
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: controller.descriptionController,
                          maxLength: 500,
                          maxLines: 4,
                          decoration: _inputDeco(
                            label: 'Description *',
                            hint:
                                'Describe condition, features, included items, and delivery options',
                            icon: Icons.notes_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter description'
                              : v.trim().length < 10
                                  ? 'Description must be at least 10 characters'
                                  : null,
                          textInputAction: TextInputAction.newline,
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: Obx(() {
                            final loading =
                                controller.isLoadingMarketplace.value;
                            return ElevatedButton(
                              onPressed: loading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                                shadowColor:
                                    AppColors.primary.withOpacity(0.3),
                              ),
                              child: Text(
                                loading
                                    ? 'Please wait…'
                                    : (isEditing
                                        ? 'Update Product'
                                        : 'Add Product'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay
            Obx(() {
              if (!controller.isLoadingMarketplace.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 3),
                            SizedBox(height: 16),
                            Text(
                              'Processing...',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/* ======================= Enhanced Header Image ======================= */

class _EnhancedHeaderImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _EnhancedHeaderImage({
    required this.imageUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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

              // Gradient overlay when image exists
              if (hasImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

              // Add/Change button
              Positioned(
                top: 12,
                right: 12,
                child: _EnhancedActionChip(
                  icon: hasImage ? Icons.edit_rounded : Icons.add_photo_alternate_rounded,
                  label: hasImage ? 'Change' : 'Add Photo',
                  onTap: onPick,
                  color: AppColors.primary,
                ),
              ),

              // Remove button
              if (onRemove != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _EnhancedActionChip(
                    icon: Icons.delete_rounded,
                    label: 'Remove',
                    onTap: onRemove!,
                    color: AppColors.error,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: AppColors.subtitle.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Add Product Image',
            style: TextStyle(
              color: AppColors.subtitle.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Photo" to upload',
            style: TextStyle(
              color: AppColors.subtitle.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _EnhancedActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

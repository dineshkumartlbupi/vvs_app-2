import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vvs_app/screens/child_screens/marketplace/controllers/marketplace_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class ProductPostScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  final String docId;

  const ProductPostScreen({super.key, required this.existingData, required this.docId});

  @override
  State<ProductPostScreen> createState() => _ProductPostScreenState();
}

class _ProductPostScreenState extends State<ProductPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceController controller = Get.put(MarketplaceController());

  @override
  void initState() {
    super.initState();
    controller.initializeForm(widget.existingData);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    controller.isLoadingMarketplace.value = true;
    final file = File(picked.path);
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final ref = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      controller.imageUrl.value = downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      controller.isLoadingMarketplace.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.docId.isEmpty ? 'Add New Product' : 'Edit Product';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.background,
      body: Obx(() => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTitle(title),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: controller.imageUrl.value.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              controller.imageUrl.value,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                              color: Colors.grey[100],
                            ),
                            alignment: Alignment.center,
                            child: const Text('Tap to upload image'),
                          ),
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.nameController,
                    label: 'Product Name',
                    validator: (v) => v == null || v.isEmpty ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: controller.priceController,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter price';
                      if (double.tryParse(v) == null) return 'Enter valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: controller.descriptionController,
                    label: 'Description',
                    validator: (v) => v == null || v.isEmpty ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 24),
                  controller.isLoadingMarketplace.value
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: 'Submit',
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              controller.submitProduct(
                                context: context,
                                docId: widget.docId,
                              );
                            }
                          },
                        ),
                ],
              ),
            ),
          )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';
import '../controllers/marketplace_controller.dart';
import 'ProductDetailScreen.dart';
import 'ProductPostScreen.dart';

class MarketPlaceScreen extends StatefulWidget {
  const MarketPlaceScreen({super.key});

  @override
  State<MarketPlaceScreen> createState() => _MarketPlaceScreenState();
}

class _MarketPlaceScreenState extends State<MarketPlaceScreen> {
  final _searchController = TextEditingController();
  late final MarketplaceController controller;

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketplaceController(), permanent: true);
    controller.fetchProducts();
    _searchController.addListener(() {
      controller.searchQuery.value = _searchController.text
          .trim()
          .toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Not logged in')));

    return Obx(() {
      if (controller.isLoadingMarketplace.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final products = controller.filteredProducts;

      return Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppInput(
                controller: _searchController,
                label: 'Search products...',
                prefixIcon: Icons.search_rounded,
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final raw = doc.data();
                        final data = raw != null
                            ? Map<String, dynamic>.from(raw)
                            : <String, dynamic>{};

                        final imageUrl = (data['imageUrl'] ?? '').toString();
                        final title = _cap(
                          (data['name'] ?? 'Untitled').toString(),
                        );
                        final description = (data['description'] ?? '')
                            .toString();
                        final category = (data['category'] ?? 'Uncategorized')
                            .toString();
                        final qtyRaw = data['quantity'];
                        final qty = (qtyRaw is num)
                            ? qtyRaw.toInt()
                            : int.tryParse((qtyRaw ?? '').toString());
                        final qtyText = qty != null ? '$qty' : '-';

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: data),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image (with placeholder)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    color: Colors.black.withOpacity(0.04),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const _ImgFallback(),
                                            loadingBuilder:
                                                (ctx, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  return const _ImgFallback();
                                                },
                                          )
                                        : const _ImgFallback(),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Texts
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Description
                                      Text(
                                        description.isEmpty
                                            ? 'No description provided.'
                                            : description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Category + Quantity
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _metaChip(
                                            icon: Icons.category_rounded,
                                            text: category.isEmpty
                                                ? 'Uncategorized'
                                                : category,
                                          ),
                                          _metaChip(
                                            icon: Icons.onetwothree_rounded,
                                            text: 'Qty: $qtyText',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Admin actions
                                if (controller.isAdmin.value) ...[
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _miniAction(
                                        label: 'Edit',
                                        color: Colors.blue,
                                        onTap: () {
                                          controller.initializeForm(data);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductPostScreen(
                                                existingData: data,
                                                docId: doc.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      _miniAction(
                                        label: 'Delete',
                                        color: Colors.red,
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                'Delete Product',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this product?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true)
                                            controller.deleteProduct(doc.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: controller.isAdmin.value
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: AppColors.card),
                onPressed: () {
                  controller.initializeForm({});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProductPostScreen(existingData: {}, docId: ''),
                    ),
                  );
                },
              )
            : null,
      );
    });
  }

  Widget _metaChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Colors.black38),
    );
  }
}

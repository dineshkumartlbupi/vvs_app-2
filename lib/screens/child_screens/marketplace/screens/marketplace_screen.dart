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

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketplaceController(), permanent: true);

    controller.fetchProducts(); // Explicitly fetch all products

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
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Obx(() {
      if (controller.isLoadingMarketplace.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final products = controller.filteredProducts;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Marketplace"),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppInput(
                controller: _searchController,
                label: 'Search products...',
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
                        final name = (data['name'] ?? 'Unnamed Product')
                            .toString();
                        final price = data['price'] != null
                            ? '₹${data['price']}'
                            : 'Price not set';

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
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        price,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (controller.isAdmin.value)
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
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
                                        icon: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text("Edit"),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
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

                                          if (confirm == true) {
                                            controller.deleteProduct(doc.id);
                                          }
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text("Delete"),
                                        ),
                                      ),
                                    ],
                                  ),
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vvs_app/constants/app_strings.dart';
import 'package:vvs_app/services/fire_store_services.dart';

class MarketplaceController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // Data / state
  RxList<QueryDocumentSnapshot<Map<String, dynamic>>> productList =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  RxBool isLoadingMarketplace = true.obs;
  RxString searchQuery = ''.obs;
  RxBool isAdmin = false.obs;

  // Base fields
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  RxString imageUrl = ''.obs;

  // Extra fields
  final qtyController = TextEditingController(text: '1');

  // Selectors
  final RxString category = ''.obs;          // required
  final RxString condition = 'New'.obs;      // required
  final RxBool negotiable = false.obs;       // optional

  // NEW: Units selector
  final List<String> units = <String>[
    'pcs', 'box', 'set', 'kg', 'g', 'litre', 'ml', 'meter', 'cm'
  ];
  final RxString unit = ''.obs;              // required

  // Options
  final List<String> categories = <String>[
    'Mobiles & Tablets',
    'Electronics',
    'Home & Furniture',
    'Vehicles',
    'Appliances',
    'Fashion',
    'Books',
    'Services',
    'Other',
  ];
  final List<String> conditions = <String>['New', 'Like New', 'Good', 'Fair'];

  @override
  void onInit() {
    super.onInit();
    fetchUserRole();
    fetchProducts();
  }

  /* ========================= Role & Data ========================= */

  void fetchUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isAdmin.value = false;
      return;
    }

    _firestoreService
        .listenToDocument(collection: 'users', docId: user.uid)
        .listen((doc) {
      final data = doc.data();
      isAdmin.value = (data?['role'] == 'admin');
    });
  }

  void fetchProducts() {
    try {
      _firestoreService
          .listenToCollection(collection: CollectionConstants.MarketPlaceCollection)
          .listen((snapshot) {
        productList.value = snapshot.docs;
        isLoadingMarketplace.value = false;
        debugPrint(
          '✅ Fetched ${snapshot.docs.length} products from ${CollectionConstants.MarketPlaceCollection}.',
        );
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching products: $e');
      debugPrint('🛠 StackTrace: $stackTrace');
      isLoadingMarketplace.value = false;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get filteredProducts {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return productList;

    return productList.where((doc) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final cat = (data['category'] ?? '').toString().toLowerCase();
      // optional: include unit in search
      final u = (data['units'] ?? '').toString().toLowerCase();

      return name.contains(q) ||
          cat.contains(q) ||
          u.contains(q);
    }).toList();
  }

  /* ========================= Form Bindings ========================= */

  void initializeForm(Map<String, dynamic> existingData) {
    nameController.text        = (existingData['name'] ?? '').toString();
    priceController.text       = (existingData['price'] ?? '').toString();
    descriptionController.text = (existingData['description'] ?? '').toString();
    imageUrl.value             = (existingData['imageUrl'] ?? '').toString();

    qtyController.text      = ((existingData['quantity'] ?? 1).toString());

    final cat = (existingData['category'] ?? '').toString();
    if (cat.isNotEmpty && !categories.contains(cat)) categories.add(cat);
    category.value = cat;

    final cond = (existingData['condition'] ?? 'New').toString();
    if (cond.isNotEmpty && !conditions.contains(cond)) conditions.add(cond);
    condition.value = cond.isEmpty ? 'New' : cond;

    negotiable.value = (existingData['negotiable'] ?? false) == true;

    // NEW: restore selected units (if any)
    final savedUnit = (existingData['units'] ?? '').toString();
    if (savedUnit.isNotEmpty && !units.contains(savedUnit)) units.add(savedUnit);
    unit.value = savedUnit;
  }

  /* ========================= Submit / Delete ========================= */

  Future<void> submitProduct({
    required BuildContext context,
    required String docId,
  }) async {
    // Validate required fields
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final desc = descriptionController.text.trim();
    final qtyText = qtyController.text.trim();
    final cat = category.value.trim();
    final cond = condition.value.trim();
    final unitsSelected = unit.value.trim();

    if (name.isEmpty ||
        priceText.isEmpty ||
        desc.isEmpty ||
        imageUrl.value.isEmpty ||
        qtyText.isEmpty ||
        cat.isEmpty ||
        cond.isEmpty ||
        unitsSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    final qty = int.tryParse(qtyText);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price (> 0).')),
      );
      return;
    }
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity (> 0).')),
      );
      return;
    }

    final data = <String, dynamic>{
      'name'       : name,
      'price'      : price,
      'description': desc,
      'imageUrl'   : imageUrl.value,
      'category'   : cat,
      'condition'  : cond,
      'quantity'   : qty,
      'units'      : unitsSelected,      // ✅ save units
      'negotiable' : negotiable.value,
      'updatedAt'  : FieldValue.serverTimestamp(),
    };

    try {
      if (docId.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestoreService.addDocument(
          collection: CollectionConstants.MarketPlaceCollection, data: data);
      } else {
        await _firestoreService.updateDocument(
          collection: CollectionConstants.MarketPlaceCollection, docId: docId, data: data);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(docId.isEmpty ? 'Product added!' : 'Product updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> deleteProduct(String docId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: CollectionConstants.MarketPlaceCollection, docId: docId);
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }

  /* ========================= Cleanup ========================= */

  @override
  void onClose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    qtyController.dispose();
    super.onClose();
  }
}

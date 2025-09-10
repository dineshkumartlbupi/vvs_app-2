import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vvs_app/constants/app_strings.dart';
import 'package:vvs_app/services/fire_store_services.dart';

class MarketplaceController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  RxList<QueryDocumentSnapshot<Map<String, dynamic>>> productList = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  RxBool isLoadingMarketplace = true.obs;
  RxString searchQuery = ''.obs;
  RxBool isAdmin = false.obs;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  RxString imageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserRole();
    fetchProducts();
  }

  // Retrieve user role
  void fetchUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isAdmin.value = false;
      return;
    }

    _firestoreService.listenToDocument(collection: 'users', docId: user.uid).listen((doc) {
      final data = doc.data();
      isAdmin.value = (data?['role'] == 'admin');
    });
  }

  // Listen to product collection
  void fetchProducts() {
  try {
    print("hhhhhhhhhhhhhhhhhhhhhhh",);
    _firestoreService.listenToCollection(collection: CollectionConstants.MarketPlaceCollection).listen((snapshot) {
      productList.value = snapshot.docs;
      isLoadingMarketplace.value = false;

      // Debug print to confirm product count
      debugPrint('✅ Fetched ${snapshot.docs.length} products from ${CollectionConstants.MarketPlaceCollection}.');
    });
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching products: $e');
    debugPrint('🛠 StackTrace: $stackTrace');
    isLoadingMarketplace.value = false;
  }
}


  List<QueryDocumentSnapshot<Map<String, dynamic>>> get filteredProducts {
    final query = searchQuery.value;
    if (query.isEmpty) return productList;
    return productList.where((doc) {
      final name = (doc.data()['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void initializeForm(Map<String, dynamic> existingData) {
    nameController.text = existingData['name'] ?? '';
    priceController.text = existingData['price']?.toString() ?? '';
    descriptionController.text = existingData['description'] ?? '';
    imageUrl.value = existingData['imageUrl'] ?? '';
  }

  Future<void> submitProduct({
    required BuildContext context,
    required String docId,
  }) async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        imageUrl.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    final data = {
      'name': nameController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'description': descriptionController.text.trim(),
      'imageUrl': imageUrl.value,
      'createdAt': FieldValue.serverTimestamp(),
      
    };

    try {
      if (docId.isEmpty) {
        await _firestoreService.addDocument(collection: CollectionConstants.MarketPlaceCollection, data: data);
      } else {
        await _firestoreService.updateDocument(collection: CollectionConstants.MarketPlaceCollection, docId: docId, data: data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(docId.isEmpty ? 'Product added!' : 'Product updated!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> deleteProduct(String docId) async {
    try {
      await _firestoreService.deleteDocument(collection: CollectionConstants.MarketPlaceCollection, docId: docId);
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }
}

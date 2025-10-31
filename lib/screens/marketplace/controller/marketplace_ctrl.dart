import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:vvs_app/services/fire_store_services.dart';

class MarketplaceCtrl extends GetxController {
/// Category -> Subcategory map (can be moved to Firestore later)
  /// Keys are category names, values are list of available subcategories.
  final Map<String, List<String>> categoriesMap = {
    'Healthcare': ['Hospital', 'Clinic', 'Pharmacy', 'Diagnostic'],
    'Education': ['College', 'Coaching Center', 'Tuition', 'Training Institute'],
    'Retail': ['Grocery', 'Clothing', 'Electronics', 'Home & Furniture'],
    'Automotive': ['Car Dealer', 'Bike Dealer', 'Service & Repair'],
    'Food & Dining': ['Restaurant', 'Cafe', 'Bakery'],
    'Services': ['Salon', 'Tailor', 'Plumber', 'Electrician'],
    'Other': ['Other'],
  };

  // Flattened category list used in dropdowns (keeps your previous categories too)
  List<String> get categories => categoriesMap.keys.toList();

  // Reactive selection
  final RxString category = ''.obs;
  final RxString subcategory = ''.obs;

  // Helper to get subcategories for a category
  List<String> subcategoriesFor(String cat) {
    return categoriesMap[cat] ?? ['Other'];
  }


  final FirestoreService _firestoreService = FirestoreService();
  // Data / state
  RxList<QueryDocumentSnapshot<Map<String, dynamic>>> productList =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  RxBool isLoadingMarketplace = true.obs;
  RxString searchQuery = ''.obs;
  RxBool isAdmin = false.obs;

  // Base fields
  RxString imageUrl = ''.obs;




}

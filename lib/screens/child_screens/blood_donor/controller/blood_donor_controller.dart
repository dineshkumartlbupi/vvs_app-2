import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BloodDonorController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Info
  RxString name = ''.obs;
  RxString email = ''.obs;
  RxString mobile = ''.obs;
  RxString location = ''.obs;
  RxString bloodGroup = ''.obs;

  // Optional stored fields in user profile
  RxInt age = 18.obs;
  RxInt weight = 50.obs;

  // UI / loading state
  RxBool isLoading = false.obs;

  // Donors list
  RxList<QueryDocumentSnapshot<Map<String, dynamic>>> allDonors =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  // For filtering if needed
  RxList<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDonors =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  // selected blood group for filtering
  RxString selectedBloodGroup = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUserData();
    fetchDonors();
    ever(selectedBloodGroup, (_) => applyFilter());
  }

  /// Fetch current user's profile data from 'users' collection
  Future<void> fetchCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        name.value = data['name'] ?? '';
        email.value = data['email'] ?? '';
        mobile.value = data['mobile'] ?? '';
        location.value = data['address'] ?? '';
        bloodGroup.value = data['bloodGroup'] ?? 'A+';

        // If your user profile stores age / weight, use them
        age.value = int.tryParse(data['age']?.toString() ?? '') ?? age.value;
        weight.value = int.tryParse(data['weight']?.toString() ?? '') ?? weight.value;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Prefill controllers when form is opened
  void prefillFormControllers({
    required TextEditingController nameCtrl,
    required TextEditingController ageCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController locationCtrl,
    required TextEditingController bloodGroupCtrl,
  }) {
    nameCtrl.text = name.value;
    phoneCtrl.text = mobile.value;
    emailCtrl.text = email.value;
    locationCtrl.text = location.value;
    ageCtrl.text = age.value.toString();
    bloodGroupCtrl.text = bloodGroup.value;
  }

  /// Check if current user is already in donors
  Future<bool> isAlreadyDonor() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('donors').doc(user.uid).get();
    return doc.exists;
  }

  /// Add donor
  Future<void> addDonor({
    required String name,
    required int age,
    required int weight,
    required String mobile,
    required String email,
    required String location,
    required String bloodGroup,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Check if already donor
    final already = await isAlreadyDonor();
    if (already) {
      throw AlreadyDonorException();
    }

    final donorData = {
      'uid': user.uid,
      'name': name,
      'age': age,
      'weight': weight,
      'mobile': mobile,
      'email': email,
      'location': location,
      'bloodGroup': bloodGroup,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('donors').doc(user.uid).set(donorData);
    // Optionally refresh donor list
    await fetchDonors();
  }

  /// Fetch all donors
  Future<void> fetchDonors() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore.collection('donors').get();
      allDonors.value = snapshot.docs;
      applyFilter();
    } catch (e) {
      print('Error fetching donors: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter donors by selectedBloodGroup if set
  void applyFilter() {
    if (selectedBloodGroup.value.isEmpty) {
      filteredDonors.value = allDonors;
    } else {
      filteredDonors.value = allDonors.where((doc) {
        final d = doc.data();
        return (d['bloodGroup'] ?? '') == selectedBloodGroup.value;
      }).toList();
    }
  }
}

/// Custom Exception when user is already donor
class AlreadyDonorException implements Exception {
  @override
  String toString() => "You are already registered as a donor.";
}

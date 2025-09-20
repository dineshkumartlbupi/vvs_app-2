import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileController extends GetxController {
  final nameC = TextEditingController();
  final mobileC = TextEditingController();
  final addressC = TextEditingController();
  final bgC = TextEditingController();
  final samajC = TextEditingController();
  final aadhaarC = TextEditingController();
  final dobC = TextEditingController();
  final genderC = TextEditingController();
  final maritalStatusC = TextEditingController();
  final fatherHusbandNameC = TextEditingController();
  final qualificationC = TextEditingController();
  final occupationC = TextEditingController();
  final professionC = TextEditingController();

  final isLoading = false.obs;
  final photoUrl = ''.obs;
  File? imageFile;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> fetchUserData() async {
    if (user == null) return;
    isLoading.value = true;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final d = doc.data();

    if (d != null) {
      nameC.text = d['name'] ?? '';
      mobileC.text = d['mobile'] ?? '';
      addressC.text = d['address'] ?? '';
      bgC.text = d['bloodGroup'] ?? '';
      samajC.text = d['samaj'] ?? '';
      aadhaarC.text = d['aadhaarNumber'] ?? '';
      dobC.text = d['dob'] ?? '';
      genderC.text = d['gender'] ?? '';
      maritalStatusC.text = d['maritalStatus'] ?? '';
      fatherHusbandNameC.text = d['fatherHusbandName'] ?? '';
      qualificationC.text = d['qualification'] ?? '';
      occupationC.text = d['occupation'] ?? '';
      professionC.text = d['profession'] ?? '';
      photoUrl.value = d['photoUrl'] ?? '';
    }

    isLoading.value = false;
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      imageFile = File(picked.path);
      update();
    }
  }

  Future<String?> uploadImage(String uid) async {
    if (imageFile == null) return photoUrl.value;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      final snapshot = await ref.putFile(imageFile!);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }

  Future<void> saveProfile() async {
    if (user == null) return;
    isLoading.value = true;

    final imageUrl = await uploadImage(user!.uid);

    final updates = {
      'name': nameC.text.trim(),
      'mobile': mobileC.text.trim(),
      'address': addressC.text.trim(),
      'bloodGroup': bgC.text.trim(),
      'samaj': samajC.text.trim(),
      'aadhaarNumber': aadhaarC.text.trim(),
      'dob': dobC.text.trim(),
      'gender': genderC.text.trim(),
      'maritalStatus': maritalStatusC.text.trim(),
      'fatherHusbandName': fatherHusbandNameC.text.trim(),
      'qualification': qualificationC.text.trim(),
      'occupation': occupationC.text.trim(),
      'profession': professionC.text.trim(),
      if (imageUrl != null) 'photoUrl': imageUrl,
    };

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(updates);
    isLoading.value = false;
  }

  @override
  void onClose() {
    nameC.dispose();
    mobileC.dispose();
    addressC.dispose();
    bgC.dispose();
    samajC.dispose();
    aadhaarC.dispose();
    dobC.dispose();
    genderC.dispose();
    maritalStatusC.dispose();
    fatherHusbandNameC.dispose();
    qualificationC.dispose();
    occupationC.dispose();
    professionC.dispose();
    super.onClose();
  }
}

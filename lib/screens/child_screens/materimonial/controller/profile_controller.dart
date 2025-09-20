import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Map<String, dynamic>> profiles = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfiles();
    checkProfileExists();
  }

  Stream<QuerySnapshot> fetchProfilesStream() {
    return _firestore
        .collection('profiles')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void fetchProfiles() {
    isLoading.value = true;
    fetchProfilesStream().listen((snapshot) {
      profiles.value =
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      isLoading.value = false;
    }, onError: (err) {
      isLoading.value = false;
    });
  }

  Future<String?> uploadImage(File image) async {
    final fileName = "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = _storage.ref().child('profiles/$fileName');
    final uploadTask = await ref.putFile(image);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  Future<void> addProfile({
    required String name,
    required String profession,
    required String address,
    required String bio,
    required String photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      'uid': user.uid,
      'name': name,
      'profession': profession,
      'address': address,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('profiles').add(data);
    hasProfile.value = true;
  }

  Future<void> checkProfileExists() async {
    final user = _auth.currentUser;
    if (user == null) {
      hasProfile.value = false;
      return;
    }

    final query = await _firestore
        .collection('profiles')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    hasProfile.value = query.docs.isNotEmpty;
  }
}

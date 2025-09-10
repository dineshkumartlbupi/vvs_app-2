import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:vvs_app/services/fire_store_services.dart';
class NewsBulletinController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();


  final RxBool isAdmin = false.obs;
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> newsList = <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;
  final RxBool isLoading = true.obs;

  final String userCollection = 'users';
  final String newsCollection = 'news';

  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    _fetchUserRole();
    _fetchNews();
  }

  void _fetchUserRole() {
    if (currentUser == null) return;

    _firestoreService
      .listenToDocument(collection: userCollection, docId: currentUser!.uid)
      .listen((doc) {
        final data = doc.data();
        isAdmin.value = (data?['role'] == 'admin');
      });
  }

  void _fetchNews() {
    _firestoreService
      .listenToCollection(collection: newsCollection)
      .listen((snapshot) {
        newsList.assignAll(snapshot.docs);
        isLoading.value = false;
      });
  }

  Future<void> deleteNews(String docId) async {
    await _firestoreService.deleteDocument(collection: newsCollection, docId: docId);
  }

  Future<void> postNews({
    required String title,
    required String content,
    required String imageUrl,
  }) async {
    await _firestoreService.addDocument(collection: newsCollection, data: {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNews({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestoreService.updateDocument(collection: newsCollection, docId: docId, data: data);
  }
}

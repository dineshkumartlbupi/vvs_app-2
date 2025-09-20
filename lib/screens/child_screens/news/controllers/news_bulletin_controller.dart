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
    print('[NewsBulletinController] onInit called');
    _fetchUserRole();
    _fetchNews();
  }

  void _fetchUserRole() {
    print('[NewsBulletinController] Fetching user role...');
    if (currentUser == null) {
      print('[NewsBulletinController] No current user found.');
      return;
    }

    _firestoreService
        .listenToDocument(collection: userCollection, docId: currentUser!.uid)
        .listen((doc) {
      final data = doc.data();
      print('[NewsBulletinController] User data: $data');
      isAdmin.value = (data?['role'] == 'admin');
      print('[NewsBulletinController] isAdmin updated: ${isAdmin.value}');
    });
  }

  void _fetchNews() {
    print('[NewsBulletinController] Fetching news list...');
    _firestoreService.listenToCollection(collection: newsCollection).listen((snapshot) {
      newsList.assignAll(snapshot.docs);
      isLoading.value = false;
      print('[NewsBulletinController] News list updated with ${snapshot.docs} items');
    });
  }

  Future<void> deleteNews(String docId) async {
    print('[NewsBulletinController] Deleting news docId: $docId');
    await _firestoreService.deleteDocument(collection: newsCollection, docId: docId);
    print('[NewsBulletinController] Deleted news docId: $docId');
  }

  Future<void> postNews({
    required String title,
    required String content,
    required String imageUrl,
  }) async {
    print('[NewsBulletinController] Posting news: title=$title');
    await _firestoreService.addDocument(collection: newsCollection, data: {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('[NewsBulletinController] Posted news: title=$title');
  }

  Future<void> updateNews({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    print('[NewsBulletinController] Updating news docId: $docId with data: $data');
    await _firestoreService.updateDocument(collection: newsCollection, docId: docId, data: data);
    print('[NewsBulletinController] Updated news docId: $docId');
  }
}

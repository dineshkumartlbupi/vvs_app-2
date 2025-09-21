import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NewsBulletinController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isAdmin = false.obs;

  /// We keep original snapshots so you still have access to doc.id etc.
  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> newsList =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  User? get currentUser => _auth.currentUser;

  StreamSubscription? _userSub;
  StreamSubscription? _newsSub;

  @override
  void onInit() {
    super.onInit();
    _watchUserRole();
    _watchNews();
  }

  void _watchUserRole() {
    final uid = currentUser?.uid;
    if (uid == null) {
      isAdmin.value = false;
      return;
    }
    _userSub?.cancel();
    _userSub = _db.collection('users').doc(uid).snapshots().listen((doc) {
      isAdmin.value = (doc.data()?['role'] == 'admin');
    }, onError: (_) {
      isAdmin.value = false;
    });
  }

  void _watchNews() {
    _newsSub?.cancel();
    isLoading.value = true;
    error.value = null;

    _newsSub = _db.collection('news').snapshots().listen((snap) {
      final docs = snap.docs.toList();

      // Sort by 'timestamp' OR 'createdAt' descending
      docs.sort((a, b) {
        final ad = _extractDate(a.data());
        final bd = _extractDate(b.data());
        return bd.compareTo(ad);
      });

      newsList.assignAll(docs);
      isLoading.value = false;
    }, onError: (e) {
      error.value = e.toString();
      isLoading.value = false;
    });
  }

  /// Pull-to-refresh (one-shot fetch)
  Future<void> refreshNews() async {
    try {
      final snap = await _db.collection('news').get();
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final ad = _extractDate(a.data());
        final bd = _extractDate(b.data());
        return bd.compareTo(ad);
      });
      newsList.assignAll(docs);
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteNews(String docId) async {
    await _db.collection('news').doc(docId).delete();
  }

  Future<void> postNews({
    required String title,
    required String content,
    required String imageUrl,
  }) async {
    await _db.collection('news').add({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(), // preferred field
    });
  }

  Future<void> updateNews({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('news').doc(docId).update(data);
  }

  static DateTime _extractDate(Map<String, dynamic> m) {
    final raw = m['timestamp'] ?? m['createdAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      final p = DateTime.tryParse(raw);
      if (p != null) return p;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void onClose() {
    _userSub?.cancel();
    _newsSub?.cancel();
    super.onClose();
  }
}

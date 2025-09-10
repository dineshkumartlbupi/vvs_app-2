import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCollection({
    required String collection,
    String orderByField = 'createdAt',
    bool descending = true,
  }) {
    return _firestore
        .collection(collection)
        .orderBy(orderByField, descending: descending)
        .snapshots();
  }

  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<void> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).add(data);
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/constants/app_strings.dart';

class FamilyController {
  static Stream<QuerySnapshot> getFamilyMembersStream() {
    return FirebaseFirestore.instance
        .collection('family_members')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> saveMember({
    required BuildContext context,
    required String name,
    required String relation,
    required String age,
    required String dob,
    required String? gender,
    required String? maritalStatus,
    required String occupation,
    required String qualification,
    required String profession,
    required String email,
    required String mobile,
    required String address,
    required String bloodGroup,
    required String aadhaarNumber,
  }) async {
    await FirebaseFirestore.instance
        .collection(CollectionConstants.FamilyCollection)
        .add({
          'name': name.trim(),
          'relation': relation.trim(),
          'age': int.tryParse(age.trim()) ?? 0,
          'dob': dob.trim(),
          'gender': gender,
          'maritalStatus': maritalStatus,
          'occupation': occupation.trim(),
          'qualification': qualification.trim(),
          'profession': profession.trim(),
          'email': email.trim(),
          'mobile': mobile.trim(),
          'address': address.trim(),
          'bloodGroup': bloodGroup.trim(),
          'aadhaarNumber': aadhaarNumber.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Member saved')));
  }

  static Future<void> updateMember(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (docId.isEmpty) throw ArgumentError('docId is required');

    // Ensure we don't overwrite server timestamps if caller already set them
    final now = DateTime.now();
    final updateData = Map<String, dynamic>.from(data);
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    updateData['updatedBy'] = FirebaseAuth.instance.currentUser?.uid;

    // Convert numeric fields if needed (age may be string)
    if (updateData.containsKey('age')) {
      final ageVal = updateData['age'];
      if (ageVal is String) {
        updateData['age'] = int.tryParse(ageVal.trim()) ?? 0;
      } // if already int, leave as-is
    }

    await FirebaseFirestore.instance
        .collection(CollectionConstants.FamilyCollection)
        .doc(docId)
        .update(updateData);
  }
}

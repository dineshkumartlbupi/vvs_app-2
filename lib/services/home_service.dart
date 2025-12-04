// lib/services/home_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> fetchQuickStats() async {
    try {
      final members = await _firestore.collection('users').count().get();
      final families = await _firestore.collection('family_members').count().get();
      final donors = await _firestore.collection('donors').count().get();
      final events = await _firestore.collection('events').count().get();
      return {
        'members': members.count!,
        'families': families.count!,
        'donors': donors.count!,
        'events': events.count!,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {
        'members': 0,
        'families': 0,
        'donors': 0,
        'events': 0,
      };
    }
  }
}

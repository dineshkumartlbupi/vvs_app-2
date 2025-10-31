// lib/services/chat_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;

/// ChatService — Realtime Database backed chat helpers
class ChatService {
  static final rtdb.DatabaseReference _db = rtdb.FirebaseDatabase.instance.ref();
  static String get uuid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Build deterministic conversation id from two UIDs
  static String conversationIdFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Ensure conversation index for both users exists and update meta (lastMessage/time)
  static Future<void> ensureConversation({
    required String peerId,
    required String peerName,
    String? peerPhoto,
    String? initialMessage,
  }) async {
    final uid = uuid;
    if (uid.isEmpty) throw Exception('Not authenticated');

    final cid = conversationIdFor(uid, peerId);
    final ts = rtdb.ServerValue.timestamp;

    // create or update minimal conversation entries under /user_conversations/{uid}/{peerId}
    final updates = <String, dynamic>{};

    updates['/user_conversations/$uid/$peerId'] = {
      'conversationId': cid,
      'peerId': peerId,
      'peerName': peerName,
      'peerPhoto': peerPhoto ?? '',
      'lastMessage': initialMessage ?? '',
      'timestamp': ts,
    };

    // mirrored for peer's index so they can see the conversation
    updates['/user_conversations/$peerId/$uid'] = {
      'conversationId': cid,
      'peerId': uid,
      'peerName': FirebaseAuth.instance.currentUser?.displayName ?? '',
      'peerPhoto': FirebaseAuth.instance.currentUser?.photoURL ?? '',
      'lastMessage': initialMessage ?? '',
      'timestamp': ts,
    };

    await _db.update(updates);
  }

  /// Send message: pushes under /messages/{conversationId}/
  static Future<void> sendMessage({
    required String peerId,
    required String text,
  }) async {
    final uid = uuid;
    if (uid.isEmpty) throw Exception('Not authenticated');
    final cid = conversationIdFor(uid, peerId);
    final msgRef = _db.child('messages').child(cid).push();
    final now = rtdb.ServerValue.timestamp;

    final payload = {
      'id': msgRef.key,
      'from': uid,
      'to': peerId,
      'text': text,
      'timestamp': now,
      'seen': false,
    };

    // push message and update both users' conversation meta with lastMessage / timestamp
    final updates = <String, dynamic>{};
    updates['/messages/$cid/${msgRef.key}'] = payload;
    updates['/user_conversations/$uid/$peerId/lastMessage'] = text;
    updates['/user_conversations/$uid/$peerId/timestamp'] = now;
    updates['/user_conversations/$peerId/$uid/lastMessage'] = text;
    updates['/user_conversations/$peerId/$uid/timestamp'] = now;

    await _db.update(updates);
  }

  /// Listen to messages stream for a conversation (Realtime Database Query)
  static rtdb.Query messagesQuery({required String peerId}) {
    final uid = uuid;
    final cid = conversationIdFor(uid, peerId);
    return _db.child('messages').child(cid).orderByChild('timestamp');
  }

  /// Provide stream of user conversations (for the current user)
  static rtdb.Query conversationsIndexQuery() {
    final uid = uuid;
    return _db.child('user_conversations').child(uid).orderByChild('timestamp');
  }

  /// Mark message as seen (optional)
  static Future<void> markMessageSeen({
    required String peerId,
    required String messageId,
  }) async {
    final uid = uuid;
    final cid = conversationIdFor(uid, peerId);
    await _db.child('messages').child(cid).child(messageId).update({'seen': true});
  }
}

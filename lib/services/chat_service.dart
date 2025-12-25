// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// দুই user এর মধ্যে conversation ID বের করে (না থাকলে তৈরি করে)
  static Future<String> getOrCreateConversation({
    required String otherUserId,
    String? postId,
    String? postTitle,
  }) async {
    final uid = _auth.currentUser!.uid;

    // পুরোনো conversation আছে কিনা চেক
    final q = await _firestore
        .collection('conversations')
        .where('userIds', arrayContains: uid)
        .get();

    for (final doc in q.docs) {
      final data = doc.data();
      final List userIds = data['userIds'] ?? [];
      if (userIds.contains(otherUserId)) {
        return doc.id; // পুরোনোটা ব্যবহার করো
      }
    }

    // না থাকলে নতুন তৈরি
    final ref = await _firestore.collection('conversations').add({
      'userIds': [uid, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastSenderId': uid,
      'lastAt': FieldValue.serverTimestamp(),
      'postId': postId,
      'postTitle': postTitle,
    });

    return ref.id;
  }

  /// current user এর সব conversation (list view এর জন্য)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamConversations() {
    final uid = _auth.currentUser!.uid;

    final query = _firestore
        .collection('conversations')
        .where('userIds', arrayContains: uid)
        .orderBy('lastAt', descending: true);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// নির্দিষ্ট conversation এর messages stream (chat screen এর জন্য)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamMessages(String conversationId) {
    final query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// message পাঠানো
  static Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final uid = _auth.currentUser!.uid;
    final now = FieldValue.serverTimestamp();

    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    await _firestore.runTransaction((txn) async {
      txn.set(msgRef, {
        'senderId': uid,
        'text': text.trim(),
        'createdAt': now,
        'type': 'text',
        'seenBy': [uid],
      });

      final convRef =
      _firestore.collection('conversations').doc(conversationId);
      txn.update(convRef, {
        'lastMessage': text.trim(),
        'lastSenderId': uid,
        'lastAt': now,
      });
    });
  }
}
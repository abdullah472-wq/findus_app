// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _messagesCol(String convId) {
    return _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages');
  }

  /// Get or create conversation between two users
  static Future<String> getOrCreateConversation({
    required String otherUserId,
    String? otherName,
    String? otherRole,
    String? otherImage,
    String? postId,
    String? postTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Login required');

    final currentUid = user.uid;

    // Deterministic conversation ID
    final ids = [currentUid, otherUserId]..sort();
    final convId = ids.join('_');

    final ref = _firestore.collection('conversations').doc(convId);
    final snap = await ref.get();

    if (!snap.exists) {
      final now = FieldValue.serverTimestamp();

      await ref.set({
        'id': convId,
        'participants': ids,
        'createdAt': now,
        'updatedAt': now,
        'lastMsg': '',
        'unread': 0,
        'postId': postId,
        'postTitle': postTitle,
        'userId': otherUserId,
        'name': otherName,
        'role': otherRole,
        'image': otherImage,
      });
    }

    return convId;
  }

  /// Stream all conversations for current user
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamConversations() {
    final uid = _auth.currentUser!.uid;

    final query = _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// Stream messages in a conversation
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamMessages(String conversationId) {
    final query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// Send text message
  static Future<void> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final uid = user.uid;

    await _messagesCol(conversationId).add({
      'text': trimmed,
      'senderId': uid,
      'createdAt': now,
      'type': 'text',
      'seenBy': [uid],
    });

    await _firestore.collection('conversations').doc(conversationId).set(
      {
        'lastMsg': trimmed,
        'updatedAt': now,
        'unread': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  /// Send image message
  static Future<void> sendImageMessage({
    required String conversationId,
    required String imageUrl,
    String? caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = FieldValue.serverTimestamp();
    final uid = user.uid;

    await _messagesCol(conversationId).add({
      'type': 'image',
      'imageUrl': imageUrl,
      'text': caption ?? '',
      'senderId': uid,
      'createdAt': now,
      'seenBy': [uid],
    });

    final previewText = caption?.isNotEmpty == true
        ? caption!
        : '📷 Sent an image';

    await _firestore.collection('conversations').doc(conversationId).set(
      {
        'lastMsg': previewText,
        'updatedAt': now,
        'unread': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  /// Reset unread counter
  static Future<void> resetUnread(String conversationId) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);

    await convRef.set(
      {'unread': 0},
      SetOptions(merge: true),
    );
  }

  /// Mark all messages as seen
  static Future<void> markAllAsSeen(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final unreadMessages = await _messagesCol(conversationId)
        .where('senderId', isNotEqualTo: uid)
        .get();

    final batch = _firestore.batch();

    for (var doc in unreadMessages.docs) {
      final data = doc.data();
      final seenBy = List<String>.from(data['seenBy'] ?? []);

      if (!seenBy.contains(uid)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([uid]),
          'seenAt_$uid': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    await resetUnread(conversationId);
  }

  /// Delete conversation for current user
  static Future<void> deleteConversation(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
      'deletedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Block user
  static Future<void> blockUser(String otherUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'blockedUsers': FieldValue.arrayUnion([otherUserId]),
    });
  }

  /// Check if user is blocked
  static Future<bool> isUserBlocked(String otherUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();
    final blockedUsers = List<String>.from(doc.data()?['blockedUsers'] ?? []);

    return blockedUsers.contains(otherUserId);
  }
}
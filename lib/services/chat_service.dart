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

  /// দুই user এর মধ্যে conversation ID বের করে (না থাকলে তৈরি করে)
  /// deterministic ID: uid ছোটটা আগে, তারপর uid বড়টা → uid1_uid2
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

    // নিজের সাথে চ্যাট করতে দিতে না চাইলে:
    // if (currentUid == otherUserId) {
    //   throw Exception('Cannot chat with yourself');
    // }

    // deterministic convId
    final ids = [currentUid, otherUserId]..sort();
    final convId = ids.join('_');

    final ref = _firestore.collection('conversations').doc(convId);
    final snap = await ref.get();

    if (!snap.exists) {
      final now = FieldValue.serverTimestamp();

      await ref.set({
        'id': convId,
        'participants': ids,        // rules + filter এর জন্য
        'createdAt': now,
        'updatedAt': now,
        'lastMsg': '',
        'unread': 0,
        'postId': postId,
        'postTitle': postTitle,

        // UI এর জন্য (current user এর perspective থেকে অন্য পাশের info)
        'userId': otherUserId,
        'name': otherName,
        'role': otherRole,
        'image': otherImage,
      });
    }

    return convId;
  }

  /// current user এর সব conversation (ConversationTab এর জন্য)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamConversations() {
    final uid = _auth.currentUser!.uid;

    final query = _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// নির্দিষ্ট conversation এর messages stream (ChatScreen এর জন্য)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamMessages(String conversationId) {
    final query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    return query.snapshots().map((snap) => snap.docs);
  }

  /// simple text message পাঠানো (ChatScreen-এর জন্য)
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
        // basic unread increment; চাইলে per-user unread logic implement করতে পারো
        'unread': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  /// transaction সহ message পাঠানো (যদি একসাথে read-modify-write দরকার হয়)
  static Future<void> sendMessageTx({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final uid = user.uid;

    final convRef =
    _firestore.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    await _firestore.runTransaction((txn) async {
      txn.set(msgRef, {
        'senderId': uid,
        'text': trimmed,
        'createdAt': now,
        'type': 'text',
        'seenBy': [uid],
      });

      final convSnap = await txn.get(convRef);
      final data = convSnap.data() as Map<String, dynamic>? ?? {};
      final currentUnread = (data['unread'] ?? 0) as int;

      txn.set(
        convRef,
        {
          'lastMsg': trimmed,
          'updatedAt': now,
          'unread': currentUnread + 1,
        },
        SetOptions(merge: true),
      );
    });
  }

  /// চ্যাট ওপেন করলে unread reset করার জন্য
  static Future<void> resetUnread(String conversationId) async {
    final convRef =
    _firestore.collection('conversations').doc(conversationId);

    await convRef.set(
      {'unread': 0},
      SetOptions(merge: true),
    );
  }
}
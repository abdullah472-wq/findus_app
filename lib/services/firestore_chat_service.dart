// lib/services/firestore_chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // 📁 COLLECTION REFERENCES
  // ════════════════════════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> _messagesCol(String convId) {
    return _db.collection('conversations').doc(convId).collection('messages');
  }

  static DocumentReference<Map<String, dynamic>> _conversationDoc(String convId) {
    return _db.collection('conversations').doc(convId);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💬 CREATE/GET CONVERSATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Get or create conversation with metadata
  static Future<String> getOrCreateConversation({
    required String otherUserId,
    String? otherUserName,
    String? otherUserImage,
    String? otherUserRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Login required');

    // Deterministic ID: smaller UID first
    final ids = [user.uid, otherUserId]..sort();
    final convId = ids.join('_');

    final ref = _conversationDoc(convId);
    final snap = await ref.get();

    if (!snap.exists) {
      // ✅ Fetch other user's data if not provided
      if (otherUserName == null || otherUserImage == null) {
        final otherUserDoc = await _db.collection('users').doc(otherUserId).get();
        final otherUserData = otherUserDoc.data() ?? {};

        otherUserName = otherUserData['name'] ?? 'User';
        otherUserImage = otherUserData['image'] ?? otherUserData['imageUrl'] ?? '';
        otherUserRole = otherUserData['role'] ?? otherUserData['userRole'] ?? 'User';
      }

      // ✅ Create conversation with metadata
      await ref.set({
        'id': convId,
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMsg': '',
        'lastMsgAt': null,
        'lastMsgBy': '',

        // ✅ Store other user's info for UI (from current user's perspective)
        'userId': otherUserId,
        'name': otherUserName,
        'image': otherUserImage,
        'role': otherUserRole,

        // ✅ Per-user unread counts
        'unreadCounts': {
          user.uid: 0,
          otherUserId: 0,
        },

        // ✅ Additional flags
        'isArchived': false,
        'isPinned': false,
        'isMuted': false,
        'deletedBy': [],
      });

      debugPrint("✅ New conversation created: $convId");
    }

    return convId;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📨 SEND MESSAGE
  // ════════════════════════════════════════════════════════════════════════════

  /// Send text message
  static Future<void> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final now = FieldValue.serverTimestamp();

    try {
      // ✅ 1. Add message
      await _messagesCol(conversationId).add({
        'text': trimmedText,
        'senderId': user.uid,
        'createdAt': now,
        'type': 'text',
        'seenBy': [user.uid],
        'status': 'sent',
      });

      // ✅ 2. Update conversation summary
      final convDoc = await _conversationDoc(conversationId).get();
      final convData = convDoc.data() ?? {};
      final participants = List<String>.from(convData['participants'] ?? []);

      // Find other user's ID
      final otherUserId = participants.firstWhere(
            (id) => id != user.uid,
        orElse: () => '',
      );

      await _conversationDoc(conversationId).update({
        'lastMsg': trimmedText,
        'lastMsgAt': now,
        'lastMsgBy': user.uid,
        'updatedAt': now,

        // ✅ Increment unread count for other user only
        'unreadCounts.${otherUserId}': FieldValue.increment(1),
      });

      debugPrint("✅ Message sent");
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
      rethrow;
    }
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

    try {
      // ✅ 1. Add message
      await _messagesCol(conversationId).add({
        'type': 'image',
        'imageUrl': imageUrl,
        'text': caption ?? '',
        'senderId': user.uid,
        'createdAt': now,
        'seenBy': [user.uid],
        'status': 'sent',
      });

      // ✅ 2. Update conversation
      final convDoc = await _conversationDoc(conversationId).get();
      final convData = convDoc.data() ?? {};
      final participants = List<String>.from(convData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
            (id) => id != user.uid,
        orElse: () => '',
      );

      final previewText = caption?.isNotEmpty == true ? caption! : '📷 Sent an image';

      await _conversationDoc(conversationId).update({
        'lastMsg': previewText,
        'lastMsgAt': now,
        'lastMsgBy': user.uid,
        'updatedAt': now,
        'unreadCounts.${otherUserId}': FieldValue.increment(1),
      });

      debugPrint("✅ Image message sent");
    } catch (e) {
      debugPrint("❌ Error sending image: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📖 READ RECEIPTS
  // ════════════════════════════════════════════════════════════════════════════

  /// Mark all messages as read
  static Future<void> markAllAsRead(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // ✅ 1. Get unread messages
      final unreadMessages = await _messagesCol(conversationId)
          .where('senderId', isNotEqualTo: user.uid)
          .get();

      final batch = _db.batch();

      // ✅ 2. Mark each message as seen
      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        final seenBy = List<String>.from(data['seenBy'] ?? []);

        if (!seenBy.contains(user.uid)) {
          batch.update(doc.reference, {
            'seenBy': FieldValue.arrayUnion([user.uid]),
            'seenAt_${user.uid}': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      // ✅ 3. Reset unread count
      await _conversationDoc(conversationId).update({
        'unreadCounts.${user.uid}': 0,
      });

      debugPrint("✅ All messages marked as read");
    } catch (e) {
      debugPrint("❌ Error marking as read: $e");
    }
  }

  /// Mark single message as read
  static Future<void> markMessageAsRead(
      String conversationId,
      String messageId,
      ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _messagesCol(conversationId).doc(messageId).update({
        'seenBy': FieldValue.arrayUnion([user.uid]),
        'seenAt_${user.uid}': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Message marked as read");
    } catch (e) {
      debugPrint("❌ Error marking message as read: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📡 STREAM DATA
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream all conversations for current user
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamConversations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .where('deletedBy', whereNotIn: [uid]) // Exclude deleted conversations
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Stream messages in a conversation
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamMessages(
      String conversationId,
      ) {
    return _messagesCol(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⌨️ TYPING INDICATOR
  // ════════════════════════════════════════════════════════════════════════════

  /// Set typing status
  static Future<void> setTyping(String conversationId, bool isTyping) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _conversationDoc(conversationId).update({
        'typing_$uid': isTyping,
        'typingAt_$uid': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Error setting typing status: $e");
    }
  }

  /// Get typing status of other user
  static Stream<bool> getOtherUserTypingStatus(
      String conversationId,
      String otherUserId,
      ) {
    return _conversationDoc(conversationId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return false;

      final isTyping = data['typing_$otherUserId'] == true;
      final typingAt = data['typingAt_$otherUserId'];

      // Check if typing was within last 5 seconds
      if (isTyping && typingAt is Timestamp) {
        final diff = DateTime.now().difference(typingAt.toDate());
        return diff.inSeconds < 5;
      }

      return false;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ DELETE/ARCHIVE
  // ════════════════════════════════════════════════════════════════════════════

  /// Delete conversation for current user (soft delete)
  static Future<void> deleteConversation(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _conversationDoc(conversationId).update({
        'deletedBy': FieldValue.arrayUnion([uid]),
      });

      debugPrint("✅ Conversation deleted");
    } catch (e) {
      debugPrint("❌ Error deleting conversation: $e");
      rethrow;
    }
  }

  /// Archive conversation
  static Future<void> archiveConversation(String conversationId) async {
    try {
      await _conversationDoc(conversationId).update({
        'isArchived': true,
      });

      debugPrint("✅ Conversation archived");
    } catch (e) {
      debugPrint("❌ Error archiving conversation: $e");
      rethrow;
    }
  }

  /// Pin/Unpin conversation
  static Future<void> togglePinConversation(
      String conversationId,
      bool isPinned,
      ) async {
    try {
      await _conversationDoc(conversationId).update({
        'isPinned': !isPinned,
      });

      debugPrint("✅ Conversation ${!isPinned ? 'pinned' : 'unpinned'}");
    } catch (e) {
      debugPrint("❌ Error toggling pin: $e");
      rethrow;
    }
  }

  /// Mute/Unmute conversation
  static Future<void> toggleMuteConversation(
      String conversationId,
      bool isMuted,
      ) async {
    try {
      await _conversationDoc(conversationId).update({
        'isMuted': !isMuted,
      });

      debugPrint("✅ Conversation ${!isMuted ? 'muted' : 'unmuted'}");
    } catch (e) {
      debugPrint("❌ Error toggling mute: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 SEARCH
  // ════════════════════════════════════════════════════════════════════════════

  /// Search conversations by name
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchConversations(
      String query,
      ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null || query.isEmpty) return Stream.value([]);

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      return snap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 ANALYTICS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get unread count for current user
  static Future<int> getUnreadCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    try {
      final conversations = await _db
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();

      int totalUnread = 0;
      for (var doc in conversations.docs) {
        final data = doc.data();
        final unreadCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
        totalUnread += (unreadCounts[uid] ?? 0) as int;
      }

      return totalUnread;
    } catch (e) {
      debugPrint("❌ Error getting unread count: $e");
      return 0;
    }
  }

  /// Stream total unread count
  static Stream<int> streamUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      int totalUnread = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        final unreadCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
        totalUnread += (unreadCounts[uid] ?? 0) as int;
      }
      return totalUnread;
    });
  }
}
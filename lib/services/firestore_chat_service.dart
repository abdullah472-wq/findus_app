// lib/services/firestore_chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _messagesCol(String convId) {
    return _db.collection('conversations').doc(convId).collection('messages');
  }

  // মেসেজ পাঠানো
  static Future<void> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = FieldValue.serverTimestamp();

    // ১. মেসেজ অ্যাড করা
    await _messagesCol(conversationId).add({
      'text': text,
      'senderId': user.uid,
      'createdAt': now,
    });

    // ২. কনভারসেশন সামারি আপডেট (চ্যাট লিস্টের জন্য)
    await _db.collection('conversations').doc(conversationId).update({
      'lastMsg': text,
      'lastMsgAt': now,
      'lastMsgBy': user.uid,
    });
  }

  // Conversation আইডি তৈরি বা খুঁজে বের করা
  static Future<String> getOrCreateConversation({required String otherUserId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Login required');

    // deterministic ID: দুইজনের ইউআইডি মিলিয়ে একটি ইউনিক আইডি (ছোটটা আগে)
    final ids = [user.uid, otherUserId]..sort();
    final convId = ids.join('_');

    final ref = _db.collection('conversations').doc(convId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'id': convId,
        'participants': ids, // চ্যাট লিস্ট ফিল্টার করার জন্য জরুরি
        'createdAt': FieldValue.serverTimestamp(),
        'lastMsg': '',
        'unread': 0,
      });
    }
    return convId;
  }
}
// lib/services/blocked_user_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/services/notification_service.dart';

class BlockedUserService {
  static const String _prefsKey = 'blocked_users_map';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final BlockedUserService _instance = BlockedUserService._internal();
  factory BlockedUserService() => _instance;
  BlockedUserService._internal();

  // ১. অ্যাপ স্টার্টে Firestore থেকে লোকাল স্টোরেজ সিঙ্ক করা
  Future<void> syncWithFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db.collection('users').doc(uid).collection('blocked_users').get();
      final List<Map<String, String>> blockedList = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': (doc.data()['name'] ?? 'Unknown User').toString(),
        };
      }).toList();

      await _saveBlockedList(blockedList);
    } catch (e) {
      print("Error syncing blocked users: $e");
    }
  }

  // ২. ইউজারকে ব্লক করা (Cloud + Local)
  Future<void> blockUser(String targetId, String targetName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || targetId == uid) return;

    // ক) লোকাল আপডেট
    final current = await _loadBlockedList();
    if (!current.any((u) => u['id'] == targetId)) {
      current.add({'id': targetId, 'name': targetName});
      await _saveBlockedList(current);
    }

    // খ) Firestore আপডেট (সাব-কালেকশন হিসেবে)
    await _db.collection('users').doc(uid).collection('blocked_users').doc(targetId).set({
      'name': targetName,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    // গ) নোটিফিকেশন
    await NotificationService.sendNotification(
      toUserId: uid,
      fromUserId: 'system',
      title: 'User Blocked',
      body: 'You have blocked $targetName.',
      type: 'system',
    );
  }

  // ৩. ইউজারকে আনব্লক করা (Cloud + Local)
  Future<void> unblockUser(String targetId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // ক) লোকাল থেকে রিমুভ
    final current = await _loadBlockedList();
    current.removeWhere((u) => u['id'] == targetId);
    await _saveBlockedList(current);

    // খ) Firestore থেকে ডিলিট
    await _db.collection('users').doc(uid).collection('blocked_users').doc(targetId).delete();

    // গ) নোটিফিকেশন
    await NotificationService.sendNotification(
      toUserId: uid,
      fromUserId: 'system',
      title: 'User Unblocked',
      body: 'User has been removed from your block list.',
      type: 'system',
    );
  }

  // ৪. কোনো ইউজার ব্লকড কি না চেক করা (লোকাল থেকে - ফাস্ট)
  Future<bool> isBlocked(String id) async {
    final current = await _loadBlockedList();
    return current.any((u) => u['id'] == id);
  }

  // --- ইন্টারনাল হেল্পার্স ---

  Future<List<Map<String, String>>> _loadBlockedList() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_prefsKey) ?? [];
    return rawList.map((item) => Map<String, String>.from(jsonDecode(item))).toList();
  }

  Future<void> _saveBlockedList(List<Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = users.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_prefsKey, rawList);
  }

  Future<List<Map<String, String>>> getBlockedUsers() async => _loadBlockedList();

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
// lib/services/saved_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SavedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// মেমরিতে সেভ করা লিস্ট (UI তে দ্রুত দেখানোর জন্য)
  static List<Map<String, dynamic>> savedWorkers = [];

  /// অ্যাপ স্টার্টে Firestore থেকে ডাটা লোড করবে
  static Future<void> init() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('saved_profiles')
          .get();

      savedWorkers = snapshot.docs.map((doc) => doc.data()).toList();
      debugPrint("Loaded ${savedWorkers.length} saved profiles from Firestore");
    } catch (e) {
      debugPrint("Error loading saved profiles: $e");
    }
  }

  /// আইডি বের করার হেল্পার
  static String? _extractId(dynamic source) {
    if (source is String) return source;
    if (source is Map) {
      return (source['userId'] ?? source['id'] ?? source['uid'])?.toString();
    }
    return null;
  }

  /// সেভ করা আছে কি না চেক করা
  static bool isSaved(dynamic workerOrId) {
    final id = _extractId(workerOrId);
    if (id == null) return false;
    return savedWorkers.any((w) => _extractId(w) == id);
  }

  /// Toggle Save/Unsave (Firestore + Local Memory)
  static Future<void> toggleSave(Map<String, dynamic> workerData) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final workerId = _extractId(workerData);
    if (workerId == null) return;

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('saved_profiles')
        .doc(workerId);

    if (isSaved(workerId)) {
      // ১. আগে থেকেই থাকলে রিমুভ করো (Unsave)
      savedWorkers.removeWhere((w) => _extractId(w) == workerId);
      await docRef.delete();
    } else {
      // ২. না থাকলে অ্যাড করো (Save)
      final dataToSave = Map<String, dynamic>.from(workerData);

      // নিশ্চিত করি ডাটাতে আইডিটা আছে
      dataToSave['id'] = workerId;
      dataToSave['savedAt'] = FieldValue.serverTimestamp();

      savedWorkers.add(dataToSave);
      await docRef.set(dataToSave, SetOptions(merge: true));
    }
  }

  /// ইউজারের সব ডাটা ক্লিয়ার করা (Logout এর সময় কল করবেন)
  static void clear() {
    savedWorkers.clear();
  }

  /// শুধু নির্দিষ্ট আইডি দিয়ে রিমুভ করা
  static Future<void> removeWorkerById(String workerId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    savedWorkers.removeWhere((w) => _extractId(w) == workerId);
    await _db
        .collection('users')
        .doc(uid)
        .collection('saved_profiles')
        .doc(workerId)
        .delete();
  }
}
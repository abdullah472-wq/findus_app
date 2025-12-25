import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// বর্তমানে লগইন থাকা ইউজার
  static User? get currentUser => _auth.currentUser;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// লগইন state শুনতে চাইলে
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// নতুন ইউজার রেজিস্ট্রেশন (ইমেল + পাসওয়ার্ড)
  /// চাইলে পরে name/phone UI থেকে নিবে, তখন extra ফিল্ড বাড়িয়ে দিও
  static Future<User?> registerWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // Firestore এ basic user document তৈরি করি
        await _db.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileCompleted': false,
        }, SetOptions(merge: true));
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Registration Error: ${e.code}");
      }
      throw _handleAuthError(e);
    } catch (e, st) {
      if (kDebugMode) {
        print("Registration unknown error: $e");
        print(st);
      }
      rethrow;
    }
  }

  /// বিদ্যমান ইউজার লগইন
  static Future<User?> signInWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Sign-In Error: ${e.code}");
      }
      throw _handleAuthError(e);
    } catch (e, st) {
      if (kDebugMode) {
        print("Sign-In unknown error: $e");
        print(st);
      }
      rethrow;
    }
  }

  /// লগআউট
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// FirebaseAuth এরর → সহজ মেসেজ
  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'এই ইমেলের সাথে কোনো ব্যবহারকারী নিবন্ধিত নয়।';
      case 'wrong-password':
        return 'পাসওয়ার্ডটি ভুল। আবার চেষ্টা করুন।';
      case 'invalid-email':
        return 'দয়া করে একটি বৈধ ইমেল অ্যাড্রেস দিন।';
      case 'email-already-in-use':
        return 'এই ইমেল দিয়ে আগে থেকেই একটি অ্যাকাউন্ট আছে।';
      case 'weak-password':
        return 'পাসওয়ার্ডটি দুর্বল। কমপক্ষে ৬টি অক্ষর ব্যবহার করুন।';
      case 'too-many-requests':
        return 'অনেক বেশি অনুরোধ করা হয়েছে। পরে আবার চেষ্টা করুন।';
      default:
        return 'প্রবেশে ত্রুটি: ${e.message ?? e.code}';
    }
  }
}
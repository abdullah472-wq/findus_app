import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/services/cloudinary_service.dart';

class PortfolioService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> uploadPortfolioImages(List<dynamic> files) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('লগইন নেই');
    }
    if (files.isEmpty) return;

    final urls = <String>[];

    for (final f in files) {
      final res = await CloudinaryService.uploadFile(
        f,
        folder: 'findus/portfolio/$uid',
        resourceType: 'image',
        tags: const ['portfolio'],
      );

      final url = (res['secure_url'] ?? '').toString().trim();
      if (url.isNotEmpty) urls.add(url);
    }

    if (urls.isEmpty) return;

    await _db.collection('users').doc(uid).set({
      'portfolioImages': FieldValue.arrayUnion(urls),
      'portfolioUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> uploadCertificates(List<dynamic> files) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('লগইন নেই');
    }
    if (files.isEmpty) return;

    final urls = <String>[];

    for (final f in files) {
      final res = await CloudinaryService.uploadFile(
        f,
        folder: 'findus/certificates/$uid',
        resourceType: 'image',
        tags: const ['certificate'],
      );

      final url = (res['secure_url'] ?? '').toString().trim();
      if (url.isNotEmpty) urls.add(url);
    }

    if (urls.isEmpty) return;

    await _db.collection('users').doc(uid).set({
      'certificateImages': FieldValue.arrayUnion(urls),
      'certificatesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> uploadCv(dynamic file) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('লগইন নেই');
    }

    // এখন আপনার স্ক্রিন থেকে ইমেজ যাচ্ছে, তাই resourceType image রাখা হলো।
    // পরে PDF সাপোর্ট চাইলে resourceType 'raw' + file_picker ব্যবহার করবেন।
    final res = await CloudinaryService.uploadFile(
      file,
      folder: 'findus/cv/$uid',
      resourceType: 'image',
      tags: const ['cv'],
    );

    final url = (res['secure_url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('CV upload ব্যর্থ (secure_url নেই)');
    }

    await _db.collection('users').doc(uid).set({
      'cvUrl': url,
      'cvUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
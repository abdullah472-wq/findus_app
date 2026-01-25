// lib/services/profile_completion_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileCompletionService {
  static Future<bool> isCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;

      // ✅ বেসিক প্রোফাইল চেক
      final bool basicInfo =
          (data['name'] != null && data['name'].toString().isNotEmpty) &&
              (data['location'] != null && data['location'].toString().isNotEmpty) &&
              (data['phone'] != null && data['phone'].toString().isNotEmpty);

      // ✅ ইউজার রোল চেক
      final String role = (data['userRole'] ?? '').toString().toLowerCase();

      if (role == 'finder') {
        // ওয়ার্কার (Job Finder) হলে আরও কিছু ফিল্ড চেক করতে হবে
        final bool workerInfo =
            (data['roleKey'] != null && data['roleKey'].toString().isNotEmpty) && // Service Type
                (data['price'] != null || data['priceText'] != null) &&               // Price
                (data['workStart'] != null && data['workEnd'] != null);               // Work Time

        return basicInfo && workerInfo;
      } else if (role == 'maker') {
        // সাপোর্টার (Job Maker) হলে শুধু বেসিক ইনফো থাকলেই চলবে
        return basicInfo;
      }

      // যদি রোল ঠিকমতো না থাকে
      return false;

    } catch (e) {
      return false;
    }
  }
}
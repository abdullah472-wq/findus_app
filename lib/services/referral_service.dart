import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ১. রেফারেল কোড অ্যাপ্লাই করা (সাইন আপের সময়)
  static Future<void> applyReferralCode({required String newUserId, required String code}) async {
    try {
      // রেফারার (যিনি ইনভাইট করেছেন) খুঁজুন
      final query = await _db.collection('users').where('referralCode', isEqualTo: code).get();

      if (query.docs.isEmpty) return; // কোড ভুল হলে কিছু হবে না

      final referrerDoc = query.docs.first;
      final referrerId = referrerDoc.id;

      // নতুন ইউজারের প্রোফাইলে রেফারার আইডি সেভ করা
      await _db.collection('users').doc(newUserId).update({
        'referredBy': referrerId,
        'referralStatus': 'pending', // স্ট্যাটাস পেন্ডিং থাকবে যতক্ষণ না জব কমপ্লিট হয়
      });

      // রেফারারের ইনভাইট কাউন্ট বাড়ানো
      await _db.collection('users').doc(referrerId).update({
        'referralInvitedCount': FieldValue.increment(1),
        'referralPendingRewards': FieldValue.increment(50), // ধরুন ৫০ টাকা পেন্ডিং রিওয়ার্ড
      });

    } catch (e) {
      print("Referral Error: $e");
    }
  }

  // ২. রিওয়ার্ড আনলক করা (প্রথম জব কমপ্লিট হলে)
  static Future<void> completeReferralReward(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final data = userDoc.data();

      // যদি ইউজার রেফার করা হয়ে থাকে এবং স্ট্যাটাস পেন্ডিং থাকে
      if (data != null && data['referralStatus'] == 'pending' && data['referredBy'] != null) {
        final referrerId = data['referredBy'];
        const int rewardAmount = 50; // রিওয়ার্ড অ্যামাউন্ট

        // ব্যাচ রাইট (একসাথে আপডেট)
        final batch = _db.batch();

        // রেফারারের আপডেট
        final referrerRef = _db.collection('users').doc(referrerId);
        batch.update(referrerRef, {
          'referralPendingRewards': FieldValue.increment(-rewardAmount), // পেন্ডিং কমবে
          'referralTotalRewards': FieldValue.increment(rewardAmount),   // টোটাল রিওয়ার্ড বাড়বে
          'referralJoinedCount': FieldValue.increment(1),               // জয়েন কাউন্ট বাড়বে
          'walletBalance': FieldValue.increment(rewardAmount),          // ওয়ালেটে টাকা যোগ হবে
        });

        // নতুন ইউজারের আপডেট (তাকে বোনাস দিতে চাইলে)
        final newUserRef = _db.collection('users').doc(userId);
        batch.update(newUserRef, {
          'referralStatus': 'completed',
          'walletBalance': FieldValue.increment(20), // নতুন ইউজারকেও ২০ টাকা বোনাস
        });

        await batch.commit();
      }
    } catch (e) {
      print("Reward Error: $e");
    }
  }
}
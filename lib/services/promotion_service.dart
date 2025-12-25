// lib/services/promotion_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/promotion_campaign.dart';

class PromotionService {
  static final _firestore = FirebaseFirestore.instance;
  static final _promotionsRef = _firestore.collection('promotions');

  /// প্রোফাইল বুস্ট তৈরি (ProfileBoostScreen থেকে কল করবে)
  static Future<void> createProfilePromotion({
    required int days,
    required String targetArea,   // 'nearby' | 'city'
    required double dailyBudget,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final ownerId = user.uid;
    final now = DateTime.now();
    final startAt = now;
    final endAt = now.add(Duration(days: days));
    final totalBudget = days * dailyBudget;

    // নতুন ডক আইডি বানাই
    final docRef = _promotionsRef.doc();

    final campaign = PromotionCampaign(
      id: docRef.id,
      ownerId: ownerId,
      type: PromotionType.profile,
      targetId: ownerId,        // simple: নিজের প্রোফাইলই target
      targetArea: targetArea,
      days: days,
      dailyBudget: dailyBudget,
      totalBudget: totalBudget,
      status: PromotionStatus.active, // v1 এ direct active ধরলাম
      startAt: startAt,
      endAt: endAt,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(campaign.toMap());
  }

  /// নির্দিষ্ট ইউজারের সব promotions listen করার জন্য (Ad Center overview ইত্যাদির জন্য)
  static Stream<List<PromotionCampaign>> myPromotionsStream(String ownerId) {
    return _promotionsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((d) => PromotionCampaign.fromDoc(d))
          .toList(),
    );
  }

  /// শুধুমাত্র active profile promotions (Explore ranking এর জন্য কাজে লাগবে)
  static Future<List<PromotionCampaign>> fetchActiveProfilePromotions(
      {String? ownerId}) async {
    Query<Map<String, dynamic>> q = _promotionsRef
        .where('type', isEqualTo: PromotionType.profile)
        .where('status', isEqualTo: PromotionStatus.active);

    if (ownerId != null) {
      q = q.where('ownerId', isEqualTo: ownerId);
    }

    final now = DateTime.now();
    final snap = await q.get();

    final all = snap.docs
        .map((d) => PromotionCampaign.fromDoc(d))
        .where((c) =>
    !now.isBefore(c.startAt) &&
        !now.isAfter(c.endAt)) // time window check
        .toList();

    return all;
  }

  /// future এ: কোনো worker id এর জন্য active campaign আছে কি না
  static Future<PromotionCampaign?> getActiveProfileCampaignForWorker(
      String workerId) async {
    final now = DateTime.now();
    final snap = await _promotionsRef
        .where('type', isEqualTo: PromotionType.profile)
        .where('targetId', isEqualTo: workerId)
        .where('status', isEqualTo: PromotionStatus.active)
        .get();

    for (final doc in snap.docs) {
      final c = PromotionCampaign.fromDoc(doc);
      if (!now.isBefore(c.startAt) && !now.isAfter(c.endAt)) {
        return c;
      }
    }
    return null;
  }
}
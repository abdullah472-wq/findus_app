import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/screens/ads/ad_model.dart';

class AdService {
  // একটি র্যান্ডম অ্যাড ফেচ করা
  static Future<AdModel?> getRandomAd() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('isActive', isEqualTo: true) // শুধু একটিভ অ্যাড
          .get();

      if (snapshot.docs.isEmpty) return null;

      // র্যান্ডমলি একটি অ্যাড সিলেক্ট করা
      final randomIndex = Random().nextInt(snapshot.docs.length);
      return AdModel.fromDoc(snapshot.docs[randomIndex]);
    } catch (e) {
      return null;
    }
  }

  // অ্যাডে ক্লিক করলে কাউন্ট বাড়ানোর জন্য (Optional Analytics)
  static Future<void> incrementClick(String adId) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (_) {}
  }
}
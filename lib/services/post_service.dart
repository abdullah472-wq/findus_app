import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'posts';

  /// 📌 Create Post/Pin
  static Future<void> createPost({
    required String ownerId,
    required String ownerRole,
    required String title,
    required String description,
    required String roleLabel,
    required String roleKey,
    required double lat,
    required double lng,
    required String address,
    required List<String> locationKeys,
    required double price,
    required String priceLabel,
    required List<String> images,
    required bool isLive,
    FieldValue? createdAt,
    String gender = 'Any',
    double experience = 0,
    double rating = 0.0,
    bool trusted = false,
    bool verified = false,
    bool isPromoted = false,
    String status = 'open',
    int slots = 1,
    int approvedCount = 0,
  }) async {
    try {
      final docRef = await _db.collection(_collection).add({
        'ownerId': ownerId,
        'ownerRole': ownerRole,
        'title': title,
        'description': description,
        'roleLabel': roleLabel,
        'roleKey': roleKey,
        'location': GeoPoint(lat, lng),
        'lat': lat,
        'lng': lng,
        'address': address,
        'locationKeys': locationKeys,
        'price': price,
        'priceLabel': priceLabel,
        'image': images.isNotEmpty ? images.first : '',
        'images': images,
        'isLive': isLive,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'gender': gender,
        'experience': experience,
        'rating': rating,
        'trusted': trusted,
        'verified': verified,
        'isPromoted': isPromoted,
        'status': status,
        'slots': slots.clamp(1, 10),
        'approvedCount': approvedCount,

        // ✅ Analytics Initial Fields
        'clicks': 0,
        'impressions': 0,
      });

      // ✅ Long-term chain progress
      try {
        await AchievementService.incrementProgress('lt_posts_s1', amount: 1);
        await AchievementService.incrementProgress('lt_posts_s2', amount: 1);
        await AchievementService.incrementProgress('lt_posts_s3', amount: 1);
      } catch (_) {}

      if (kDebugMode) print("✅ Post created successfully: ${docRef.id}");
    } catch (e) {
      if (kDebugMode) print("❌ Error creating post: $e");
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamPins() {
    return _db
        .collection(_collection)
        .where('isLive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        double lat = 0.0;
        double lng = 0.0;

        if (data['location'] is GeoPoint) {
          final gp = data['location'] as GeoPoint;
          lat = gp.latitude;
          lng = gp.longitude;
        } else {
          lat = double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0;
          lng = double.tryParse(data['lng']?.toString() ?? '0') ?? 0.0;
        }

        return {
          ...data,
          'id': doc.id,
          'latitude': lat,
          'longitude': lng,
          'geoPoint': data['location'] is GeoPoint ? data['location'] : GeoPoint(lat, lng),
        };
      }).toList();
    }).handleError((error) {
      if (kDebugMode) print("❌ Error streaming posts: $error");
      return <Map<String, dynamic>>[];
    });
  }

  static Future<void> deletePost(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).delete();
      if (kDebugMode) print("🗑️ Post deleted successfully");
    } catch (e) {
      if (kDebugMode) print("❌ Error deleting post: $e");
      rethrow;
    }
  }

  static Future<void> updatePostStatus(String postId, bool isLive) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        'isLive': isLive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print("🔄 Post status updated to: $isLive");
    } catch (e) {
      if (kDebugMode) print("❌ Error updating status: $e");
      rethrow;
    }
  }

  // ✅ 1. Track Card Click (Tap) - Updated Logic
  static Future<void> trackCardClick(String postId, String ownerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    // নিজের কার্ডে নিজে ক্লিক করলে কাউন্ট হবে না
    if (currentUser != null && currentUser.uid == ownerId) return;

    try {
      // পোস্টের ক্লিক এবং ইম্প্রেশন কাউন্ট বাড়ানো
      // যেহেতু ইউজার কার্ডে ক্লিক করেছে, তাই এটি একটি ভিউ/ইম্প্রেশন হিসেবেও গণ্য হবে
      if (postId.isNotEmpty) {
        await _db.collection(_collection).doc(postId).update({
          'clicks': FieldValue.increment(1),
          'impressions': FieldValue.increment(1), // ✅ এখানে ইম্প্রেশন যোগ করা হলো
        });
      }

      // ইউজারের টোটাল প্রোফাইল ভিউ কাউন্ট বাড়ানো
      await _db.collection('users').doc(ownerId).update({
        'profileViews': FieldValue.increment(1),
      });

      debugPrint("✅ Click & Impression tracked for Post: $postId");
    } catch (e) {
      debugPrint("❌ Error tracking click: $e");
    }
  }

  // ✅ 2. Track Profile Click (Direct)
  static Future<void> trackProfileClick(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == targetUserId) return;

    try {
      await _db.collection('users').doc(targetUserId).update({
        'profileViews': FieldValue.increment(1),
      });
      debugPrint("✅ Profile view counted for $targetUserId");
    } catch (e) {
      debugPrint("❌ Error counting view: $e");
    }
  }

// নোট: trackImpression ফাংশনটি রিমুভ করা হয়েছে।
// এখন শুধু কার্ডে ট্যাপ করলেই ইম্প্রেশন গণনা হবে।
}
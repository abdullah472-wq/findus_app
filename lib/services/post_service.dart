import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // ডিবাগ প্রিন্টের জন্য

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'posts'; // কালেকশন নাম কনস্ট্যান্ট হিসেবে রাখা ভালো

  /// 📌 পিন তৈরি করা (Create Post/Pin)
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
    // FieldValue.serverTimestamp() পাস করাই উত্তম
    FieldValue? createdAt,
    String gender = 'Any',
    double experience = 0,
    double rating = 0.0,
    bool trusted = false,
    bool verified = false,
    bool isPromoted = false,
    String status = 'open',
  }) async {
    try {
      await _db.collection(_collection).add({
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
      });
      if (kDebugMode) print("✅ Post created successfully");
    } catch (e) {
      if (kDebugMode) print("❌ Error creating post: $e");
      rethrow; // UI তে এরর দেখানোর জন্য rethrow করা হলো
    }
  }

  /// 📍 ম্যাপের সব পিন লোড করা
  /// দ্রষ্টব্য: Firebase Console এ 'isLive' এবং 'createdAt' এর জন্য Composite Index তৈরি করতে হবে।
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

        // সেফটি চেক: লোকেশন ডেটা এক্সট্রাক্ট করা
        double lat = 0.0;
        double lng = 0.0;

        if (data['location'] is GeoPoint) {
          GeoPoint gp = data['location'];
          lat = gp.latitude;
          lng = gp.longitude;
        } else {
          // যদি GeoPoint না থাকে, lat/lng ফিল্ড চেক করবে
          lat = double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0;
          lng = double.tryParse(data['lng']?.toString() ?? '0') ?? 0.0;
        }

        return {
          ...data,
          'id': doc.id,
          'latitude': lat,
          'longitude': lng,
          // UI এর সুবিধার্থে GeoPoint অবজেক্টও রাখা হলো
          'geoPoint': data['location'] is GeoPoint
              ? data['location']
              : GeoPoint(lat, lng),
        };
      }).toList();
    }).handleError((error) {
      if (kDebugMode) print("❌ Error streaming posts: $error");
      return <Map<String, dynamic>>[]; // এরর হলে খালি লিস্ট রিটার্ন করবে
    });
  }

  /// 🗑️ পিন ডিলিট করা
  static Future<void> deletePost(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).delete();
      if (kDebugMode) print("🗑️ Post deleted successfully");
    } catch (e) {
      if (kDebugMode) print("❌ Error deleting post: $e");
      rethrow;
    }
  }

  /// 🔄 পিন আপডেট করা (Live Status)
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
}
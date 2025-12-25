// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:findus_app/services/notification_service.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// নতুন Earn/Support পোস্ট তৈরি করার জন্য helper
  static Future<void> createPost({
    required String ownerId,
    required String ownerRole, // 'worker' or 'supporter'
    required String title,
    required String roleLabel, // যেমন 'DRIVER', 'CLEANER'
    required double lat,
    required double lng,
    required String address,
    required String priceLabel,
    bool isLive = true,
    bool verified = false,
    String phone = '',
    String gender = 'Any',
    int experience = 0,
    double rating = 4.5,
    String language = 'Any',
    bool trusted = false,

    /// 🔹 Firestore পোস্টের isPromoted flag
    bool isPromoted = false,
  }) async {
    // 🔹 ১) Firestore এ post ডকুমেন্ট তৈরি
    final docRef = await _db.collection('posts').add({
      'ownerId': ownerId,
      'ownerRole': ownerRole,
      'title': title,
      'roleLabel': roleLabel,
      'lat': lat,
      'lng': lng,
      'address': address,
      'priceLabel': priceLabel,
      'isLive': isLive,
      'verified': verified,
      'phone': phone,
      'gender': gender,
      'experience': experience,
      'rating': rating,
      'language': language,
      'trusted': trusted,
      'createdAt': FieldValue.serverTimestamp(),
      'isPromoted': isPromoted,
    });

    final postId = docRef.id;

    // 🔹 ২) owner-এর জন্য job_post notification
    final notifTitle = ownerRole == 'supporter'
        ? 'Your request has been posted'
        : 'Your job offer has been posted';

    await NotificationService.sendNotificationToUser(
      toUserId: ownerId,
      title: notifTitle,
      body: '“$title” is now live.',
      type: 'job_post',
      relatedPostId: postId,
      data: {
        'ownerRole': ownerRole,
        'roleLabel': roleLabel,
        'address': address,
        'priceLabel': priceLabel,
        'lat': lat,
        'lng': lng,
      },
    );
  }

  /// viewerRole: 'finder' / 'maker' → বিপরীত ownerRole এর পোস্ট stream করবে
  static Stream<List<Map<String, dynamic>>> streamPinsForViewerRole(
      String viewerRole) {
    final oppositeOwnerRole =
    viewerRole == 'finder' ? 'supporter' : 'worker';

    final query = _db
        .collection('posts')
        .where('ownerRole', isEqualTo: oppositeOwnerRole)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        final lat = (data['lat'] ?? 0.0) as num;
        final lng = (data['lng'] ?? 0.0) as num;

        return <String, dynamic>{
          "id": doc.id,
          "name": data['title'] ?? 'Post',
          "role": data['roleLabel'] ?? 'WORK',
          "location": LatLng(lat.toDouble(), lng.toDouble()),
          "address": data['address'] ?? '',
          "image": "https://i.pravatar.cc/150?u=${doc.id}", // demo avatar
          "price": data['priceLabel'] ?? 'Negotiable',
          "verified": data['verified'] ?? false,
          "isLive": data['isLive'] ?? true,
          "phone": data['phone'] ?? '',
          "gender": data['gender'] ?? 'Any',
          "experience": data['experience'] ?? 0,
          "rating": (data['rating'] is num)
              ? (data['rating'] as num).toDouble()
              : 4.5,
          "language": data['language'] ?? 'Any',
          "trusted": data['trusted'] ?? false,
          "isPromoted": (data['isPromoted'] ?? false) as bool,
        };
      }).toList();
    });
  }
}
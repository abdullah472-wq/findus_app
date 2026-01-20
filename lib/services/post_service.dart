import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Create post (production-grade) + optional fields for better filtering/ranking on map
  static Future<void> createPost({
    required String ownerId,
    required String ownerRole, // 'finder' or 'maker'
    required String title,
    required String description,
    required String roleLabel,
    required String roleKey,
    required double lat,
    required double lng,
    required String address,
    required List<String> locationKeys,
    required double price, // numeric for filtering
    required String priceLabel, // display label (e.g. "৳800 / day")
    required List<String> images,
    required bool isLive,
    dynamic createdAt, // FieldValue.serverTimestamp()

    // ✅ Optional (used by Explore filters/sorting)
    bool? verified, // default false
    bool? isPromoted, // default false
    String? status, // default 'open'
    String? gender, // 'Male'/'Female'/'Any'
    int? experience, // years (or any numeric)
    double? rating, // 0.0 - 5.0
    bool? trusted, // badge/logic derived if you want
  }) async {
    try {
      await _db.collection('posts').add({
        'ownerId': ownerId,
        'ownerRole': ownerRole,
        'title': title,
        'description': description,
        'roleLabel': roleLabel,
        'roleKey': roleKey,
        'location': GeoPoint(lat, lng),
        'address': address,
        'locationKeys': locationKeys,
        'price': price,
        'priceLabel': priceLabel,
        'images': images,
        'isLive': isLive,

        // defaults (override-able)
        'verified': verified ?? false,
        'isPromoted': isPromoted ?? false,
        'status': status ?? 'open',

        // optional filter/sort metadata
        'gender': gender ?? 'Any',
        'experience': experience ?? 0,
        'rating': rating ?? 0.0,
        'trusted': trusted ?? false,

        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Post creation failed: $e");
    }
  }

  /// ✅ ExploreScreen-compatible pins stream
  /// viewerRole: 'finder' or 'maker'
  static Stream<List<Map<String, dynamic>>> streamPinsForViewerRole(String viewerRole) {
    final String targetRole = (viewerRole == 'finder') ? 'maker' : 'finder';

    return _db
        .collection('posts')
        .where('ownerRole', isEqualTo: targetRole)
        .where('isLive', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final geo = data['location'];
        final GeoPoint gp = geo is GeoPoint
            ? geo
            : const GeoPoint(23.8103, 90.4125); // fallback Dhaka

        return {
          'id': doc.id,
          'name': (data['title'] ?? '').toString(),
          'role': (data['roleLabel'] ?? '').toString(),

          // ✅ MUST be LatLng (ExploreScreen expects LatLng)
          'location': LatLng(gp.latitude, gp.longitude),

          'address': (data['address'] ?? '').toString(),

          // ExploreScreen extracts digits from this string for price filtering
          'price': (data['priceLabel'] ?? '').toString(),

          'verified': data['verified'] == true,
          'isLive': data['isLive'] == true,
          'isPromoted': data['isPromoted'] == true,

          // optional filter/sort metadata
          'gender': (data['gender'] ?? 'Any').toString(),
          'experience': (data['experience'] ?? 0),
          'rating': (data['rating'] ?? 0.0),
          'trusted': (data['trusted'] ?? false),

          'images': (data['images'] is List) ? data['images'] : <dynamic>[],
          'ownerId': (data['ownerId'] ?? '').toString(),
        };
      }).toList();
    });
  }
}
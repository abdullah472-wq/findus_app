// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'posts';

  // ════════════════════════════════════════════════════════════════════════════
  // 📌 CREATE POST
  // ════════════════════════════════════════════════════════════════════════════

  static Future<String> createPost({
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
        'updatedAt': FieldValue.serverTimestamp(), // ✅ Added
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
        'saves': 0,
        'shares': 0,
        'searchImpressions': 0,
        'lastClickedAt': null,
        'lastSharedAt': null,
        'lastSearchedAt': null,
      });

      // ✅ Achievement Progress (Non-blocking)
      _updateAchievements();

      debugPrint("✅ Post created successfully: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint("❌ Error creating post: $e");
      rethrow;
    }
  }

  /// ✅ Non-blocking achievement update
  static Future<void> _updateAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('lt_posts_s1', amount: 1),
        AchievementService.incrementProgress('lt_posts_s2', amount: 1),
        AchievementService.incrementProgress('lt_posts_s3', amount: 1),
      ]);
    } catch (e) {
      debugPrint("⚠️ Achievement update failed: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📡 STREAM POSTS
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Stream all live posts (with offline support)
  static Stream<List<Map<String, dynamic>>> streamPins() {
    return _db
        .collection(_collection)
        .where('isLive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots(includeMetadataChanges: true) // ✅ Offline support
        .map((snapshot) {
      return snapshot.docs.map((doc) => _parsePostData(doc)).toList();
    }).handleError((error) {
      debugPrint("❌ Error streaming posts: $error");
      return <Map<String, dynamic>>[];
    });
  }

  /// ✅ Stream posts with filters (with offline support)
  static Stream<List<Map<String, dynamic>>> streamFilteredPosts({
    String? roleKey,
    String? ownerId,
    double? minPrice,
    double? maxPrice,
    bool? isPromoted,
    String? status,
    int limit = 100,
  }) {
    var query = _db
        .collection(_collection)
        .where('isLive', isEqualTo: true);

    if (roleKey != null) {
      query = query.where('roleKey', isEqualTo: roleKey);
    }

    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    if (isPromoted != null) {
      query = query.where('isPromoted', isEqualTo: isPromoted);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true) // ✅ Offline support
        .map((snapshot) {
      var docs = snapshot.docs.map((doc) => _parsePostData(doc)).toList();

      // ✅ Client-side price filtering
      if (minPrice != null || maxPrice != null) {
        docs = docs.where((post) {
          final price = (post['price'] as num?)?.toDouble() ?? 0.0;
          if (minPrice != null && price < minPrice) return false;
          if (maxPrice != null && price > maxPrice) return false;
          return true;
        }).toList();
      }

      return docs;
    }).handleError((error) {
      debugPrint("❌ Error streaming filtered posts: $error");
      return <Map<String, dynamic>>[];
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 GET SINGLE POST
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Get single post with offline support
  static Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(postId)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ Offline support

      if (!doc.exists) {
        debugPrint("⚠️ Post not found: $postId");
        return null;
      }

      return _parsePostData(doc);
    } catch (e) {
      debugPrint("❌ Error getting post: $e");
      return null;
    }
  }

  /// ✅ Stream single post (real-time)
  static Stream<Map<String, dynamic>?> streamPostById(String postId) {
    return _db
        .collection(_collection)
        .doc(postId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
      if (!doc.exists) return null;
      return _parsePostData(doc);
    }).handleError((error) {
      debugPrint("❌ Error streaming post: $error");
      return null;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✏️ UPDATE POST
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> updatePost(
      String postId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Post updated successfully: $postId");
    } catch (e) {
      debugPrint("❌ Error updating post: $e");
      rethrow;
    }
  }

  static Future<void> updatePostStatus(String postId, bool isLive) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        'isLive': isLive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("🔄 Post status updated to: $isLive");
    } catch (e) {
      debugPrint("❌ Error updating status: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ DELETE POST
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> deletePost(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).delete();
      debugPrint("🗑️ Post deleted successfully: $postId");
    } catch (e) {
      debugPrint("❌ Error deleting post: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 ANALYTICS TRACKING
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Track card click (non-blocking, ignore if owner)
  static Future<void> trackCardClick(String postId, String ownerId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == ownerId) return;

    // ✅ Run in background (non-blocking)
    _trackAnalytics(() async {
      if (postId.isNotEmpty) {
        await _db.collection(_collection).doc(postId).update({
          'clicks': FieldValue.increment(1),
          'impressions': FieldValue.increment(1),
          'lastClickedAt': FieldValue.serverTimestamp(),
        });
      }

      await _db.collection('users').doc(ownerId).update({
        'profileViews': FieldValue.increment(1),
        'lastProfileViewAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Click & Impression tracked for Post: $postId");
    });
  }

  /// ✅ Track profile click
  static Future<void> trackProfileClick(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == targetUserId) return;

    _trackAnalytics(() async {
      await _db.collection('users').doc(targetUserId).update({
        'profileViews': FieldValue.increment(1),
        'lastProfileViewAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Profile view counted for $targetUserId");
    });
  }

  /// ✅ Track search impression
  static Future<void> trackSearchImpression(String postId) async {
    _trackAnalytics(() async {
      await _db.collection(_collection).doc(postId).update({
        'searchImpressions': FieldValue.increment(1),
        'lastSearchedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Search impression tracked");
    });
  }

  /// ✅ Track save/bookmark
  static Future<void> trackSave(String postId) async {
    _trackAnalytics(() async {
      await _db.collection(_collection).doc(postId).update({
        'saves': FieldValue.increment(1),
      });
      debugPrint("✅ Save tracked");
    });
  }

  /// ✅ Track share
  static Future<void> trackShare(String postId) async {
    _trackAnalytics(() async {
      await _db.collection(_collection).doc(postId).update({
        'shares': FieldValue.increment(1),
        'lastSharedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Share tracked");
    });
  }

  /// ✅ Non-blocking analytics wrapper
  static void _trackAnalytics(Future<void> Function() fn) {
    fn().catchError((e) {
      debugPrint("⚠️ Analytics tracking failed: $e");
    });
  }

  /// ✅ Get analytics for a post
  static Future<Map<String, dynamic>> getPostAnalytics(String postId) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(postId)
          .get(const GetOptions(source: Source.serverAndCache));

      final data = doc.data() ?? {};

      final impressions = data['impressions'] ?? 0;
      final clicks = data['clicks'] ?? 0;

      return {
        'impressions': impressions,
        'clicks': clicks,
        'saves': data['saves'] ?? 0,
        'shares': data['shares'] ?? 0,
        'searchImpressions': data['searchImpressions'] ?? 0,
        'ctr': _calculateCTR(clicks, impressions),
        'lastClickedAt': data['lastClickedAt'],
        'lastSharedAt': data['lastSharedAt'],
        'lastSearchedAt': data['lastSearchedAt'],
      };
    } catch (e) {
      debugPrint("❌ Error getting analytics: $e");
      return {
        'impressions': 0,
        'clicks': 0,
        'saves': 0,
        'shares': 0,
        'searchImpressions': 0,
        'ctr': 0.0,
      };
    }
  }

  /// ✅ Calculate Click-Through Rate
  static double _calculateCTR(dynamic clicks, dynamic impressions) {
    final c = (clicks is int) ? clicks : int.tryParse(clicks?.toString() ?? '0') ?? 0;
    final i = (impressions is int) ? impressions : int.tryParse(impressions?.toString() ?? '0') ?? 0;

    if (i == 0) return 0.0;
    return double.parse((c / i * 100).toStringAsFixed(2));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📦 BATCH OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Batch update posts (max 500 per batch)
  static Future<void> batchUpdatePosts(
      List<String> postIds,
      Map<String, dynamic> updates,
      ) async {
    try {
      // ✅ Split into chunks of 500 (Firestore limit)
      const chunkSize = 500;
      for (var i = 0; i < postIds.length; i += chunkSize) {
        final chunk = postIds.skip(i).take(chunkSize).toList();
        final batch = _db.batch();

        for (final postId in chunk) {
          final docRef = _db.collection(_collection).doc(postId);
          batch.update(docRef, {
            ...updates,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        debugPrint("✅ Batch update completed for ${chunk.length} posts");
      }
    } catch (e) {
      debugPrint("❌ Error in batch update: $e");
      rethrow;
    }
  }

  /// ✅ Batch delete posts (max 500 per batch)
  static Future<void> batchDeletePosts(List<String> postIds) async {
    try {
      const chunkSize = 500;
      for (var i = 0; i < postIds.length; i += chunkSize) {
        final chunk = postIds.skip(i).take(chunkSize).toList();
        final batch = _db.batch();

        for (final postId in chunk) {
          final docRef = _db.collection(_collection).doc(postId);
          batch.delete(docRef);
        }

        await batch.commit();
        debugPrint("✅ Batch delete completed for ${chunk.length} posts");
      }
    } catch (e) {
      debugPrint("❌ Error in batch delete: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎯 POST STATUS MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Mark post as completed
  static Future<void> markAsCompleted(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'isLive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Post marked as completed: $postId");
    } catch (e) {
      debugPrint("❌ Error marking as completed: $e");
      rethrow;
    }
  }

  /// ✅ Reopen a post
  static Future<void> reopenPost(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        'status': 'open',
        'isLive': true,
        'reopenedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Post reopened: $postId");
    } catch (e) {
      debugPrint("❌ Error reopening post: $e");
      rethrow;
    }
  }

  /// ✅ Archive a post
  static Future<void> archivePost(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).update({
        'status': 'archived',
        'isLive': false,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Post archived: $postId");
    } catch (e) {
      debugPrint("❌ Error archiving post: $e");
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🛠️ HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Parse post data from Firestore document
  static Map<String, dynamic> _parsePostData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

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
      'geoPoint': GeoPoint(lat, lng),
    };
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔥 ADDITIONAL UTILITIES
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Get posts count by owner
  static Future<int> getPostsCountByOwner(String ownerId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .where('isLive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint("❌ Error getting posts count: $e");
      return 0;
    }
  }

  /// ✅ Check if user owns post
  static Future<bool> isPostOwner(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _db
          .collection(_collection)
          .doc(postId)
          .get(const GetOptions(source: Source.cache));

      return doc.data()?['ownerId'] == currentUser.uid;
    } catch (e) {
      debugPrint("❌ Error checking ownership: $e");
      return false;
    }
  }
}
// lib/services/rating_history_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RatingHistoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ In-memory cache for better performance
  static final Map<String, Map<String, dynamic>> _summaryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get rating summary for worker
  /// Returns: { 'avgRating': double, 'totalReviews': int }
  static Future<Map<String, dynamic>> getSummaryForWorker(String workerKey) async {
    if (workerKey.isEmpty) {
      return {'avgRating': 0.0, 'totalReviews': 0};
    }

    // ✅ Check cache first
    if (_summaryCache.containsKey(workerKey)) {
      final cachedAt = _cacheTimestamps[workerKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < _cacheDuration) {
        debugPrint("📦 Using cached rating for $workerKey");
        return _summaryCache[workerKey]!;
      }
    }

    try {
      final snap = await _db
          .collection('ratings')
          .where('workerKey', isEqualTo: workerKey)
          .get();

      if (snap.docs.isEmpty) {
        return {'avgRating': 0.0, 'totalReviews': 0};
      }

      double total = 0;
      for (final doc in snap.docs) {
        final rating = (doc.data()['stars'] as num?)?.toDouble() ?? 0.0;
        total += rating;
      }

      final count = snap.docs.length;
      final avg = total / count;

      final result = {
        'avgRating': double.parse(avg.toStringAsFixed(2)),
        'totalReviews': count,
      };

      // ✅ Update cache
      _summaryCache[workerKey] = result;
      _cacheTimestamps[workerKey] = DateTime.now();

      return result;
    } catch (e) {
      debugPrint("❌ Error getting rating summary: $e");
      return {'avgRating': 0.0, 'totalReviews': 0};
    }
  }

  /// Get recent reviews for worker
  /// Returns: List<Map> → [{ name, comment, stars, createdAt }, ...]
  static Future<List<Map<String, dynamic>>> getRecentReviewsForWorker(
      String workerKey, {
        int limit = 3,
      }) async {
    if (workerKey.isEmpty) return [];

    try {
      final snap = await _db
          .collection('ratings')
          .where('workerKey', isEqualTo: workerKey)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['userName'] ?? 'Anonymous',
          'comment': data['comment'] ?? '',
          'stars': (data['stars'] as num?)?.toInt() ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error getting recent reviews: $e");
      return [];
    }
  }

  /// Stream rating summary (real-time updates)
  /// Returns: Stream<Map> → { 'avgRating': double, 'totalReviews': int }
  static Stream<Map<String, dynamic>> streamSummaryForWorker(String workerKey) {
    if (workerKey.isEmpty) {
      return Stream.value({'avgRating': 0.0, 'totalReviews': 0});
    }

    return _db
        .collection('ratings')
        .where('workerKey', isEqualTo: workerKey)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return {'avgRating': 0.0, 'totalReviews': 0};
      }

      double total = 0;
      for (final doc in snap.docs) {
        final rating = (doc.data()['stars'] as num?)?.toDouble() ?? 0.0;
        total += rating;
      }

      final count = snap.docs.length;
      final avg = total / count;

      return {
        'avgRating': double.parse(avg.toStringAsFixed(2)),
        'totalReviews': count,
      };
    }).handleError((error) {
      debugPrint("❌ Stream error: $error");
      return {'avgRating': 0.0, 'totalReviews': 0};
    });
  }

  /// Get rating distribution (5 stars: 10, 4 stars: 5, etc.)
  /// Returns: Map<int, int> → {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}
  static Future<Map<int, int>> getRatingDistribution(String workerKey) async {
    if (workerKey.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    try {
      final snap = await _db
          .collection('ratings')
          .where('workerKey', isEqualTo: workerKey)
          .get();

      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (final doc in snap.docs) {
        final stars = (doc.data()['stars'] as num?)?.toInt() ?? 0;
        if (stars >= 1 && stars <= 5) {
          distribution[stars] = (distribution[stars] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint("❌ Error getting rating distribution: $e");
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }
  }

  /// Get all reviews with pagination
  /// Returns: List<Map> with pagination support
  static Future<List<Map<String, dynamic>>> getReviewsWithPagination(
      String workerKey, {
        int limit = 10,
        DocumentSnapshot? lastDoc,
      }) async {
    if (workerKey.isEmpty) return [];

    try {
      var query = _db
          .collection('ratings')
          .where('workerKey', isEqualTo: workerKey)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // ✅ Pagination support
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['userName'] ?? 'Anonymous',
          'comment': data['comment'] ?? '',
          'stars': (data['stars'] as num?)?.toInt() ?? 0,
          'createdAt': data['createdAt'],
          'doc': doc, // For next page pagination
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Error getting paginated reviews: $e");
      return [];
    }
  }

  /// Get detailed rating stats
  /// Returns comprehensive statistics
  static Future<Map<String, dynamic>> getDetailedStats(String workerKey) async {
    if (workerKey.isEmpty) {
      return {
        'avgRating': 0.0,
        'totalReviews': 0,
        'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        'percentages': {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
        'recentReviews': [],
      };
    }

    try {
      final snap = await _db
          .collection('ratings')
          .where('workerKey', isEqualTo: workerKey)
          .get();

      if (snap.docs.isEmpty) {
        return {
          'avgRating': 0.0,
          'totalReviews': 0,
          'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          'percentages': {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
          'recentReviews': [],
        };
      }

      double total = 0;
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      List<Map<String, dynamic>> recentReviews = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        final stars = (data['stars'] as num?)?.toInt() ?? 0;
        total += stars;

        if (stars >= 1 && stars <= 5) {
          distribution[stars] = (distribution[stars] ?? 0) + 1;
        }

        recentReviews.add({
          'name': data['userName'] ?? 'Anonymous',
          'comment': data['comment'] ?? '',
          'stars': stars,
          'createdAt': data['createdAt'],
        });
      }

      final count = snap.docs.length;
      final avg = total / count;

      // Calculate percentages
      Map<int, double> percentages = {};
      for (int i = 1; i <= 5; i++) {
        percentages[i] = (distribution[i]! / count) * 100;
      }

      // Sort recent reviews by date
      recentReviews.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return {
        'avgRating': double.parse(avg.toStringAsFixed(2)),
        'totalReviews': count,
        'distribution': distribution,
        'percentages': percentages,
        'recentReviews': recentReviews.take(5).toList(),
      };
    } catch (e) {
      debugPrint("❌ Error getting detailed stats: $e");
      return {
        'avgRating': 0.0,
        'totalReviews': 0,
        'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        'percentages': {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
        'recentReviews': [],
      };
    }
  }

  /// Check if user has reviewed a worker
  static Future<bool> hasUserReviewedWorker({
    required String userId,
    required String workerKey,
  }) async {
    try {
      final snap = await _db
          .collection('ratings')
          .where('userId', isEqualTo: userId)
          .where('workerKey', isEqualTo: workerKey)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Error checking review status: $e");
      return false;
    }
  }

  /// Clear cache for a specific worker
  static void clearCache(String workerKey) {
    _summaryCache.remove(workerKey);
    _cacheTimestamps.remove(workerKey);
    debugPrint("🗑️ Cleared cache for $workerKey");
  }

  /// Clear all cache
  static void clearAllCache() {
    _summaryCache.clear();
    _cacheTimestamps.clear();
    debugPrint("🗑️ Cleared all rating cache");
  }

  /// Get top rated workers (leaderboard)
  static Future<List<Map<String, dynamic>>> getTopRatedWorkers({
    int limit = 10,
    double minRating = 4.0,
    int minReviews = 5,
  }) async {
    try {
      final snap = await _db
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .limit(1000) // Get a large sample
          .get();

      // Group by workerKey
      Map<String, List<double>> workerRatings = {};

      for (var doc in snap.docs) {
        final workerKey = doc.data()['workerKey'] as String?;
        final stars = (doc.data()['stars'] as num?)?.toDouble() ?? 0.0;

        if (workerKey != null && workerKey.isNotEmpty) {
          workerRatings.putIfAbsent(workerKey, () => []);
          workerRatings[workerKey]!.add(stars);
        }
      }

      // Calculate averages and filter
      List<Map<String, dynamic>> topWorkers = [];

      workerRatings.forEach((workerKey, ratings) {
        if (ratings.length >= minReviews) {
          final avg = ratings.reduce((a, b) => a + b) / ratings.length;
          if (avg >= minRating) {
            topWorkers.add({
              'workerKey': workerKey,
              'avgRating': double.parse(avg.toStringAsFixed(2)),
              'totalReviews': ratings.length,
            });
          }
        }
      });

      // Sort by rating
      topWorkers.sort((a, b) => b['avgRating'].compareTo(a['avgRating']));

      return topWorkers.take(limit).toList();
    } catch (e) {
      debugPrint("❌ Error getting top rated workers: $e");
      return [];
    }
  }
}
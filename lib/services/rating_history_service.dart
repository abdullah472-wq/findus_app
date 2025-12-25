import 'package:cloud_firestore/cloud_firestore.dart';

class RatingHistoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// workerKey (uid / phone / name) অনুযায়ী রেটিং summary
  /// return map: { 'avgRating': double, 'totalReviews': int }
  static Future<Map<String, dynamic>> getSummaryForWorker(
      String workerKey) async {
    if (workerKey.isEmpty) {
      return {'avgRating': 0.0, 'totalReviews': 0};
    }

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

    return {'avgRating': avg, 'totalReviews': count};
  }

  /// recent reviews – workerKey অনুযায়ী
  /// return List<Map> → [{ name, comment, stars }, ...]
  static Future<List<Map<String, dynamic>>> getRecentReviewsForWorker(
      String workerKey, {
        int limit = 3,
      }) async {
    if (workerKey.isEmpty) return [];

    final snap = await _db
        .collection('ratings')
        .where('workerKey', isEqualTo: workerKey)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['userName'] ?? 'User',
        'comment': data['comment'] ?? '',
        'stars': (data['stars'] as num?)?.toInt() ?? 0,
      };
    }).toList();
  }
}
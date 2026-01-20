import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardThemeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'card_themes';

  // থিম গ্রেডিয়েন্টের লিস্ট
  static const List<List<Color>> gradients = [
    [Color(0xFFB2EBF2), Color(0xFFE0F7FA)], // teal/light blue
    [Color(0xFFFFCC80), Color(0xFFFFE0B2)], // orange
    [Color(0xFFC5CAE9), Color(0xFFE8EAF6)], // indigo
    [Color(0xFFF8BBD0), Color(0xFFFCE4EC)], // pink
  ];

  /// কার্ড থিম ইন্ডেক্স নিয়ে আসে
  static Future<int> getCardThemeIndex(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['color_index'] as int? ?? 0;
      }

      // ডিফল্ট ভ্যালু সেট করে রাখে
      await setCardThemeIndex(userId, 0);
      return 0;
    } catch (e) {
      print('Error getting card theme: $e');
      return 0;
    }
  }

  /// কার্ড থিম ইন্ডেক্স সেভ করে
  static Future<void> setCardThemeIndex(String userId, int index) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set({
        'color_index': index,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting card theme: $e');
      rethrow;
    }
  }

  /// প্রোফাইল কার্ডের থিম কালার ফিরিয়ে দেয়
  static Future<List<Color>> getCardColors(String userId) async {
    final index = await getCardThemeIndex(userId);
    final int safeIndex = index.clamp(0, gradients.length - 1);

    // ✅ সরাসরি gradients থেকে colors রিটার্ন করুন
    return gradients[safeIndex];
  }

  /// থিমের নাম ফিরিয়ে দেয়
  static String getThemeName(int index) {
    final List<String> names = ['Teal', 'Orange', 'Indigo', 'Pink'];
    return names[index.clamp(0, names.length - 1)];
  }

  /// সব থিমের লিস্ট ফিরিয়ে দেয়
  static List<List<Color>> getAllThemes() {
    return gradients;
  }

  /// থিম সংখ্যা ফিরিয়ে দেয়
  static int getThemeCount() {
    return gradients.length;
  }
}
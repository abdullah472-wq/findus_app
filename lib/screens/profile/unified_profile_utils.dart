import 'package:flutter/material.dart';

class UnifiedProfileUtils {
  static String safeString(dynamic value, {String defaultValue = 'N/A'}) {
    if (value == null) return defaultValue;
    if (value is String && value.trim().isEmpty) return defaultValue;
    return value.toString();
  }

  static int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static double safeDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  static String formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// DB role standard: finder=Worker, maker=Supporter
  static bool isWorkerRoleFromUserData(Map<String, dynamic> userData) {
    final role = (userData['userRole'] ?? 'finder').toString().toLowerCase().trim();
    return role == 'finder';
  }

  static String roleLabelFromUserData(Map<String, dynamic> userData) {
    return isWorkerRoleFromUserData(userData) ? 'Worker' : 'Supporter';
  }
}
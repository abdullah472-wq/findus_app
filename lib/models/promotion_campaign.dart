// lib/models/promotion_campaign.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionType {
  static const profile = 'profile'; // প্রোফাইল বুস্ট
  static const jobs = 'jobs';       // জব পোস্ট বুস্ট
  static const instant = 'instant'; // ২৪ ঘন্টার ইনস্ট্যান্ট বুস্ট
}

class PromotionStatus {
  static const active = 'active';
  static const pending = 'pending';
  static const ended = 'ended';
  static const paused = 'paused';
}

class PromotionCampaign {
  final String id;          // Firestore doc id
  final String ownerId;     // user uid
  final String type;        // PromotionType.profile / jobs / instant
  final String targetId;    // profileId বা postId (এখন জন্য uid-ই রাখতে পারো)
  final String targetArea;  // 'nearby' | 'city'
  final int days;
  final double dailyBudget;
  final double totalBudget;

  final String status;      // PromotionStatus.*
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromotionCampaign({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.targetId,
    required this.targetArea,
    required this.days,
    required this.dailyBudget,
    required this.totalBudget,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convenience: এখন active আছে কি না
  bool get isActive {
    final now = DateTime.now();
    return status == PromotionStatus.active &&
        !now.isBefore(startAt) &&
        !now.isAfter(endAt);
  }

  PromotionCampaign copyWith({
    String? id,
    String? status,
    double? totalBudget,
    DateTime? updatedAt,
  }) {
    return PromotionCampaign(
      id: id ?? this.id,
      ownerId: ownerId,
      type: type,
      targetId: targetId,
      targetArea: targetArea,
      days: days,
      dailyBudget: dailyBudget,
      totalBudget: totalBudget ?? this.totalBudget,
      status: status ?? this.status,
      startAt: startAt,
      endAt: endAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore → Model
  factory PromotionCampaign.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;
    return PromotionCampaign(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      type: data['type'] as String,
      targetId: data['targetId'] as String,
      targetArea: data['targetArea'] as String,
      days: (data['days'] as num).toInt(),
      dailyBudget: (data['dailyBudget'] as num).toDouble(),
      totalBudget: (data['totalBudget'] as num).toDouble(),
      status: data['status'] as String,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Model → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'type': type,
      'targetId': targetId,
      'targetArea': targetArea,
      'days': days,
      'dailyBudget': dailyBudget,
      'totalBudget': totalBudget,
      'status': status,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
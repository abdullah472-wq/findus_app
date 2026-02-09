import 'package:flutter/foundation.dart';
// ✅ ইম্পোর্ট অ্যাড করা হয়েছে
import 'package:findus_app/badge/badge_model.dart';

/// রিসেট পিরিয়ড এনাম (Daily, Weekly, None)
enum ResetPeriod { none, daily, weekly, monthly }

/// 🎯 Achievement Definition (Static Config)
@immutable
class AchievementDef {
  final String id;
  final String title;
  final String description;
  final int target;
  final int xpReward;
  final bool workerOnly;
  final bool supporterOnly;

  final bool teamOnly;
  final bool proOnly;

  final ResetPeriod resetPeriod;
  final int minPoints;

  final String? chainKey;
  final int chainStage;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.xpReward,
    this.workerOnly = false,
    this.supporterOnly = false,
    this.teamOnly = false,
    this.proOnly = false,
    this.resetPeriod = ResetPeriod.none,
    this.minPoints = 0,
    this.chainKey,
    this.chainStage = 1,
  });
}

/// 📊 Achievement State (User Progress)
@immutable
class AchievementState {
  final AchievementDef def;
  final int progress;
  final bool claimed;
  final DateTime? lastUpdated;
  final bool isLocked;

  const AchievementState({
    required this.def,
    this.progress = 0,
    this.claimed = false,
    this.lastUpdated,
    this.isLocked = false,
  });

  bool get isCompleted => progress >= def.target;

  AchievementState copyWith({
    int? progress,
    bool? claimed,
    DateTime? lastUpdated,
    bool? isLocked,
  }) {
    return AchievementState(
      def: def,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': def.id,
    'progress': progress,
    'claimed': claimed,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory AchievementState.fromJson(AchievementDef def, Map<String, dynamic> json) {
    return AchievementState(
      def: def,
      progress: json['progress'] as int? ?? 0,
      claimed: json['claimed'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'])
          : null,
      isLocked: false,
    );
  }
}
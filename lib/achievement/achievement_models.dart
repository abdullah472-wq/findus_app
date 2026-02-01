import 'package:flutter/foundation.dart';

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
  final ResetPeriod resetPeriod;
  final int minPoints; // মিনিমাম কত পয়েন্ট থাকলে এই টাস্ক আনলক হবে

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.xpReward,
    this.workerOnly = false,
    this.supporterOnly = false,
    this.resetPeriod = ResetPeriod.none,
    this.minPoints = 0,
  });
}

/// 📊 Achievement State (User Progress)
@immutable
class AchievementState {
  final AchievementDef def;
  final int progress;
  final bool claimed;
  final DateTime? lastUpdated;

  const AchievementState({
    required this.def,
    this.progress = 0,
    this.claimed = false,
    this.lastUpdated,
  });

  bool get isCompleted => progress >= def.target;

  AchievementState copyWith({
    int? progress,
    bool? claimed,
    DateTime? lastUpdated,
  }) {
    return AchievementState(
      def: def,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
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
    );
  }
}
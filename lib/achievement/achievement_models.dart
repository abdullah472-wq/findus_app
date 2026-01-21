// lib/models/achievement_models.dart


/// Achievement এর টাইপ
enum AchievementType {
  /// একবারের: complete হলেই done; XP একবারই
  oneTime,

  /// incremental: লক্ষ্যমাত্রা পর্যন্ত progress (যেমন 0/10, 7/10...)
  incremental,
}

/// Reset period: daily / weekly / none
enum ResetPeriod {
  none,
  daily,
  weekly,
}

/// Config: প্রতিটা achievement/quest define করার data
class AchievementDefinition {
  final String id; // unique key, e.g. "daily_open_app"
  final String title;
  final String description;
  final int xpReward;
  final AchievementType type;
  final int target; // incremental এর জন্য; oneTime এ 1 রাখো
  final ResetPeriod resetPeriod;
  final bool workerOnly;
  final bool supporterOnly;
  final int minPoints; // global XP gating এর জন্য (optional)

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    required this.target,
    this.resetPeriod = ResetPeriod.none,
    this.workerOnly = false,
    this.supporterOnly = false,
    this.minPoints = 0,
  });
}

/// Runtime state: progress + claimed + lastUpdated
class AchievementState {
  final AchievementDefinition def;
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

  /// JSON এ save/load করার জন্য
  Map<String, dynamic> toJson() {
    return {
      'id': def.id,
      'progress': progress,
      'claimed': claimed,
      'lastUpdated':
      lastUpdated?.millisecondsSinceEpoch,
    };
  }

  static AchievementState fromJson(
      AchievementDefinition def,
      Map<String, dynamic> json,
      ) {
    return AchievementState(
      def: def,
      progress: (json['progress'] ?? 0) as int,
      claimed: (json['claimed'] ?? false) as bool,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] as int,
      ),
    );
  }
}
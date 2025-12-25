// lib/models/badge_model.dart

enum BadgeLevel { bronze, silver, gold, platinum, diamond }

class BadgeProgress {
  final BadgeLevel level;
  final int totalPoints;
  final int nextLevelPoints;

  const BadgeProgress({
    required this.level,
    required this.totalPoints,
    required this.nextLevelPoints,
  });

  /// Next level-এর দিকে progress (0.0 → 1.0)
  double get percentToNext {
    if (nextLevelPoints <= 0) return 1.0;
    final ratio = totalPoints / nextLevelPoints;
    if (ratio < 0) return 0.0;
    if (ratio > 1) return 1.0;
    return ratio;
  }
}
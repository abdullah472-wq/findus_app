class UserAchievements {
  final int totalReviewsGiven;
  final int totalSupports;
  final int totalTrustedScore;
  final int totalVerifiedScore;
  final int totalPaymentsDone;

  final int currentPoints;       // Badge point
  final int nextBadgeTarget;     // পরের ব্যাজের জন্য টার্গেট পয়েন্ট

  UserAchievements({
    required this.totalReviewsGiven,
    required this.totalSupports,
    required this.totalTrustedScore,
    required this.totalVerifiedScore,
    required this.totalPaymentsDone,
    required this.currentPoints,
    required this.nextBadgeTarget,
  });
}
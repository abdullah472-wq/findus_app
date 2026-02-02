// lib/achievement/achievements_config.dart
import 'achievement_models.dart';

class AchievementsConfig {
  static List<AchievementDef> get all => [
    // ==================================================
    // 🎯 DAILY QUESTS (প্রতিদিন রিসেট হবে)
    // ==================================================
    const AchievementDef(
      id: 'daily_login',
      title: 'Daily Check-in',
      description: 'Open the app daily to earn points',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'daily_explore',
      title: 'Daily Explorer',
      description: 'Browse the map for finding workers',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'daily_share',
      title: 'Social Sharer',
      description: 'Share your profile on social media',
      target: 1,
      xpReward: 100,
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'daily_job_view',
      title: 'Job Browser',
      description: 'View 5 job listings',
      target: 5,
      xpReward: 75,
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),

    // ==================================================
    // 📅 WEEKLY QUESTS (সাপ্তাহিক রিসেট)
    // ==================================================
    const AchievementDef(
      id: 'weekly_referral',
      title: 'Weekly Referral',
      description: 'Refer a friend to join FindUs',
      target: 1,
      xpReward: 500,
      resetPeriod: ResetPeriod.weekly,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'weekly_complete_jobs',
      title: 'Weekly Worker',
      description: 'Complete 3 jobs this week',
      target: 3,
      xpReward: 300,
      resetPeriod: ResetPeriod.weekly,
      workerOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'weekly_post_jobs',
      title: 'Weekly Employer',
      description: 'Post 2 jobs this week',
      target: 2,
      xpReward: 400,
      resetPeriod: ResetPeriod.weekly,
      supporterOnly: true,
      minPoints: 1000,
    ),

    // ==================================================
    // 🏆 ONE-TIME ACHIEVEMENTS (আনলক হবে ধাপে ধাপে)
    // ==================================================

    // 🥉 BRONZE LEVEL (0-1000 XP)
    const AchievementDef(
      id: 'setup_profile',
      title: 'Profile Perfectionist',
      description: 'Complete your profile with photo and bio',
      target: 1,
      xpReward: 500,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'first_map_view',
      title: 'Map Explorer',
      description: 'Explore the map for the first time',
      target: 1,
      xpReward: 100,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'add_skills',
      title: 'Skill Master',
      description: 'Add at least 3 skills to your profile',
      target: 1,
      xpReward: 300,
      workerOnly: true,
      minPoints: 0,
    ),

    // 🥈 SILVER LEVEL (1000-10000 XP)
    const AchievementDef(
      id: 'first_job_complete',
      title: 'First Earnings',
      description: 'Complete your first job successfully',
      target: 1,
      xpReward: 2000,
      workerOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'first_job_post',
      title: 'First Job Poster',
      description: 'Post your first job requirement',
      target: 1,
      xpReward: 1500,
      supporterOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'rating_4_star',
      title: 'Quality Worker',
      description: 'Get a 4+ star rating on any job',
      target: 1,
      xpReward: 1000,
      workerOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'complete_5_jobs',
      title: 'Rising Star',
      description: 'Complete 5 jobs successfully',
      target: 5,
      xpReward: 2500,
      workerOnly: true,
      minPoints: 1000,
    ),

    // 🥇 GOLD LEVEL (10000-50000 XP)
    const AchievementDef(
      id: 'portfolio_upload',
      title: 'Portfolio Pro',
      description: 'Upload your portfolio/CV',
      target: 1,
      xpReward: 3000,
      workerOnly: true,
      minPoints: 10000,
    ),
    const AchievementDef(
      id: 'rating_4.5_star',
      title: 'Top Rated',
      description: 'Maintain 4.5+ average rating',
      target: 1,
      xpReward: 5000,
      workerOnly: true,
      minPoints: 10000,
    ),
    const AchievementDef(
      id: 'complete_20_jobs',
      title: 'Experienced Worker',
      description: 'Complete 20 jobs successfully',
      target: 20,
      xpReward: 8000,
      workerOnly: true,
      minPoints: 10000,
    ),
    const AchievementDef(
      id: 'post_10_jobs',
      title: 'Active Employer',
      description: 'Post 10 jobs',
      target: 10,
      xpReward: 6000,
      supporterOnly: true,
      minPoints: 10000,
    ),

    // 💎 PLATINUM LEVEL (50000-100000 XP) - DOCUMENT VERIFICATION
    const AchievementDef(
      id: 'kyc_verify',
      title: 'KYC Verified',
      description: 'Upload NID/Passport for verification',
      target: 1,
      xpReward: 20000,
      minPoints: 50000,
    ),
    const AchievementDef(
      id: 'driving_license',
      title: 'Licensed Professional',
      description: 'Upload valid Driving License',
      target: 1,
      xpReward: 15000,
      minPoints: 50000,
    ),
    const AchievementDef(
      id: 'education_certificate',
      title: 'Certified Expert',
      description: 'Upload education certificates',
      target: 1,
      xpReward: 10000,
      minPoints: 50000,
    ),
    const AchievementDef(
      id: 'complete_50_jobs',
      title: 'Veteran Worker',
      description: 'Complete 50 jobs with 4+ rating',
      target: 50,
      xpReward: 15000,
      workerOnly: true,
      minPoints: 50000,
    ),

    // 👑 DIAMOND LEVEL (100000+ XP) - ELITE ACHIEVEMENTS
    const AchievementDef(
      id: 'top_rated_100',
      title: 'Legendary Worker',
      description: 'Complete 100 jobs with 5-star rating',
      target: 100,
      xpReward: 50000,
      workerOnly: true,
      minPoints: 100000,
    ),
    const AchievementDef(
      id: 'elite_employer',
      title: 'Elite Employer',
      description: 'Post 50+ jobs with 90% completion rate',
      target: 50,
      xpReward: 40000,
      supporterOnly: true,
      minPoints: 100000,
    ),
    const AchievementDef(
      id: 'referral_champion',
      title: 'Referral Champion',
      description: 'Refer 10+ friends who complete profile',
      target: 10,
      xpReward: 30000,
      minPoints: 100000,
    ),
    const AchievementDef(
      id: 'perfect_rating',
      title: 'Perfect Score',
      description: 'Maintain 5.0 rating for 20+ jobs',
      target: 20,
      xpReward: 25000,
      workerOnly: true,
      minPoints: 100000,
    ),

    // ==================================================
    // 🎮 SPECIAL CHALLENGES (বিশেষ চ্যালেঞ্জ)
    // ==================================================
    const AchievementDef(
      id: 'streak_7_days',
      title: 'Weekly Warrior',
      description: 'Maintain 7-day login streak',
      target: 7,
      xpReward: 1000,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'streak_30_days',
      title: 'Monthly Champion',
      description: 'Maintain 30-day login streak',
      target: 30,
      xpReward: 5000,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'quick_completion',
      title: 'Speed Demon',
      description: 'Complete a job within 24 hours of posting',
      target: 1,
      xpReward: 1500,
      workerOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'repeat_client',
      title: 'Trusted Partner',
      description: 'Get hired by same client 3+ times',
      target: 3,
      xpReward: 2000,
      workerOnly: true,
      minPoints: 5000,
    ),
    const AchievementDef(
      id: 'weekend_warrior',
      title: 'Weekend Warrior',
      description: 'Complete jobs on both Saturday and Sunday',
      target: 2,
      xpReward: 1200,
      workerOnly: true,
      minPoints: 1000,
    ),
    const AchievementDef(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Complete a job before 10 AM',
      target: 1,
      xpReward: 800,
      workerOnly: true,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Complete a job after 10 PM',
      target: 1,
      xpReward: 800,
      workerOnly: true,
      minPoints: 0,
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ✅ ক্যাটাগরি অনুযায়ী ফিল্টার করার মেথড
  static List<AchievementDef> getByCategory(String category) {
    switch (category) {
      case 'daily':
        return all.where((e) => e.resetPeriod == ResetPeriod.daily).toList();
      case 'weekly':
        return all.where((e) => e.resetPeriod == ResetPeriod.weekly).toList();
      case 'onetime':
        return all.where((e) => e.resetPeriod == ResetPeriod.none).toList();
      default:
        return all;
    }
  }

  // ✅ লেভেল অনুযায়ী ফিল্টার করার মেথড
  static List<AchievementDef> getByLevel(int minPoints) {
    if (minPoints >= 100000) {
      return all.where((e) => e.minPoints >= 100000).toList();
    } else if (minPoints >= 50000) {
      return all.where((e) => e.minPoints >= 50000 && e.minPoints < 100000).toList();
    } else if (minPoints >= 10000) {
      return all.where((e) => e.minPoints >= 10000 && e.minPoints < 50000).toList();
    } else if (minPoints >= 1000) {
      return all.where((e) => e.minPoints >= 1000 && e.minPoints < 10000).toList();
    } else {
      return all.where((e) => e.minPoints == 0).toList();
    }
  }

  // ✅ রোল অনুযায়ী ফিল্টার করার মেথড
  static List<AchievementDef> getByRole(bool isWorker) {
    if (isWorker) {
      return all.where((e) => !e.supporterOnly).toList();
    } else {
      return all.where((e) => !e.workerOnly).toList();
    }
  }
}
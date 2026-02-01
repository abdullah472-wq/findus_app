// lib/achievement/achievements_config.dart

import 'achievement_models.dart';

class AchievementsConfig {
  static List<AchievementDef> get all => [
    // ==================================================
    // 🏅 LEVEL 1: NEWBIE TO BRONZE (Target: 1,000 XP)
    // ==================================================

    // 1. Daily Engagement (Easy XP)
    const AchievementDef(
      id: 'daily_login',
      title: 'Daily Check-in',
      description: 'Open the app daily to earn points.',
      target: 1,
      xpReward: 50, // 20 days = 1000 XP
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),
    const AchievementDef(
      id: 'explore_map',
      title: 'Explorer',
      description: 'Browse the map for finding workers.',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
      minPoints: 0,
    ),

    // 2. Profile Setup (One-time Boost)
    const AchievementDef(
      id: 'setup_profile',
      title: 'Identity Verified',
      description: 'Add profile picture and bio.',
      target: 1,
      xpReward: 500, // Instant half-way to Bronze
      minPoints: 0,
    ),

    // ==================================================
    // 🥉 LEVEL 2: BRONZE TO SILVER (Target: 10,000 XP)
    // ==================================================

    // 1. First Job Success
    const AchievementDef(
      id: 'first_job',
      title: 'First Earnings',
      description: 'Complete your first job successfully.',
      target: 1,
      xpReward: 2000, // Big jump
      workerOnly: true,
      minPoints: 1000, // Bronze badge required
    ),

    // 2. Consistent Daily (Increased Reward)
    const AchievementDef(
      id: 'daily_share',
      title: 'Social Bee',
      description: 'Share your profile on social media.',
      target: 1,
      xpReward: 200,
      resetPeriod: ResetPeriod.daily,
      minPoints: 1000,
    ),

    // 3. Post Creation
    const AchievementDef(
      id: 'create_post',
      title: 'Job Poster',
      description: 'Post a job requirement or gig.',
      target: 1,
      xpReward: 1000,
      minPoints: 1000,
    ),

    // ==================================================
    // 🥈 LEVEL 3: SILVER TO GOLD (Target: 50,000 XP)
    // ==================================================
    // Note: No Documents Required Yet

    const AchievementDef(
      id: 'ten_jobs',
      title: 'Rising Star',
      description: 'Complete 10 jobs with 4+ rating.',
      target: 10,
      xpReward: 15000, // Massive boost
      workerOnly: true,
      minPoints: 10000,
    ),

    const AchievementDef(
      id: 'refer_friend',
      title: 'Community Leader',
      description: 'Refer a friend to join FindUs.',
      target: 1,
      xpReward: 5000, // Per referral
      resetPeriod: ResetPeriod.weekly, // Once a week
      minPoints: 10000,
    ),

    // ==================================================
    // 🥇 LEVEL 4: GOLD TO PLATINUM (Target: 100,000 XP)
    // ==================================================
    // 🔥 MANDATORY DOCUMENTS HERE 🔥

    const AchievementDef(
      id: 'kyc_verify',
      title: 'KYC Verified',
      description: 'Upload NID/Passport for verification.',
      target: 1,
      xpReward: 20000, // Huge reward for trust
      minPoints: 50000,
    ),

    const AchievementDef(
      id: 'driving_license',
      title: 'Licensed Pro',
      description: 'Upload valid Driving License.',
      target: 1,
      xpReward: 15000,
      minPoints: 50000,
    ),

    // ==================================================
    // 💎 LEVEL 5: PLATINUM TO DIAMOND (Target: 1,000,000 XP)
    // ==================================================

    const AchievementDef(
      id: 'top_rated_100',
      title: 'Legendary Worker',
      description: 'Complete 100 jobs with 5-star rating.',
      target: 100,
      xpReward: 100000, // The ultimate prize
      workerOnly: true,
      minPoints: 100000,
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
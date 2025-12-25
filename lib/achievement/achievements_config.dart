// lib/config/achievements_config.dart

import 'package:findus_app/achievement//achievement_models.dart';

class AchievementsConfig {
  /// সব achievements / quests
  static const List<AchievementDefinition> all = [
    // ---------- COMMON / DAILY ----------
    AchievementDefinition(
      id: 'daily_open_app',
      title: 'Daily Check‑in',
      description: 'Open FINDUS today to collect XP.',
      xpReward: 20,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.daily,
    ),

    AchievementDefinition(
      id: 'daily_view_map',
      title: 'Explore the map',
      description: 'Open the Explore map and move around.',
      xpReward: 30,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.daily,
    ),

    // ---------- KYC / PROFILE ----------
    AchievementDefinition(
      id: 'kyc_verification',
      title: 'KYC Verified',
      description:
      'Complete KYC verification to earn extra trust & XP.',
      xpReward: 1000,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.none,
    ),

    AchievementDefinition(
      id: 'driving_license_upload',
      title: 'Driving License',
      description:
      'Upload your driving license as an extra ID document.',
      xpReward: 500,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.none,
    ),

    AchievementDefinition(
      id: 'create_cv',
      title: 'Create your CV',
      description:
      'Fill up your digital CV inside FINDUS.',
      xpReward: 300,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.none,
    ),

    // ---------- WORKER / EARNER ----------
    AchievementDefinition(
      id: 'worker_first_job',
      title: 'First Job Completed',
      description:
      'Complete your first job as a worker/earner.',
      xpReward: 200,
      type: AchievementType.oneTime,
      target: 1,
      resetPeriod: ResetPeriod.none,
      workerOnly: true,
    ),

    AchievementDefinition(
      id: 'worker_complete_10_jobs',
      title: '10 Jobs Completed',
      description:
      'Complete 10 total jobs as a worker.',
      xpReward: 600,
      type: AchievementType.incremental,
      target: 10,
      resetPeriod: ResetPeriod.none,
      workerOnly: true,
    ),

    AchievementDefinition(
      id: 'worker_complete_50_jobs',
      title: '50 Jobs Completed',
      description:
      'Complete 50 total jobs as a worker.',
      xpReward: 2000,
      type: AchievementType.incremental,
      target: 50,
      resetPeriod: ResetPeriod.none,
      workerOnly: true,
      minPoints: 2000, // কিছু XP পর এইটা আসবে
    ),

    // ---------- SUPPORTER / MAKER ----------
    AchievementDefinition(
      id: 'supporter_first_post',
      title: 'First Job Posted',
      description:
      'Post your first support/job request.',
      xpReward: 150,
      type: AchievementType.oneTime,
      target: 1,
      supporterOnly: true,
    ),

    AchievementDefinition(
      id: 'supporter_hire_10_workers',
      title: 'Hire 10 Workers',
      description:
      'Successfully hire workers for 10 jobs.',
      xpReward: 700,
      type: AchievementType.incremental,
      target: 10,
      supporterOnly: true,
    ),

    // ---------- REVIEW / TRUST ----------
    AchievementDefinition(
      id: 'give_5_reviews',
      title: 'Helpful Reviewer',
      description:
      'Give 5 rating & review to workers/supporters.',
      xpReward: 500,
      type: AchievementType.incremental,
      target: 5,
      resetPeriod: ResetPeriod.none,
    ),

    AchievementDefinition(
      id: 'give_20_reviews',
      title: 'Top Reviewer',
      description:
      'Give 20 detailed reviews (4★ or higher).',
      xpReward: 1500,
      type: AchievementType.incremental,
      target: 20,
      resetPeriod: ResetPeriod.none,
      minPoints: 2000,
    ),
  ];

  static AchievementDefinition? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
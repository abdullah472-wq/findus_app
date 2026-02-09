import 'achievement_models.dart';

class AchievementsConfig {
  static List<AchievementDef> get all => [
    // ==================================================
    // 🎯 DAILY QUESTS (সহজ ও দ্রুত)
    // ==================================================
    const AchievementDef(
      id: 'daily_login',
      title: 'Daily Check-in',
      description: 'Open the app daily to earn points',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_message',
      title: 'Conversation Starter',
      description: 'Send a message or reply',
      target: 1,
      xpReward: 60,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_view_jobs',
      title: 'Window Shopper',
      description: 'View details of 3 jobs',
      target: 3,
      xpReward: 70,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_explore',
      title: 'Map Explorer',
      description: 'Browse the map for 1 minute',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_share',
      title: 'Social Sharer',
      description: 'Share a job or profile',
      target: 1,
      xpReward: 100,
      resetPeriod: ResetPeriod.daily,
    ),

    // ==================================================
    // 📅 WEEKLY QUESTS (চেইন লজিক)
    // ==================================================
    const AchievementDef(
      id: 'weekly_daily_chest',
      title: 'Weekly Consistency',
      description: 'Complete 20 daily quests this week',
      target: 20,
      xpReward: 1500,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_apply',
      title: 'Active Seeker',
      description: 'Apply to 5 jobs this week',
      target: 5,
      xpReward: 400,
      workerOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_post_free',
      title: 'Weekly Hiring',
      description: 'Post 3 job this week',
      target: 3,
      xpReward: 300,
      supporterOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // ==================================================
    // 🏢 TEAM & PRO QUESTS (বিজনেস প্ল্যান)
    // ==================================================
    const AchievementDef(
      id: 'team_daily_active',
      title: 'Team Huddle',
      description: '2 Team members active today',
      target: 1,
      xpReward: 200,
      teamOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'team_weekly_hire',
      title: 'Recruitment Drive',
      description: 'Shortlist 10 candidates as a team',
      target: 10,
      xpReward: 1000,
      teamOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // 🔒 LOCKED QUESTS (Upselling for Pro)
    const AchievementDef(
      id: 'pro_mass_post',
      title: 'Power Poster',
      description: 'Post 5 jobs in a week (Pro Only)',
      target: 5,
      xpReward: 2000,
      supporterOnly: true,
      proOnly: true, // 🔒 ফ্রি ইউজারদের জন্য লক থাকবে
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'pro_top_candidate',
      title: 'Elite Hunter',
      description: 'Contact 10 candidates (Pro Only)',
      target: 10,
      xpReward: 1500,
      supporterOnly: true,
      proOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // ==================================================
    // 🏆 LONG-TERM CHAINS (Profile Setup)
    // ==================================================
    const AchievementDef(
      id: 'lt_profile_s1',
      chainKey: 'lt_profile',
      chainStage: 1,
      title: 'Profile Setup I',
      description: 'Basic info & photo',
      target: 1,
      xpReward: 300,
    ),
    const AchievementDef(
      id: 'lt_profile_s2',
      chainKey: 'lt_profile',
      chainStage: 2,
      title: 'Profile Setup II',
      description: 'Add Bio & Location details',
      target: 1,
      xpReward: 700,
    ),
    const AchievementDef(
      id: 'lt_profile_s3',
      chainKey: 'lt_profile',
      chainStage: 3,
      title: 'Profile Setup III',
      description: 'Add Skills & Portfolio',
      target: 1,
      xpReward: 1200,
    ),

    // 🏆 LONG-TERM CHAINS (Job Journey - Worker)
    const AchievementDef(
      id: 'lt_jobs_s1',
      chainKey: 'lt_jobs',
      chainStage: 1,
      title: 'Job Journey I',
      description: 'Complete 1 job',
      target: 1,
      xpReward: 500,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_jobs_s2',
      chainKey: 'lt_jobs',
      chainStage: 2,
      title: 'Job Journey II',
      description: 'Complete 10 jobs',
      target: 10,
      xpReward: 2000,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_jobs_s3',
      chainKey: 'lt_jobs',
      chainStage: 3,
      title: 'Job Journey III',
      description: 'Complete 50 jobs',
      target: 50,
      xpReward: 5000,
      workerOnly: true,
    ),

    // ==================================================
    // 🏆 EXISTING LONG-TERM CHAINS (Profile & Jobs)
    // ==================================================
    // ... আপনার আগের lt_profile এবং lt_jobs কোডগুলো এখানে থাকবে ...

    // ==================================================
    // 🌟 NEW 1: REPUTATION BUILDER (Ratings - Everyone)
    // ==================================================
    const AchievementDef(
      id: 'lt_rating_s1',
      chainKey: 'lt_rating',
      chainStage: 1,
      title: 'Rising Star',
      description: 'Receive your first 50-star rating',
      target: 50,
      xpReward: 1000,
    ),
    const AchievementDef(
      id: 'lt_rating_s2',
      chainKey: 'lt_rating',
      chainStage: 2,
      title: 'Trusted User',
      description: 'Receive 500 positive ratings',
      target: 500,
      xpReward: 2500,
    ),
    const AchievementDef(
      id: 'lt_rating_s3',
      chainKey: 'lt_rating',
      chainStage: 3,
      title: 'Community Legend',
      description: 'Receive 1000 positive ratings',
      target: 1000,
      xpReward: 5000, // Big Reward!
    ),

    // ==================================================
    // 🤝 NEW 2: SOCIAL CONNECTOR (Referrals - Everyone)
    // ==================================================
    const AchievementDef(
      id: 'lt_invite_s1',
      chainKey: 'lt_invite',
      chainStage: 1,
      title: 'Friendly Face',
      description: 'Refer 50 friend to the app',
      target: 50,
      xpReward: 1500,
    ),
    const AchievementDef(
      id: 'lt_invite_s2',
      chainKey: 'lt_invite',
      chainStage: 2,
      title: 'Community Builder',
      description: 'Refer 500 friends',
      target: 500,
      xpReward: 5000,
    ),
    const AchievementDef(
      id: 'lt_invite_s3',
      chainKey: 'lt_invite',
      chainStage: 3,
      title: 'Influencer',
      description: 'Refer 1000 friends',
      target: 1000,
      xpReward: 10000,
    ),

    // ==================================================
    // 💬 NEW 3: NETWORK MASTER (Chat/Messages - Everyone)
    // ==================================================
    const AchievementDef(
      id: 'lt_chat_s1',
      chainKey: 'lt_chat',
      chainStage: 1,
      title: 'Hello World',
      description: 'Start conversations with 100 people',
      target: 100,
      xpReward: 1500,
    ),
    const AchievementDef(
      id: 'lt_chat_s2',
      chainKey: 'lt_chat',
      chainStage: 2,
      title: 'Networker',
      description: 'Start conversations with 1000 people',
      target: 1000,
      xpReward: 10000,
    ),
    const AchievementDef(
      id: 'lt_chat_s3',
      chainKey: 'lt_chat',
      chainStage: 3,
      title: 'Communication Hub',
      description: 'Start conversations with 5000 people',
      target: 5000,
      xpReward: 50000,
    ),

    // ==================================================
    // 📝 NEW 4: AMBITIOUS APPLICANT (Worker Only)
    // ==================================================
    const AchievementDef(
      id: 'lt_apply_s1',
      chainKey: 'lt_apply',
      chainStage: 1,
      title: 'Job Hunter I',
      description: 'Apply to 50 jobs',
      target: 50,
      xpReward: 2500,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_apply_s2',
      chainKey: 'lt_apply',
      chainStage: 2,
      title: 'Job Hunter II',
      description: 'Apply to 200 jobs',
      target: 200,
      xpReward: 5000,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_apply_s3',
      chainKey: 'lt_apply',
      chainStage: 3,
      title: 'Job Hunter III',
      description: 'Apply to 1000 jobs',
      target: 1000,
      xpReward: 10000,
      workerOnly: true,
    ),

    // ==================================================
    // 💼 NEW 5: THE RECRUITER (Employer Only)
    // ==================================================
    const AchievementDef(
      id: 'lt_hire_s1',
      chainKey: 'lt_hire',
      chainStage: 1,
      title: 'First Hire',
      description: 'Hire 50 person successfully',
      target: 50,
      xpReward: 1000,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s2',
      chainKey: 'lt_hire',
      chainStage: 2,
      title: 'Team Builder',
      description: 'Hire 200 people',
      target: 200,
      xpReward: 2500,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s3',
      chainKey: 'lt_hire',
      chainStage: 3,
      title: 'Business Tycoon',
      description: 'Hire 1000 people',
      target: 1000,
      xpReward: 15000,
      supporterOnly: true,
    ),

    // ==================================================
    // 🛠 WORKER: JOB COMPLETION CHAIN
    // ==================================================

    // 1. Daily (প্রতিদিন ১টা কাজ)
    const AchievementDef(
      id: 'daily_complete_job',
      title: 'Hard Worker',
      description: 'Complete 1 job today',
      target: 1,
      xpReward: 100,
      workerOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),

    // 2. Weekly (সপ্তাহে ৩টা কাজ)
    const AchievementDef(
      id: 'weekly_complete_jobs',
      title: 'Job Marathon',
      description: 'Complete 3 jobs this week',
      target: 3,
      xpReward: 500,
      workerOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // 3. Long-Term Chain (লাইফটাইম প্রগ্রেস)
    const AchievementDef(
      id: 'lt_jobs_s1',
      chainKey: 'lt_jobs',
      chainStage: 1,
      title: 'First Earnings',
      description: 'Complete 20 jobs',
      target: 20,
      xpReward: 2500,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_jobs_s2',
      chainKey: 'lt_jobs',
      chainStage: 2,
      title: 'Professional',
      description: 'Complete 50 jobs',
      target: 50,
      xpReward: 10000,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_jobs_s3',
      chainKey: 'lt_jobs',
      chainStage: 3,
      title: 'Veteran Worker',
      description: 'Complete 200 jobs',
      target: 200,
      xpReward: 15000,
      workerOnly: true,
    ),

    // ==================================================
    // 💼 EMPLOYER: HIRING CHAIN
    // ==================================================

    // 1. Daily (প্রতিদিন ১ জনকে হায়ার)
    const AchievementDef(
      id: 'daily_hire',
      title: 'Daily Recruiter',
      description: 'Hire 1 person today',
      target: 1,
      xpReward: 150,
      supporterOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),

    // 2. Weekly (সপ্তাহে ৩ জনকে হায়ার)
    const AchievementDef(
      id: 'weekly_hire',
      title: 'Hiring Spree',
      description: 'Hire 3 people this week',
      target: 3,
      xpReward: 600,
      supporterOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // 3. Long-Term Chain (লাইফটাইম হায়ার)
    const AchievementDef(
      id: 'lt_hire_s1',
      chainKey: 'lt_hire',
      chainStage: 1,
      title: 'First Hire',
      description: 'Hire 20 people',
      target: 20,
      xpReward: 2500,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s2',
      chainKey: 'lt_hire',
      chainStage: 2,
      title: 'Team Builder',
      description: 'Hire 50 people',
      target: 50,
      xpReward: 10000,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s3',
      chainKey: 'lt_hire',
      chainStage: 3,
      title: 'Business Tycoon',
      description: 'Hire 200 people',
      target: 200,
      xpReward: 20000,
      supporterOnly: true,
    ),

    // 🎁 BONUS (Side Missions - No Chain)
    const AchievementDef(
      id: 'bonus_rate_us',
      title: 'Fan of FindUs',
      description: 'Rate us on Play Store',
      target: 1,
      xpReward: 500,
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
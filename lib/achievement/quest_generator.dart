// lib/achievement/quest_generator.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/achievement/achievements_config.dart';

class QuestGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Personalized quests generate করা
  static Future<List<AchievementDef>> generatePersonalizedQuests({
    required bool isWorker,
    required int userPoints,
    required List<String> completedQuestIds,
  }) async {
    final personalizedQuests = <AchievementDef>[];
    final userId = _auth.currentUser?.uid;

    if (userId == null) return personalizedQuests;

    try {
      // User stats fetch করা
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userStats = userDoc.data() ?? {};

      final jobsCompleted = (userStats['jobsCompleted'] ?? 0) as int;
      final loginStreak = (userStats['loginStreak'] ?? 0) as int;
      final averageRating = (userStats['averageRating'] ?? 0.0).toDouble();
      final referralCount = (userStats['referralCount'] ?? 0) as int;

      // 1. First Job Encouragement
      if (isWorker && jobsCompleted == 0 && !completedQuestIds.contains('first_job_complete')) {
        personalizedQuests.add(
          const AchievementDef(
            id: 'first_job_encouragement',
            title: 'Get Started!',
            description: 'Complete your first job to unlock amazing rewards',
            target: 1,
            xpReward: 1000,
            workerOnly: true,
            minPoints: 0,
          ),
        );
      }

      // 2. Streak Encouragement
      if (loginStreak >= 3 && loginStreak < 7 && !completedQuestIds.contains('streak_7_days')) {
        personalizedQuests.add(
          AchievementDef(
            id: 'streak_${loginStreak + 1}_days',
            title: 'Keep the Streak!',
            description: 'Maintain login streak for ${loginStreak + 1} days',
            target: loginStreak + 1,
            xpReward: (200 * (loginStreak + 1)).toInt(), // ✅ .toInt()
            minPoints: 0,
          ),
        );
      }

      // 3. Rating Improvement
      if (isWorker && averageRating >= 4.0 && averageRating < 4.5) {
        personalizedQuests.add(
          const AchievementDef(
            id: 'rating_improvement',
            title: 'Climb to 4.5!',
            description: 'Improve your average rating to 4.5 stars',
            target: 1,
            xpReward: 1500,
            workerOnly: true,
            minPoints: 1000,
          ),
        );
      }

      // 4. Referral Boost
      if (referralCount >= 3 && referralCount < 5) {
        personalizedQuests.add(
          const AchievementDef(
            id: 'referral_boost',
            title: 'Referral Master',
            description: 'Refer 5 friends to unlock special rewards',
            target: 5,
            xpReward: 2500,
            minPoints: 5000,
          ),
        );
      }

      // 5. Job Completion Milestone
      if (isWorker && jobsCompleted >= 10 && jobsCompleted < 20) {
        personalizedQuests.add(
          AchievementDef(
            id: 'milestone_${jobsCompleted + 5}_jobs',
            title: 'Next Milestone: ${jobsCompleted + 5} Jobs',
            description: 'Complete ${jobsCompleted + 5} jobs to earn bonus XP',
            target: jobsCompleted + 5,
            xpReward: (1000 + (jobsCompleted * 100)).toInt(), // ✅ .toInt()
            workerOnly: true,
            minPoints: userPoints,
          ),
        );
      }

      // 6. Weekend Challenge (Only on Fridays)
      final now = DateTime.now();
      if (now.weekday == DateTime.friday) {
        personalizedQuests.add(
          const AchievementDef(
            id: 'weekend_challenge',
            title: 'Weekend Warrior Challenge',
            description: 'Complete a job this weekend',
            target: 1,
            xpReward: 1200,
            workerOnly: true,
            minPoints: 1000,
            resetPeriod: ResetPeriod.weekly,
          ),
        );
      }

      // 7. Monthly Challenge (First of the month)
      if (now.day == 1) {
        personalizedQuests.add(
          const AchievementDef(
            id: 'monthly_challenge',
            title: 'Monthly Challenge',
            description: 'Complete 5 jobs this month',
            target: 5,
            xpReward: 3000,
            workerOnly: true,
            minPoints: 5000,
          ),
        );
      }

      return personalizedQuests;
    } catch (e) {
      debugPrint('QuestGenerator error: $e');
      return personalizedQuests;
    }
  }

  // ✅ Get all quests including personalized ones
  static Future<List<AchievementDef>> getAllQuestsForUser({
    required bool isWorker,
    required int userPoints,
  }) async {
    // Get standard quests
    final standardQuests = AchievementsConfig.getByRole(isWorker);

    // Get completed quest IDs
    final completedIds = await _getCompletedQuestIds();

    // Generate personalized quests
    final personalizedQuests = await generatePersonalizedQuests(
      isWorker: isWorker,
      userPoints: userPoints,
      completedQuestIds: completedIds,
    );

    // Combine and filter by minPoints
    final allQuests = [...standardQuests, ...personalizedQuests];

    return allQuests.where((quest) {
      // Filter by user points
      if (userPoints < quest.minPoints) return false;

      // Filter by role
      if (quest.workerOnly && !isWorker) return false;
      if (quest.supporterOnly && isWorker) return false;

      return true;
    }).toList();
  }

  // ✅ Get completed quest IDs from Firestore
  static Future<List<String>> _getCompletedQuestIds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completed_quests')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting completed quests: $e'); // ✅ print ব্যবহার করুন
      return [];
    }
  }

  // ✅ Mark quest as completed
  static Future<void> markQuestCompleted(String questId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completed_quests')
          .doc(questId)
          .set({
        'completedAt': FieldValue.serverTimestamp(),
        'questId': questId,
      });
    } catch (e) {
      print('Error marking quest completed: $e'); // ✅ print ব্যবহার করুন
    }
  }
}

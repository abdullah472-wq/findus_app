import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';

import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/screens/profile/earn_post_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/profile/worker_documents_screen.dart';

class _ChainBundle {
  final String chainKey;
  final List<AchievementState> stages;
  _ChainBundle({required this.chainKey, required this.stages});
}

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool _isLoading = true;
  bool _showCompleted = false;

  bool _isWorker = true;
  bool _isPro = false;
  bool _hasTeam = false;
  String _userRole = 'finder';

  int _totalXpEarned = 0;
  int _totalAchievements = 0;
  int _completedAchievements = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  late ConfettiController _confettiController;
  late VoidCallback _badgeListener;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _badgeListener = () {
      if (!mounted) return;
      _updateStats();
      setState(() {});
    };
    BadgeService.badgeNotifier.addListener(_badgeListener);

    // ✅ অ্যাপ ওপেন করলেই চেক করবে সপ্তাহ শেষ হয়েছে কিনা
    _checkWeeklyReset();

    _initializeData();
  }

  // ✅ উইকলি রিসেট ফাংশন (শনিবারে সপ্তাহ শেষ ধরে রবিবারে রিসেট করবে)
  // ✅ উইকলি রিসেট ফাংশন (শুক্রবার শেষ, শনিবার শুরু)
  Future<void> _checkWeeklyReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      final doc = await userRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // ১. আজকের তারিখ নেওয়া
      final now = DateTime.now();

      // ২. বর্তমান সপ্তাহের আইডি বের করা (শনিবার থেকে সপ্তাহ শুরু)
      // 1 week = 604,800,000 ms
      // Epoch Time শুরু হয় Thursday থেকে।
      // বৃহস্পতিবার থেকে শনিবার = ২ দিন।
      // ২ দিন = 172,800,000 ms যোগ করলে সপ্তাহ শনিবার থেকে গণনা শুরু হবে।

      final int currentWeekId = ((now.millisecondsSinceEpoch + 172800000) / 604800000).floor();

      // ৩. ডাটাবেসে সেভ করা গত সপ্তাহের আইডি নেওয়া
      final int lastSavedWeekId = data['last_week_id'] ?? 0;

      // ৪. যদি আজকের সপ্তাহ আইডি আগের চেয়ে বড় হয় (মানে শুক্রবার পার হয়ে শনিবার এসেছে)
      if (currentWeekId > lastSavedWeekId) {
        await userRef.update({
          // ✅ Weekly Progress রিসেট
          'weekly_quest_progress': 0,
          // ✅ নতুন সপ্তাহ আইডি সেভ করা
          'last_week_id': currentWeekId,
          // ✅ উইকলি ক্লেম স্ট্যাটাস রিসেট
          'weekly_quest_claimed': false,
        });
        print("Weekly progress reset successful. New Week ID: $currentWeekId");
      }
    } catch (e) {
      print("Error checking weekly reset: $e");
    }
  }

  Future<void> _initializeData() async {
    try {
      String role = 'finder';

      setState(() {
        _userRole = role;
        _isWorker = (role == 'finder' || role == 'worker');
      });

      _listenUserDoc();
      await _checkAchievements();

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _listenUserDoc();
    }
  }

  Future<void> _checkAchievements() async {
    try {
      final achievements = AchievementService.achievementsNotifier.value;
      if (achievements.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    BadgeService.badgeNotifier.removeListener(_badgeListener);
    _userSub?.cancel();
    super.dispose();
  }

  void _listenUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final plan = (data['subscription_plan'] ?? 'free').toString().toLowerCase();
      final bool isProUser = plan == 'pro' || plan == 'business';
      final teamId = data['team_id'];
      final bool hasTeam = teamId != null && teamId.toString().isNotEmpty;
      final firebaseRole = (data['userRole'] ?? _userRole).toString().toLowerCase();
      final bool isWorker = (firebaseRole == 'finder' || firebaseRole == 'worker');

      final rawXp = data['xpPoints'] ?? 0;
      final int xp = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0;
      BadgeService.setPointsFromServer(xp);

      if (mounted) {
        setState(() {
          _isPro = isProUser;
          _hasTeam = hasTeam;
          _userRole = firebaseRole;
          _isWorker = isWorker;
          _isLoading = false;
        });
        _updateStats();
      }
    }, onError: (error) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _updateStats() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final all = AchievementService.getAllForUser(
      isWorker: _isWorker,
      currentPoints: points,
      isProUser: _isPro,
      hasTeam: _hasTeam,
      ignoreChainGating: true,
    );

    int totalXp = 0;
    int completed = 0;
    for (final st in all) {
      if (st.claimed) {
        totalXp += st.def.xpReward;
        completed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _totalXpEarned = totalXp;
      _totalAchievements = all.length;
      _completedAchievements = completed;
    });
  }

  List<AchievementState> _dailyCore() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final list = AchievementService.getAllForUser(
        isWorker: _isWorker,
        currentPoints: points,
        isProUser: _isPro,
        hasTeam: _hasTeam,
        ignoreChainGating: false
    )
        .where((st) => st.def.resetPeriod == ResetPeriod.daily)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    list.sort((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    return list.take(5).toList();
  }

  List<AchievementState> _dailyBonus() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final list = AchievementService.getAllForUser(
        isWorker: _isWorker,
        currentPoints: points,
        isProUser: _isPro,
        hasTeam: _hasTeam,
        ignoreChainGating: false
    )
        .where((st) => st.def.resetPeriod == ResetPeriod.daily)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    list.sort((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    return list.skip(5).take(2).toList();
  }

  List<AchievementState> _getWeeklyQuests() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final weeklyList = AchievementService.getAllForUser(
        isWorker: _isWorker,
        currentPoints: points,
        isProUser: _isPro,
        hasTeam: _hasTeam
    )
        .where((st) => st.def.resetPeriod == ResetPeriod.weekly)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    weeklyList.sort((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      return b.def.xpReward.compareTo(a.def.xpReward);
    });

    return weeklyList;
  }

  List<_ChainBundle> _longTermChains() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final allLongTerm = AchievementService.getAllForUser(
        isWorker: _isWorker,
        currentPoints: points,
        isProUser: _isPro,
        hasTeam: _hasTeam,
        ignoreChainGating: true
    )
        .where((st) => st.def.resetPeriod == ResetPeriod.none)
        .toList();

    final Map<String, List<AchievementState>> chains = {};
    final List<AchievementState> singles = [];

    for (final st in allLongTerm) {
      if (st.def.chainKey != null && st.def.chainKey!.isNotEmpty) {
        final key = st.def.chainKey!;
        chains.putIfAbsent(key, () => []);
        chains[key]!.add(st);
      } else {
        singles.add(st);
      }
    }

    final List<_ChainBundle> bundles = chains.entries.map((e) {
      final stages = e.value.toList()
        ..sort((a, b) => a.def.chainStage.compareTo(b.def.chainStage));
      return _ChainBundle(chainKey: e.key, stages: stages);
    }).toList();

    for (final st in singles) {
      bundles.add(_ChainBundle(chainKey: st.def.id, stages: [st]));
    }

    bundles.sort((a, b) {
      final aNext = _nextStage(a) ?? a.stages.last;
      final bNext = _nextStage(b) ?? b.stages.last;
      final aClaimable = aNext.isCompleted && !aNext.claimed;
      final bClaimable = bNext.isCompleted && !bNext.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      return _getBundleProgress(b).compareTo(_getBundleProgress(a));
    });

    if (_showCompleted) {
      return bundles.where((b) {
        if (b.stages.length == 1) return b.stages.first.claimed;
        return _claimedStars(b) >= b.stages.length;
      }).toList();
    } else {
      return bundles.where((b) {
        if (b.stages.length == 1) return !b.stages.first.claimed;
        return _claimedStars(b) < b.stages.length;
      }).toList();
    }
  }

  double _getBundleProgress(_ChainBundle b) {
    final next = _nextStage(b);
    if (next == null) return 1.0;
    if (next.def.target == 0) return 0.0;
    return next.progress / next.def.target;
  }

  int _claimedStars(_ChainBundle b) {
    return b.stages.where((s) => s.claimed).length;
  }

  AchievementState? _nextStage(_ChainBundle b) {
    for (final st in b.stages) {
      if (!st.claimed) return st;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_totalAchievements == 0)
            _buildNoAchievementsWidget(isDark)
          else
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHero(isDark),
                  const SizedBox(height: 12),
                  _buildToggle(isDark),
                  const SizedBox(height: 12),

                  _buildSectionTitle("DAILY BOARD", "5 quests + 2 bonus", Icons.today, isDark),
                  _buildDailyBoard(isDark),

                  const SizedBox(height: 18),

                  _buildSectionTitle("WEEKLY BIG MISSION", "Big reward, resets weekly", Icons.date_range, isDark),
                  _buildWeeklyMission(isDark),

                  const SizedBox(height: 18),

                  _buildSectionTitle("LONG-TERM MISSIONS", "Permanent progress", Icons.flag, isDark),
                  _buildLongTermGrid(isDark),

                  const SizedBox(height: 100),
                ],
              ),
            ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAchievementsWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: isDark ? Colors.white54 : Colors.grey),
          const SizedBox(height: 20),
          Text("No Quests Found", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await AchievementService.init();
              await _initializeData();
            },
            child: const Text("Reload"),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    final stats = BadgeService.badgeNotifier.value;

    final badgeName = stats.badgeName.toUpperCase();
    final badgeColor = stats.badgeColor;
    final totalStars = stats.totalStars;
    final starsNeeded = _getNextStarThreshold(stats.badgeLevel);

    final currentLevel = stats.numericLevel;
    final currentXP = stats.totalXP;

    final xpProgress = _calculateLevelProgress(currentLevel, currentXP);
    final nextLevelXP = _getXPForLevel(currentLevel + 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain.withOpacity(0.9), AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ACHIEVEMENTS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: _showInfoDialog),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeColor, width: 2),
                        ),
                        child: Icon(stats.badgeLevel == BadgeLevel.diamond ? Icons.workspace_premium : Icons.workspace_premium, color: badgeColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CURRENT RANK", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
                            Text(badgeName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: badgeColor)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${totalStars.toStringAsFixed(0)} Stars", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                if(stats.badgeLevel != BadgeLevel.diamond)
                                  Text("/ ${starsNeeded.toStringAsFixed(0)}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: stats.badgeProgressPercent, minHeight: 8, backgroundColor: Colors.black12, valueColor: AlwaysStoppedAnimation(badgeColor)),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(Icons.bolt, color: Colors.amber, size: 18), const SizedBox(width: 6), Text("LEVEL $currentLevel", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))]),
                      Text("${(xpProgress * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(height: 18, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(9))),
                      FractionallySizedBox(widthFactor: xpProgress.clamp(0.0, 1.0), child: Container(height: 18, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.amber]), borderRadius: BorderRadius.circular(9)))),
                      Positioned.fill(child: Center(child: Text("$currentXP / $nextLevelXP XP", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getNextStarThreshold(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie: return 100;
      case BadgeLevel.bronze: return 500;
      case BadgeLevel.silver: return 2000;
      case BadgeLevel.gold: return 5000;
      case BadgeLevel.platinum: return 10000;
      default: return 10000;
    }
  }

  int _getXPForLevel(int level) {
    if (level <= 1) return 0;
    return (44 * (level - 1) * (level - 1)).toInt();
  }

  double _calculateLevelProgress(int currentLevel, int currentXP) {
    int startXP = _getXPForLevel(currentLevel);
    int nextXP = _getXPForLevel(currentLevel + 1);
    if (nextXP <= startXP) return 1.0;
    return ((currentXP - startXP) / (nextXP - startXP)).clamp(0.0, 1.0);
  }

  Widget _buildToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(child: _toggleButton("Active", !_showCompleted, isDark, () => setState(() => _showCompleted = false))),
            Expanded(child: _toggleButton("Completed", _showCompleted, isDark, () => setState(() => _showCompleted = true))),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String text, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandMain : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandMain, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.brandDark, letterSpacing: 1.0)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBoard(bool isDark) {
    final core = _dailyCore();
    final bonus = _dailyBonus();

    if (core.isEmpty && bonus.isEmpty) {
      return _buildEmptyBox(isDark, "No daily quests found.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...core.map((st) => _buildQuestRowCard(st, isDark)),
          if (bonus.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBonusHeader(isDark),
            ...bonus.map((st) => _buildQuestRowCard(st, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 8),
          Text("BONUS QUESTS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, color: isDark ? Colors.white : AppColors.brandDark)),
        ],
      ),
    );
  }

  Widget _buildWeeklyMission(bool isDark) {
    final quests = _getWeeklyQuests();

    if (quests.isEmpty) {
      return _buildEmptyBox(isDark, "No weekly missions available.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: quests.map((st) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildWeeklyCard(st, isDark),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLongTermGrid(bool isDark) {
    final chains = _longTermChains();

    if (chains.isEmpty) {
      return _buildEmptyBox(isDark, "No long-term missions found.");
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: chains.length,
        itemBuilder: (context, i) => _buildChainCard(chains[i], isDark),
      ),
    );
  }

  Widget _buildChainCard(_ChainBundle bundle, bool isDark) {
    final bool isMultiStage = bundle.stages.length > 1;

    AchievementState? currentSt;
    AchievementState? nextUnclaimed;

    for (final st in bundle.stages) {
      if (!st.claimed) {
        nextUnclaimed = st;
        break;
      }
    }
    currentSt = nextUnclaimed ?? bundle.stages.last;

    if (currentSt.isLocked) {
      return _buildLockedGridCard(currentSt, isDark);
    }

    final int starsFilled = bundle.stages.where((s) => s.claimed).length;
    final int totalStars = bundle.stages.length;

    final bool canClaim = currentSt.isCompleted && !currentSt.claimed;
    final bool isAllDone = nextUnclaimed == null;

    final int prog = currentSt.progress;
    final int target = currentSt.def.target;
    final double pct = target == 0 ? 0.0 : (prog / target).clamp(0.0, 1.0);

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        if (canClaim) {
          _claim(currentSt!);
        } else if (!currentSt!.claimed) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(currentSt.def.description),
            duration: const Duration(seconds: 1),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: canClaim ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isMultiStage)
                  Row(
                    children: List.generate(math.min(totalStars, 3), (index) {
                      bool filled = index < starsFilled;
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled ? Colors.amber : Colors.grey.withOpacity(0.4),
                        size: 16,
                      );
                    }),
                  )
                else
                  const SizedBox.shrink(),

                if (!canClaim && !isAllDone) _xpPill(currentSt.def.xpReward),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSt.def.title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isAllDone ? "Completed!" : (isMultiStage ? "$prog / $target" : currentSt.def.description),
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            if (canClaim)
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text("CLAIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            else if (!isAllDone)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandMain),
                ),
              )
            else
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check, color: Colors.green, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestRowCard(AchievementState st, bool isDark) {
    if (st.isLocked) return _buildLockedCard(st, isDark);

    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;
    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        if (canClaim) {
          _claim(st);
        } else if (!st.claimed) {
          _navigateToTask(st.def.id);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: canClaim ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor), maxLines: 1),
                      const SizedBox(height: 4),
                      Text(st.def.description, style: TextStyle(fontSize: 12, color: sub), maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (canClaim)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Text("CLAIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                else if (st.claimed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else
                  _xpPill(st.def.xpReward),
              ],
            ),
            if (!st.claimed) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCard(AchievementState st, bool isDark) {
    if (st.isLocked) return _buildLockedCard(st, isDark);

    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        if (canClaim) _claim(st);
        else if (!st.claimed) _navigateToTask(st.def.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: canClaim ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(st.def.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ),
                ),
                if (canClaim)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Text("CLAIM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                else
                  _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : Colors.blue),
              ),
            ),
            if (!st.claimed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(AchievementState st, bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upgrade to PRO to unlock this quest & earn massive XP!"),
            backgroundColor: Colors.amber,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.lock, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(st.def.title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Text("Pro Plan Exclusive", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            _xpPill(st.def.xpReward, isLocked: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedGridCard(AchievementState st, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 28, color: Colors.grey),
          const SizedBox(height: 8),
          Text(st.def.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text("Locked", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _xpPill(int xp, {bool isLocked = false}) {
    final color = isLocked ? Colors.grey : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: color, size: 14),
          const SizedBox(width: 5),
          Text("+$xp", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(bool isDark, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Text(msg, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      ),
    );
  }

  Future<void> _claim(AchievementState st) async {
    HapticFeedback.heavyImpact();
    _confettiController.play();

    // ১. ক্লেম ফাংশন কল করা
    await AchievementService.claim(st.def.id);

    // ২. Weekly Progress বাড়ানো (যদি ডেইলি কোয়েস্ট হয়)
    if (st.def.resetPeriod == ResetPeriod.daily) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // উইকলি কোয়েস্টের জন্য প্রোগ্রেস +1 করা
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'weekly_quest_progress': FieldValue.increment(1),
        });
      }
    }

    if (mounted) setState(() {});
  }

  void _navigateToTask(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = id.toLowerCase();

    if (key.contains('login') || key.contains('check')) {
      await AchievementService.incrementProgress('daily_login', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checked in!")));
        setState(() {});
      }
      return;
    }

    if (key.contains('share')) {
      _shareMyProfileFromQuest();
      return;
    }

    if (key.contains('explore') || key.contains('map')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Map...")));
      await AchievementService.incrementProgress('daily_explore', amount: 1);
      if(mounted) setState((){});
      return;
    }

    if (key.contains('portfolio') || key.contains('cv') || key.contains('upload')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDocumentsScreen(uid: uid, isOwner: true)));
      return;
    }

    if ((key.contains('job') || key.contains('post')) && !key.contains('view')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => _isWorker ? const EarnPostScreen() : const SupportPostScreen()));
      return;
    }

    if (key.contains('profile')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileEditScreen(uid: uid)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action not available from here.")));
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quest Guide"),
        content: const Text(
          "Daily Board: 5 core quests + 2 bonus\n"
              "Weekly Big Mission: big reward, resets weekly\n"
              "Long-term: permanent missions\n\n"
              "Pro quests are locked until you upgrade.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> _shareMyProfileFromQuest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      final name = (data['name'] ?? 'FindUs User').toString();

      final message = 'Check out $name on FindUs! https://yourapp.com/profile/$uid';
      await Share.share(message);

      await AchievementService.incrementProgress('daily_share', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();

      if(mounted) setState(() {});
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }
}
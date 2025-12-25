import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/constants/badge_theme.dart';
import 'package:findus_app/constants/status_theme.dart';
import 'package:findus_app/services/badge_service.dart';
import 'package:findus_app/models/badge_model.dart';
import 'package:findus_app/screens/settings/kyc_screen.dart';

// 🔹 Play Games–style achievement system
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/achievement//achievement_models.dart';

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool isCollectPoint = true; // COLLECT POINT / ACHIEVEMENT টগল

  // ব্যাজ লেভেল থ্রেশহোল্ড – BadgeService এর সাথে match
  static const int _bronzeMinPoints = 1000;
  static const int _silverMinPoints = 10000;
  static const int _goldMinPoints = 50000;
  static const int _platinumMinPoints = 100000;
  static const int _diamondMinPoints = 1000000;
  static const int _maxBadgePoints = _diamondMinPoints;

  String? _userRole; // 'finder' (worker) / 'maker' (supporter)
  bool _isVerified = false;
  bool _isTrusted = false;
  bool _isTopRated = false;

  bool get _isWorker =>
      (_userRole ?? '').toLowerCase().trim() == 'finder';

  @override
  void initState() {
    super.initState();
    _loadUserFlags();
  }

  Future<void> _loadUserFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final rating = prefs.getDouble('user_rating') ?? 0.0;

      final verifiedProfile = prefs.getBool('user_verified') ?? false;
      final kycCompleted = prefs.getBool('kyc_completed') ?? false;
      final trusted = prefs.getBool('user_trusted') ?? false;
      final topRated =
          prefs.getBool('user_top_rated') ?? (rating >= 4.8);

      if (!mounted) return;
      setState(() {
        _userRole = role;
        // 🔹 Verified badge: profile verified বা KYC complete হলে
        _isVerified = verifiedProfile || kycCompleted;
        _isTrusted = trusted;
        _isTopRated = topRated;
      });
    } catch (_) {}
  }

  // বড় point কে short format: 1200 → 1.2K, 1,200,000 → 1.2M
  String _formatPoints(int points) {
    if (points >= 1000000) {
      return "${(points / 1000000).toStringAsFixed(1)}M";
    }
    if (points >= 1000) {
      return "${(points / 1000).toStringAsFixed(1)}K";
    }
    return points.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFE0F7FA),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTopDashboardCard(progress),
                const SizedBox(height: 20),
                _buildNextBadgeSection(progress),
                const SizedBox(height: 25),
                _buildToggleButtons(),
                const SizedBox(height: 15),
                _buildAchievementsList(progress),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- টপ DASHBOARD কার্ড ----------------
  Widget _buildTopDashboardCard(BadgeProgress progress) {
    final int points =
    progress.totalPoints.clamp(0, _maxBadgePoints); // 0–1,000,000
    final double totalPercent =
    (points / _maxBadgePoints).clamp(0.0, 1.0);
    final int percentInt = (totalPercent * 100).round();
    final String pointsLabel = _formatPoints(points);

    // নতুন থ্রেশহোল্ড অনুযায়ী unlocked status
    final bool bronzeUnlocked = points >= _bronzeMinPoints;
    final bool silverUnlocked = points >= _silverMinPoints;
    final bool goldUnlocked = points >= _goldMinPoints;
    final bool platinumUnlocked = points >= _platinumMinPoints;
    final bool diamondUnlocked = points >= _diamondMinPoints;

    // worker/supporter badge label আলাদা
    final String rolePrefix = _isWorker ? "Worker" : "Support";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // বাম পাশে বড় circular percent
              CircularPercentIndicator(
                radius: 55.0,
                lineWidth: 10.0,
                percent: totalPercent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pointsLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      "XP",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$percentInt%",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                progressColor: const Color(0xFF6A1B9A),
                circularStrokeCap: CircularStrokeCap.round,
                fillColor: Colors.transparent,
              ),

              const SizedBox(width: 16),

              // ডান পাশে দুইটা row (badges + status)
              Expanded(
                child: Column(
                  children: [
                    // Row 1: ৫টা level badge
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        _badgeIcon(
                          AppBadgeTheme.baseIcon,
                          "$rolePrefix\nBRONZE",
                          AppBadgeTheme.bronze,
                          bronzeUnlocked,
                          small: true,
                        ),
                        _badgeIcon(
                          AppBadgeTheme.baseIcon,
                          "$rolePrefix\nSILVER",
                          AppBadgeTheme.silver,
                          silverUnlocked,
                          small: true,
                        ),
                        _badgeIcon(
                          AppBadgeTheme.baseIcon,
                          "$rolePrefix\nGOLD",
                          AppBadgeTheme.gold,
                          goldUnlocked,
                          small: true,
                        ),
                        _badgeIcon(
                          AppBadgeTheme.baseIcon,
                          "$rolePrefix\nPLATINUM",
                          AppBadgeTheme.platinum,
                          platinumUnlocked,
                          small: true,
                        ),
                        _badgeIcon(
                          AppBadgeTheme.baseIcon,
                          "$rolePrefix\nDIAMOND",
                          AppBadgeTheme.diamond,
                          diamondUnlocked,
                          small: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 2: Top Rated / Trusted / Verified
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusBadgeIcon(
                          icon: StatusTheme.topRatedIcon,
                          label: "TOP RATED",
                          enabled: _isTopRated,
                          activeColor:
                          StatusTheme.topRatedColor,
                        ),
                        _statusBadgeIcon(
                          icon: StatusTheme.trustedIcon,
                          label: "TRUSTED",
                          enabled: _isTrusted,
                          activeColor:
                          StatusTheme.trustedColor,
                        ),
                        _statusBadgeIcon(
                          icon: StatusTheme.verifiedIcon,
                          label: "VERIFIED",
                          enabled: _isVerified,
                          activeColor:
                          StatusTheme.verifiedColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- NEXT BADGE সেকশন ----------------
  Widget _buildNextBadgeSection(BadgeProgress progress) {
    final int points =
    progress.totalPoints.clamp(0, _maxBadgePoints);

    String nextLabel;
    int nextTarget;

    if (points < _bronzeMinPoints) {
      nextLabel = "BRONZE";
      nextTarget = _bronzeMinPoints;
    } else if (points < _silverMinPoints) {
      nextLabel = "SILVER";
      nextTarget = _silverMinPoints;
    } else if (points < _goldMinPoints) {
      nextLabel = "GOLD";
      nextTarget = _goldMinPoints;
    } else if (points < _platinumMinPoints) {
      nextLabel = "PLATINUM";
      nextTarget = _platinumMinPoints;
    } else if (points < _diamondMinPoints) {
      nextLabel = "DIAMOND";
      nextTarget = _diamondMinPoints;
    } else {
      nextLabel = "MAX BADGE";
      nextTarget = _diamondMinPoints;
    }

    final bool isMax = points >= _diamondMinPoints;
    final double barPercent =
    isMax ? 1.0 : (points / nextTarget).clamp(0.0, 1.0);

    final String targetLabel = _formatPoints(nextTarget);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0D0FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          // বাম পাশে টেক্সট + বার
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NEXT BADGE",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMax
                      ? "You have reached the highest badge (DIAMOND)."
                      : "$nextLabel badge unlocks at $targetLabel XP.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.black87, width: 1),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double fillWidth =
                          constraints.maxWidth * barPercent;
                      return Stack(
                        children: [
                          Container(
                            width: fillWidth,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B2BFF),
                              borderRadius:
                              BorderRadius.circular(30),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ডান পাশে পরের ব্যাজ আইকন
          Column(
            children: [
              Icon(
                AppBadgeTheme.baseIcon,
                color: isMax
                    ? AppBadgeTheme.diamond
                    : AppBadgeTheme.colorForLabel(nextLabel),
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                isMax ? "DIAMOND" : nextLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- টগল বাটন ----------------
  Widget _buildToggleButtons() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF80DEEA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isCollectPoint = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCollectPoint
                      ? const Color(0xFFE1BEE7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "COLLECT POINT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isCollectPoint = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isCollectPoint
                      ? const Color(0xFFE1BEE7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "ACHIEVEMENT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Play Games–style Achievement list ----------------
  Widget _buildAchievementsList(BadgeProgress progress) {
    final bool isWorker = _isWorker;
    final int currentPoints = progress.totalPoints;

    return ValueListenableBuilder<List<AchievementState>>(
      valueListenable:
      AchievementService.achievementsNotifier,
      builder: (context, allStates, _) {
        final all = AchievementService.getAllForUser(
          isWorker: isWorker,
          currentPoints: currentPoints,
        );

        final collectList =
        all.where((st) => !st.claimed).toList();
        final claimedList =
        all.where((st) => st.claimed).toList();

        final visible =
        isCollectPoint ? collectList : claimedList;

        if (!isCollectPoint && visible.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "No achievements claimed yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        if (isCollectPoint && visible.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "Complete actions in the app to unlock quests.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children:
          visible.map(_buildAchievementItem).toList(),
        );
      },
    );
  }

  Widget _buildAchievementItem(AchievementState st) {
    final def = st.def;
    final bool completed = st.isCompleted;
    final bool claimed = st.claimed;

    final double percent =
    (st.progress / def.target).clamp(0.0, 1.0);

    // icon mapping
    IconData icon;
    Color iconColor;

    if (def.id.contains('daily')) {
      icon = Icons.calendar_today_outlined;
      iconColor = Colors.blueGrey;
    } else if (def.id.contains('kyc')) {
      icon = Icons.verified_user;
      iconColor = Colors.blue;
    } else if (def.id.contains('driving_license')) {
      icon = Icons.badge_outlined;
      iconColor = Colors.deepPurple;
    } else if (def.id.contains('worker')) {
      icon = Icons.work_outline;
      iconColor = Colors.green;
    } else if (def.id.contains('supporter')) {
      icon = Icons.handshake_outlined;
      iconColor = Colors.orange;
    } else if (def.id.contains('review')) {
      icon = Icons.reviews_outlined;
      iconColor = Colors.amber;
    } else {
      icon = Icons.flag_outlined;
      iconColor = Colors.teal;
    }

    final bool isKycQuest =
    def.id.toLowerCase().contains('kyc');

    return InkWell(
      onTap: isKycQuest
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const KycUploadScreen(),
          ),
        );
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            // আইকন
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Icon(icon,
                  color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // মাঝখানে টাইটেল + বার
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    def.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(30),
                    child: Container(
                      height: 10,
                      color: const Color(0xFFFFF0D5),
                      child: Align(
                        alignment:
                        Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: percent,
                          child: Container(
                            decoration:
                            BoxDecoration(
                              color: completed
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${st.progress}/${def.target}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ডান পাশে progress + CLAIM / CLAIMED
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Text(
                  "+${def.xpReward} XP",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandMain,
                  ),
                ),
                const SizedBox(height: 4),
                if (!completed)
                  const Text(
                    "In progress",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  )
                else if (completed && !claimed)
                  OutlinedButton(
                    onPressed: () async {
                      await AchievementService
                          .claim(def.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                              'Claimed +${def.xpReward} XP'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets
                          .symmetric(
                          horizontal: 8,
                          vertical: 4),
                      side: const BorderSide(
                          color: AppColors.brandMain),
                      minimumSize: Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                    ),
                    child: const Text(
                      "CLAIM",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.brandMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(
                        AppBadgeTheme.baseIcon,
                        size: 12,
                        color: AppBadgeTheme.gold,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "CLAIMED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- হেল্পার: level badge icon ----------------
  Widget _badgeIcon(
      IconData icon,
      String label,
      Color color,
      bool unlocked, {
        bool small = false,
      }) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.25,
      child: Column(
        children: [
          Icon(
            icon,
            color: unlocked ? color : Colors.black,
            size: small ? 22 : 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: small ? 8 : 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- হেল্পার: status badge (Top/Trusted/Verified) ----------------
  Widget _statusBadgeIcon({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color activeColor,
  }) {
    final Color iconColor =
    enabled ? activeColor : Colors.black;
    final Color borderColor = enabled
        ? activeColor.withOpacity(0.7)
        : Colors.grey.shade300;
    final Color bgColor = enabled
        ? activeColor.withOpacity(0.12)
        : Colors.white;

    return Opacity(
      opacity: enabled ? 1.0 : 0.25, // fade effect
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: borderColor, width: 0.8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
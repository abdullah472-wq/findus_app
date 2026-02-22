import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';

class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String roleLabel;
  final bool isDark;
  final bool isOwner;
  final bool isOnline;
  final int cardThemeIndex;
  final int followersCount;
  final int followingCount;
  final int userRank;
  final bool isFollowing;
  final bool isFollowProcessing;
  final VoidCallback? onFollowTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onBadgeTap;
  final VoidCallback? onRankTap;
  final VoidCallback? onRatingTap;
  final VoidCallback? onImageTap;

  const ProfileHeaderCard({
    super.key,
    required this.userData,
    required this.roleLabel,
    required this.isDark,
    required this.isOwner,
    this.isOnline = false,
    this.cardThemeIndex = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.userRank = 0,
    this.isFollowing = false,
    this.isFollowProcessing = false,
    this.onFollowTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onBadgeTap,
    this.onRankTap,
    this.onRatingTap,
    this.onImageTap,
  });

  // Theme Gradients
  static const List<List<Color>> themeGradients = [
    [Color(0xFF00DDFA), Color(0xFFFFFFFF)],
    [Color(0xFFffd966), Color(0xFFFFFFFF)],
    [Color(0xFF6fa8dc), Color(0xFFFFFFFF)],
    [Color(0xFFf7bcbc), Color(0xFFFFFFFF)],
  ];

  // ✅ COMPUTED PROPERTIES FOR STATUS BADGES
  bool get _isVerified => userData['kyc_completed'] == true;

  bool get _isTopRated {
    final double rating = double.tryParse(userData['rating']?.toString() ?? '0') ?? 0.0;
    return rating >= 4.9;
  }

  bool get _isTrusted {
    final double rating = double.tryParse(userData['rating']?.toString() ?? '0') ?? 0.0;
    final int completed = int.tryParse(userData['completedCount']?.toString() ?? '0') ?? 0;
    return completed >= 50 && rating >= 4.5;
  }

  @override
  Widget build(BuildContext context) {
    // Badge & XP Data
    final int xp = _safeInt(userData['xpPoints']);
    final double stars = _safeDouble(userData['user_accumulated_stars']);
    final badgeRank = BadgeService.getBadgeByStars(stars);
    final numericLevel = BadgeService.getNumericLevel(xp);
    final badgeColor = _getBadgeColor(badgeRank);

    // Theme
    final int themeIdx = cardThemeIndex.clamp(0, themeGradients.length - 1);
    final selectedTheme = themeGradients[themeIdx];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : selectedTheme,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Section
          _buildCoverSection(badgeRank, badgeColor, numericLevel),

          const SizedBox(height: 65),

          // Name & Role
          _buildNameSection(textColor),

          const SizedBox(height: 20),

          // Engagement Row (Followers + Badges)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEngagementRow(),
          ),

          const SizedBox(height: 24),

          // Stats Row (Rating, Jobs, Rank)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStatsRow(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COVER SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCoverSection(BadgeLevel badge, Color badgeColor, int level) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Gradient Cover
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _getBadgeGradient(badge),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // Decorative Circle
              Positioned(
                top: -30,
                left: -30,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),

              // Badge (Top Right)
              Positioned(
                top: 20,
                right: 20,
                child: _AnimatedBadgeWidget(
                  badgeLevel: badge,
                  badgeColor: badgeColor,
                  onTap: onBadgeTap,
                ),
              ),
            ],
          ),
        ),

        // Avatar
        Positioned(
          bottom: -55,
          child: _buildAvatar(level),
        ),
      ],
    );
  }

  Widget _buildAvatar(int level) {
    final imageUrl = _safeString(userData['image']);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Profile Image
        GestureDetector(
          onTap: onImageTap,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarPlaceholder(),
                errorWidget: (_, __, ___) => _avatarPlaceholder(),
              )
                  : _avatarPlaceholder(),
            ),
          ),
        ),

        // Level Badge
        Positioned(
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandMain,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              "LVL $level",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        // Online Status
        if (isOnline && !isOwner)
          Positioned(
            bottom: 10,
            right: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.person, color: Colors.grey, size: 50),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NAME SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNameSection(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _safeString(userData['name']).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (userData['accountLocked'] == true)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock_outline, size: 18, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            roleLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandMain,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ENGAGEMENT ROW (Fixed - using class-level getters)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEngagementRow() {
    return Row(
      children: [
        // Left: Followers / Follow Button
        Expanded(
          child: isOwner
              ? Row(
            children: [
              _buildStatItem(followersCount, "Followers", onFollowersTap),
              const SizedBox(width: 20),
              _buildStatItem(followingCount, "Following", onFollowingTap),
            ],
          )
              : Row(
            children: [
              _buildFollowButton(),
              const SizedBox(width: 12),
              _buildStatItem(followersCount, "Followers", onFollowersTap),
            ],
          ),
        ),

        // Right: Status Badges (✅ Using class-level getters now)
        Row(
          children: [
            _buildStatusBadge(Icons.verified_rounded, _isVerified, Colors.blue),
            const SizedBox(width: 8),
            _buildStatusBadge(Icons.star_rounded, _isTopRated, Colors.orange),
            const SizedBox(width: 8),
            _buildStatusBadge(Icons.shield_rounded, _isTrusted, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    if (!isFollowing) {
      return InkWell(
        onTap: isFollowProcessing ? null : onFollowTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brandMain,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isFollowProcessing
              ? const SizedBox(
            width: 50,
            height: 16,
            child: Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          )
              : const Text(
            "Follow",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Following",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatNumber(count),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IconData icon, bool isActive, Color activeColor) {
    final Color inactiveColor = isDark ? Colors.white24 : Colors.grey[350]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.15)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? activeColor.withOpacity(0.6)
              : (isDark ? Colors.white10 : Colors.grey[300]!),
        ),
        boxShadow: isActive
            ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 8)]
            : null,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    final double rating = _safeDouble(userData['rating']);
    final int completed = _safeInt(userData['completedCount']);
    final bool isWorker = (userData['userRole'] ?? 'finder').toString().toLowerCase() == 'finder';

    String rankDisplay = userRank == 0 ? "N/A" : (userRank >= 100 ? "100+" : "#$userRank");

    return Row(
      children: [
        _buildStatBox(
          label: "RATING",
          value: rating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          onTap: onRatingTap,
        ),
        const SizedBox(width: 10),
        _buildStatBox(
          label: isWorker ? "JOBS" : "HIRED",
          value: "$completed",
          icon: isWorker ? Icons.work_rounded : Icons.handshake_rounded,
          iconColor: Colors.blue,
        ),
        const SizedBox(width: 10),
        _buildStatBox(
          label: "RANK",
          value: rankDisplay,
          icon: userRank <= 3 && userRank > 0
              ? Icons.emoji_events_rounded
              : Icons.leaderboard_rounded,
          iconColor: _getRankColor(),
          onTap: onRankTap,
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final bgColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.grey[600];

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  Color _getRankColor() {
    if (userRank == 1) return const Color(0xFFFFD700);
    if (userRank == 2) return const Color(0xFFA8A8A8);
    if (userRank == 3) return const Color(0xFFCD7F32);
    if (userRank <= 10) return Colors.orange;
    return Colors.teal;
  }

  LinearGradient _getBadgeGradient(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return const LinearGradient(colors: [Color(0xFF4B79A1), Color(0xFF283E51)]);
      case BadgeLevel.bronze:
        return const LinearGradient(colors: [Color(0xFFE65C00), Color(0xFFF9D423)]);
      case BadgeLevel.silver:
        return const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]);
      case BadgeLevel.gold:
        return const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C)]);
      case BadgeLevel.platinum:
        return const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]);
      case BadgeLevel.diamond:
        return const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]);
    }
  }

  Color _getBadgeColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return const Color(0xFFFFB74D);
      case BadgeLevel.silver:
        return const Color(0xFFE0E0E0);
      case BadgeLevel.gold:
        return const Color(0xFFFFD700);
      case BadgeLevel.platinum:
        return const Color(0xFF00E5FF);
      case BadgeLevel.diamond:
        return const Color(0xFFB388FF);
      default:
        return Colors.white;
    }
  }

  String _safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String && value.isEmpty) return defaultValue;
    return value.toString();
  }

  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  double _safeDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED BADGE WIDGET
// ═══════════════════════════════════════════════════════════════

class _AnimatedBadgeWidget extends StatefulWidget {
  final BadgeLevel badgeLevel;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _AnimatedBadgeWidget({
    required this.badgeLevel,
    required this.badgeColor,
    this.onTap,
  });

  @override
  State<_AnimatedBadgeWidget> createState() => _AnimatedBadgeWidgetState();
}

class _AnimatedBadgeWidgetState extends State<_AnimatedBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNewbie = widget.badgeLevel == BadgeLevel.newbie;
    final String badgeName = widget.badgeLevel.toString().split('.').last.toUpperCase();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                  boxShadow: [
                    BoxShadow(
                      color: isNewbie
                          ? Colors.white.withOpacity(_glowAnimation.value)
                          : widget.badgeColor.withOpacity(_glowAnimation.value),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: isNewbie ? Colors.white : widget.badgeColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeName,
                  style: TextStyle(
                    color: isNewbie ? Colors.white : widget.badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
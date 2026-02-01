import 'dart:async';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';

// Constants & Models
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_theme.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/achievement/achievement_service.dart';

// Services
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/services/card_theme_service.dart';

// Screens & Widgets
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/team/team_management_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/explore/notifications_page.dart'; // Notification Page Import
import 'package:findus_app/screens/profile/worker_documents_screen.dart';
import 'package:findus_app/screens/rating_history_screen.dart';
import '../../models/worker_model.dart';
import 'card_theme_bottom_sheet.dart';
import 'followers_following_screen.dart';

// Enums
enum ProfileMenuOwner { edit, shareProfile, previewPublicCard, lockAccount, theme, hideProfile, pauseWork }
enum ProfileMenuOther { report, block }

class UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  // Streams
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription? _followersCountSub;
  StreamSubscription? _followingCountSub;
  StreamSubscription? _onlineStatusSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;

  // State Variables
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  bool isFollowing = false;
  bool isBlocked = false;
  bool isOnline = false;

  // Theme & Stats
  int _cardThemeIndex = 0;
  int _followersCountLive = 0;
  int _followingCountLive = 0;
  int _unreadNotifCount = 0;

  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  // 🎨 Theme Gradients (Same as BottomSheet)
  final List<List<Color>> _themeGradients = const [
    [Color(0xFFE0F7FA), Color(0xFFFFFFFF)], // Teal (Light)
    [Color(0xFFFFF3E0), Color(0xFFFFFFFF)], // Orange (Light)
    [Color(0xFFE8EAF6), Color(0xFFFFFFFF)], // Indigo (Light)
    [Color(0xFFFCE4EC), Color(0xFFFFFFFF)], // Pink (Light)
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    if (widget.isOwner) {
      _listenToNotifications();
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _onlineStatusSub?.cancel();
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  void _initializeData() async {
    final blocked = await BlockedUserService().isBlocked(widget.uid);
    if (!blocked) {
      _listenToUserData();
      _listenToFollowCounts();
      if (!widget.isOwner) _checkIfFollowing();
    } else if (mounted) {
      setState(() => isBlocked = true);
      _showBlockedDialog();
    }
  }

  // --- Listeners ---

  void _listenToUserData() {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() ?? {};
      final rawIdx = data['cardThemeIndex'];
      final idx = (rawIdx is int) ? rawIdx : int.tryParse(rawIdx?.toString() ?? '') ?? 0;

      setState(() {
        userData = data;
        _cardThemeIndex = idx.clamp(0, _themeGradients.length - 1);
        isOnline = (data['isOnline'] ?? false) == true;
        isLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => isLoading = false);
    });
  }

  void _listenToFollowCounts() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();
    _followersCountSub = FirebaseFirestore.instance.collection('users').doc(widget.uid).collection('followers').snapshots().listen((q) {
      if (mounted) setState(() => _followersCountLive = q.size);
    });
    _followingCountSub = FirebaseFirestore.instance.collection('users').doc(widget.uid).collection('following').snapshots().listen((q) {
      if (mounted) setState(() => _followingCountLive = q.size);
    });
  }

  void _listenToNotifications() {
    _notifSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _notifSub = FirebaseFirestore.instance.collection('notifications').where('toUserId', isEqualTo: uid).where('isRead', isEqualTo: false).snapshots().listen((q) {
      if (mounted) setState(() => _unreadNotifCount = q.size);
    });
  }

  Future<void> _checkIfFollowing() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUid).collection('following').doc(widget.uid).get();
      if (mounted) setState(() => isFollowing = doc.exists);
    } catch (_) {}
  }

  void _openRatingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingHistoryScreen(
          targetUserId: widget.uid, // ✅ এখানে uid পাঠাচ্ছি
        ),
      ),
    );
  }

  // --- Actions ---

  Future<void> _toggleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    HapticFeedback.lightImpact();

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final followRef = currentUserRef.collection('following').doc(widget.uid);
    final followerRef = userRef.collection('followers').doc(currentUid);

    if (isFollowing) {
      batch.delete(followRef);
      batch.delete(followerRef);
      batch.update(userRef, {'followersCount': FieldValue.increment(-1)});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
    } else {
      batch.set(followRef, {'followedAt': DateTime.now(), 'userName': userData['name']});
      batch.set(followerRef, {'followedAt': DateTime.now(), 'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User'});
      batch.update(userRef, {'followersCount': FieldValue.increment(1)});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
    }

    try {
      await batch.commit();
      if (mounted) setState(() => isFollowing = !isFollowing);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    } catch (_) {}
  }

  void _showBlockedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Blocked User'),
          content: const Text('You have blocked this user.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      ).then((_) => Navigator.pop(context));
    });
  }

  // --- Theme & Premium ---

  void _showCardThemeBottomSheet() async {
    try {
      final subscriptionType = userData['subscription_type']?.toString() ?? 'free';
      final bool isProUser = subscriptionType != 'free';
      final currentColorIndex = await CardThemeService.getCardThemeIndex(widget.uid);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return CardThemeBottomSheet(
            userId: widget.uid,
            initialColorIndex: currentColorIndex,
            isfree: !isProUser,
            subscriptionType: subscriptionType,
            onThemeChanged: (index) {
              setState(() => _cardThemeIndex = index);
              CardThemeService.setCardThemeIndex(widget.uid, index);
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading themes')));
    }
  }

  // --- Premium Actions ---
  Future<void> _setAccountLocked(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({'accountLocked': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  Future<void> _setProfileHidden(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({'profileHidden': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  Future<void> _setWorkPaused(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({'workPaused': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // ===== UI BUILDERS =====

  @override
  Widget build(BuildContext context) {
    if (isBlocked) return Scaffold(appBar: AppBar(title: const Text('Profile')), body: const Center(child: Text('User Blocked')));

    final subscriptionType = userData['subscription_type']?.toString() ?? 'free';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ ডার্ক মোড কালার ফিক্স
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.bgBlue;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final scaffoldBg = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;

    return Scaffold(
      bottomNavigationBar: (!widget.isOwner)
          ? SafeArea(
        top: false, // শুধু নিচের সেফ এরিয়া
        child: _buildVisitorActionBar(isDark),
      )
          : null,
      body: Builder(
        builder: (ctx) {
          final bool shouldShowBack = widget.showBack ?? Navigator.of(ctx).canPop();

          return FloatingScaffold(
            showBack: shouldShowBack,
            title: 'PROFILE',
            backgroundColor: scaffoldBg,
            titleColor: titleColor,
            iconColor: titleColor,

            // ✅ অ্যাপ বার বাটনগুলোর সাইজ সমান করা হয়েছে
            actions: widget.isOwner
                ? [
              _buildActionButton(
                Icons.notifications_none_rounded,
                'Notifications',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                isDark,
                showBadge: true, // ✅ নতুন প্যারামিটার
                badgeCount: _unreadNotifCount, // ✅ লাইভ কাউন্ট
              ),
              _buildActionButton(Icons.groups_outlined, 'Team', () => _isBusinessUser ? Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen(userId: widget.uid))) : _showUpgradeToBusinessPopup(), isDark),
              _buildActionButton(Icons.settings_outlined, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), isDark),
              _buildMenuButton(subscriptionType, isDark),
            ]
                : [_buildVisitorMenuButton(isDark)],
            scrollable: false,
            bodyPadding: EdgeInsets.zero,
            body: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: isLoading ? _buildShimmerLoading() : _buildBody(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final locked = (userData['accountLocked'] ?? false) == true;
    final hidden = (userData['profileHidden'] ?? false) == true;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    if (!widget.isOwner && (locked || hidden)) {
      return Column(
        children: [
          _buildHeaderCard(_isWorkerRole() ? "Worker" : "Supporter", isDark),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              locked ? 'This profile is locked.' : 'This profile is currently hidden.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    final bool isWorker = _isWorkerRole();

    final double bottomSpacer = widget.isOwner ? 40.0 : 80.0;

    return Column(
      children: [
        _buildHeaderCard(isWorker ? "Worker" : "Supporter", isDark),
        _buildSocialLinks(),
        isWorker ? _buildWorkerInfo(isDark) : _buildSupporterInfo(isDark),
        _buildDocumentsButton(isDark),
        _buildAboutSection(isDark),
        _buildDynamicBottomSection(isWorker, isDark),
        SizedBox(height: bottomSpacer),
      ],
    );
  }

  // 🏞️ Final Fixed Header: Social Left, Status Right (Gray/Color Mode)
  // 🏞️ Header with Dynamic Theme Support
  Widget _buildHeaderCard(String roleLabel, bool isDark) {
    // ১. ডাটা পার্সিং
    final int xp = int.tryParse(userData['user_badge_points']?.toString() ?? '0') ?? 0;
    final double rating = double.tryParse(userData['rating']?.toString() ?? '0.0') ?? 0.0;
    final int completed = int.tryParse(userData['completedCount']?.toString() ?? '0') ?? 0;
    final badge = AchievementService.getBadgeLevelByPoints(xp);

    // ২. থিম কালার সিলেকশন লজিক
    // ইউজার যে থিম ইনডেক্স সিলেক্ট করেছে (Default 0)
    final int themeIdx = _cardThemeIndex.clamp(0, _themeGradients.length - 1);
    final List<Color> selectedTheme = _themeGradients[themeIdx];

    // ব্যাকগ্রাউন্ড লজিক:
    // যদি ডার্ক মোড হয় কিন্তু ইউজার কাস্টম থিম চায়, আমরা থিম দেখাবো তবে একটু ডার্ক করে।
    // অথবা সিম্পলি লাইট থিম দেখাবো (নিচের লজিকটি লাইট থিম দেখাবে)।

    // টেক্সট কালার: ব্যাকগ্রাউন্ড যেহেতু লাইট প্যাস্টেল, তাই টেক্সট কালো হবে।
    // তবে যদি ডিফল্ট ডার্ক মোড (কোনো থিম ছাড়া) চান, সেটার লজিক আলাদা হতে পারে।
    // এখানে থিম প্রায়োরিটি পাচ্ছে।
    final textColor = Colors.black87;

    final coverGradient = _getBadgeGradient(badge);
    final badgeColor = _getBadgeColor(badge);
    final isNewbie = xp < 1000;

    // ৩. স্ট্যাটাস লজিক
    final bool isVerified = userData['kyc_completed'] == true;
    final bool isTopRated = rating >= 4.8;
    final bool isTrusted = completed >= 50 && rating >= 4.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // 🔥🔥 DYNAMIC THEME BACKGROUND APPLIED HERE
        gradient: LinearGradient(
          colors: isDark
              ? [selectedTheme[0].withOpacity(0.8), const Color(0xFF1E1E1E)] // ডার্ক মোডে মিক্স
              : selectedTheme, // লাইট মোডে পিওর থিম
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
        // বর্ডার দেওয়া হলো যাতে ব্যাকগ্রাউন্ড লাইট হলে কার্ড বোঝা যায়
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      child: Column(
        children: [
          // 🏞️ Cover Section
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -30, left: -30, child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.1))),

                    // Badge (Top Right)
                    Positioned(
                      top: 20, right: 20,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.25),
                              boxShadow: [
                                BoxShadow(
                                  color: isNewbie ? Colors.white.withOpacity(0.3) : badgeColor.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.workspace_premium,
                              size: 48,
                              color: isNewbie ? Colors.white : badgeColor,
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
                                badge.name.toUpperCase(),
                                style: TextStyle(
                                    color: isNewbie ? Colors.white : badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2
                                )
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar
              Positioned(
                bottom: -55,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        // 🔥 Avatar Border color matches Theme
                          color: selectedTheme[0],
                          shape: BoxShape.circle,
                          border: Border.all(color: selectedTheme[0], width: 5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))]
                      ),
                      child: ClipOval(child: _buildCoverProfileImage()),
                    ),
                    if (isOnline)
                      Container(
                          margin: const EdgeInsets.all(6),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3)
                          )
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 65),

          // 📝 Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Name & Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _getSafeString(userData['name']).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor, // ব্যবহার করা হচ্ছে ডার্ক টেক্সট
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userData['accountLocked'] == true)
                      const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock_outline, size: 18, color: Colors.redAccent)),
                    if (userData['workPaused'] == true)
                      const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.pause_circle_outline, size: 18, color: Colors.amber)),
                    if (userData['profileHidden'] == true)
                      const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.visibility_off_outlined, size: 18, color: Colors.grey)),
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

                const SizedBox(height: 25),

                // Social & Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5), // Glassy white
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          _buildStylishSocialBtn(
                              count: _followersCountLive,
                              label: "Followers",
                              icon: Icons.people_alt_rounded,
                              color: Colors.blueAccent,
                              isDark: false, // Force Light mode style inside theme
                              onTap: _showFollowersList
                          ),
                          Container(height: 20, width: 1, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                          _buildStylishSocialBtn(
                              count: _followingCountLive,
                              label: "Following",
                              icon: Icons.person_add_alt_1_rounded,
                              color: Colors.purpleAccent,
                              isDark: false,
                              onTap: _showFollowingList
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        _buildStatusIcon(Icons.verified, isVerified, Colors.blue, "Verified", false),
                        const SizedBox(width: 5),
                        _buildStatusIcon(Icons.star, isTopRated, Colors.orange, "Top Rated", false),
                        const SizedBox(width: 5),
                        _buildStatusIcon(Icons.shield, isTrusted, Colors.green, "Trusted", false),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Stats Boxes (Transparent background to blend with theme)
                Row(
                  children: [
                    _buildFloatingStatBox("RATING", rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber, false),
                    const SizedBox(width: 12),
                    _buildFloatingStatBox(_isWorkerRole() ? "JOBS" : "HIRED", "$completed", _isWorkerRole() ? Icons.work_outline : Icons.handshake_rounded, Colors.blue, false),
                    const SizedBox(width: 12),
                    _buildFloatingStatBox("XP", _formatNumber(xp), Icons.bolt, Colors.purple, false),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPER METHODS ----------------

  // ✨ Helper: Stylish Glassy Social Button
  // ✨ Helper: Stylish Glassy Social Button (Count Highlighted)
  Widget _buildStylishSocialBtn({
    required int count,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap
  }) {
    // ডার্ক মোড এবং লাইট মোডের জন্য ব্যাকগ্রাউন্ড কালার
    final bgColor = isDark ? color.withOpacity(0.15) : color.withOpacity(0.08);
    final borderColor = isDark ? color.withOpacity(0.3) : color.withOpacity(0.2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12), // একটু চারকোনা পিল শেপ (Squircle)
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ১. আইকন
            Icon(icon, size: 16, color: color),

            const SizedBox(width: 8),

            // ২. কলাম (উপরে সংখ্যা, নিচে টেক্সট)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // কাউন্ট (বড় এবং রঙিন)
                Text(
                  _formatNumber(count),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900, // এক্সট্রা বোল্ড
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.0,
                  ),
                ),
                // লেবেল (ছোট)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 👉 Helper: Status Icon (Color if Active, Gray if Inactive)
  // 👉 Helper: Status Icon (Bigger & Bolder)
  Widget _buildStatusIcon(IconData icon, bool isActive, Color activeColor, String tooltip, bool isDark) {
    // কালার এবং ব্যাকগ্রাউন্ড লজিক
    final color = isActive ? activeColor : (isDark ? Colors.white24 : Colors.grey.shade300);
    final bgColor = isActive
        ? activeColor.withOpacity(0.1)
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100);

    return Tooltip(
      message: isActive ? tooltip : "Not $tooltip yet",
      child: Container(
        width: 44, // ✅ সাইজ বাড়ানো হয়েছে (আগে 36 ছিল)
        height: 44, // ✅ সাইজ বাড়ানো হয়েছে
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.4) : Colors.transparent,
            width: 2, // বর্ডার একটু মোটা করা হয়েছে
          ),
          boxShadow: isActive ? [
            BoxShadow(
                color: activeColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3)
            )
          ] : null,
        ),
        child: Icon(
          icon,
          size: 22, // ✅ আইকন সাইজ বড় করা হয়েছে (আগে 18 ছিল)
          color: color,
        ),
      ),
    );
  }

  // 🎨 Helper: Badge Gradient
  LinearGradient _getBadgeGradient(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return const LinearGradient(colors: [Color(0xFF4B79A1), Color(0xFF283E51)]); // Blue-Grey
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
      default:
        return const LinearGradient(colors: [Color(0xFF606c88), Color(0xFF3f4c6b)]);
    }
  }

  // 🎨 Helper: Badge Color (For Icon)
  // 🎨 Helper: Badge Color
  Color _getBadgeColor(BadgeLevel level) {
    switch (level) {
    // ✅ ব্রোঞ্জের জন্য অরেঞ্জ টাইপের কালার
      case BadgeLevel.bronze: return const Color(0xFFFFB74D);
      case BadgeLevel.silver: return const Color(0xFFE0E0E0);
      case BadgeLevel.gold: return const Color(0xFFFFD700);
      case BadgeLevel.platinum: return const Color(0xFF00E5FF);
      case BadgeLevel.diamond: return const Color(0xFFB388FF);
      default: return Colors.white; // Newbie
    }
  }

  // 🖼️ Helper: Profile Image
  Widget _buildCoverProfileImage() {
    final imageUrl = _getSafeString(userData['image'], defaultValue: '');
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
      );
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey));
  }

  // 📦 Helper: Stat Box
  Widget _buildFloatingStatBox(String label, String value, IconData icon, Color iconColor, bool isDark) {
    final boxBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50];
    final borderColor = isDark ? Colors.white10 : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: boxBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor!),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // --- Action Buttons (Equal Size) ---
  // এই মেথডটি আপডেট করুন
  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed, bool isDark, {bool showBadge = false, int badgeCount = 0}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            tooltip: tooltip,
          ),
          if (showBadge && badgeCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String subscriptionType, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40, height: 40, // ✅ সমান সাইজ ফিক্স
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: PopupMenuButton<ProfileMenuOwner>(
        onSelected: _handleOwnerMenu,
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white : Colors.black),
        itemBuilder: (ctx) => _buildOwnerMenuItems(subscriptionType),
      ),
    );
  }

  Widget _buildDocumentsButton(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_shared, color: AppColors.brandMain),
        title: Text(
          'CV & Portfolio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          'View documents & portfolio',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerDocumentsScreen(
                uid: widget.uid,
                isOwner: widget.isOwner,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitorMenuButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: PopupMenuButton<ProfileMenuOther>(
        onSelected: (value) {
          if (value == ProfileMenuOther.block) {
            BlockedUserService().blockUser(widget.uid, _getSafeString(userData['name'])).then((_) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Blocked')));
            });
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
          }
        },
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white : Colors.black),
        itemBuilder: (ctx) => [
          PopupMenuItem(value: ProfileMenuOther.report, child: Text('Report', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
          PopupMenuItem(value: ProfileMenuOther.block, child: Text('Block', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
        ],
      ),
    );
  }

  // --- Info Sections ---
  Widget _buildWorkerInfo(bool isDark) {
    final expYears = userData['experienceYears'];
    final expLabel = (expYears == null) ? 'New' : '$expYears Years';
    final priceLabel = _getSafeString(
      userData['priceText'],
      defaultValue: 'Negotiable',
    );
    final timeLabel = _getSafeString(
      userData['availability'],
      defaultValue: 'Not Set',
    );

    final String cvUrl = userData['cvUrl']?.toString() ?? '';
    final List<String> portfolioUrls = _safeStringList(userData['portfolioUrls']);

    return _section(
      'Work Information',
      Column(
        children: [
          _infoTile(Icons.work, 'Experience', expLabel, isDark),
          _infoTile(Icons.payments, 'Rate', priceLabel, isDark),
          _infoTile(Icons.access_time, 'Hours', timeLabel, isDark),
        ],
      ),
      isDark,
    );
  }

  Widget _buildSupporterInfo(bool isDark) {
    return _section('Company Information', Column(children: [
      _infoTile(Icons.business, 'Company', _getSafeString(userData['companyName'], defaultValue: 'Individual'), isDark),
      _infoTile(Icons.phone, 'Contact', _getSafeString(userData['companyContact'], defaultValue: 'Not Set'), isDark),
    ]), isDark);
  }

  Widget _buildAboutSection(bool isDark) {
    final about = _getSafeString(userData['about'], defaultValue: 'No bio added yet.');
    return _section('About Me', Text(about, style: TextStyle(height: 1.5, color: isDark ? Colors.white70 : Colors.black87)), isDark);
  }

  Widget _section(String title, Widget content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMain, fontSize: 15)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppColors.brandMain),
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
      trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[700])),
    );
  }

  Widget _clickableInfoTile({required IconData icon, required String title, required String value, required VoidCallback onTap, required bool isDark}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppColors.brandMain),
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
      trailing: Row(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[700])), const Icon(Icons.chevron_right, size: 16, color: Colors.grey)]),
    );
  }

  Widget _buildUserInfo(String roleLabel, bool isDark) {
    return Column(
      children: [
        Text(
          _getSafeString(userData['name']).toUpperCase(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(roleLabel.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // --- Visitor Actions ---
  Widget _buildVisitorActionBar(bool isDark) {
    final paused = (userData['workPaused'] ?? false) == true;
    final bool isWorker = _isWorkerRole();
    final bool hasPhone = userData['phone']?.toString().isNotEmpty == true;
    final barColor = isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8), // আগে all(16) ছিল
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5))],
        border: Border.all(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.3), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildVisitorActionButton(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', color: Colors.blue, onPressed: () => _openChat(isWorker ? "Worker" : "Supporter"), isDark: isDark),
            const SizedBox(width: 12),
            if (hasPhone && isWorker) _buildVisitorActionButton(icon: Icons.call_outlined, label: 'Call', color: Colors.green, onPressed: _makePhoneCall, isDark: isDark)
            else if (!isWorker) _buildVisitorActionButton(icon: Icons.email_outlined, label: 'Email', color: Colors.orange, onPressed: _sendEmail, isDark: isDark),
            if ((hasPhone && isWorker) || !isWorker) const SizedBox(width: 12),
            Expanded(child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.brandMain, AppColors.brandMain.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Material(color: Colors.transparent, child: InkWell(onTap: paused ? null : () => _handleHireOrRequest(isWorker), borderRadius: BorderRadius.circular(15), child: Center(child: Text(isWorker ? 'HIRE NOW' : 'SEND REQUEST', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))))))),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed, required bool isDark}) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Material(color: Colors.transparent, child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(15), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 22), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color))]))),
    );
  }

  // --- Other Helpers (Unchanged Logic, added isDark if needed) ---
  Widget _buildEngagementRow(int followersCount, int followingCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark ? [Colors.grey.shade800.withOpacity(0.3), Colors.grey.shade900.withOpacity(0.3)] : [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: widget.isOwner ? _buildOwnerStats(followersCount, followingCount, isDark) : _buildVisitorEngagement(followersCount, followingCount, isDark),
    );
  }

  Widget _buildOwnerStats(int followers, int following, bool isDark) {
    return Row(children: [Expanded(child: _statCard(icon: Icons.trending_up, count: followers, label: 'Followers', growth: followers > 100 ? '+12%' : null, isDark: isDark, onTap: _showFollowersList)), const SizedBox(width: 8), Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.3)), const SizedBox(width: 8), Expanded(child: _statCard(icon: Icons.group, count: following, label: 'Following', isDark: isDark, onTap: _showFollowingList))]);
  }

  Widget _buildVisitorEngagement(int followers, int following, bool isDark) {
    return Row(children: [Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 400), curve: Curves.fastOutSlowIn, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isFollowing ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : AppColors.brandMain, boxShadow: [if (!isFollowing) BoxShadow(color: AppColors.brandMain.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]), child: Material(color: Colors.transparent, child: InkWell(onTap: _toggleFollow, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: isFollowing ? Icon(Icons.done_all, key: const ValueKey('following'), color: isDark ? Colors.white70 : Colors.grey.shade700, size: 20) : const Icon(Icons.person_add_alt_1, key: ValueKey('follow'), color: Colors.white, size: 20)), const SizedBox(width: 8), AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: isFollowing ? Text('Following'.toUpperCase(), key: const ValueKey('following_text'), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14)) : Text('Follow'.toUpperCase(), key: const ValueKey('follow_text'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))],)))))), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.2)), color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.brandMain), const SizedBox(width: 6), Text(_formatNumber(followers), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]), const SizedBox(height: 2), Text('Followers', style: TextStyle(fontSize: 10, color: Colors.grey.shade500))]))]);
  }

  Widget _statCard({required IconData icon, required int count, required String label, String? growth, required bool isDark, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: AppColors.brandMain), Text(_formatNumber(count), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]));
  }

  Widget _buildBadgeSection(BadgeLevel badge) { return Column(children: [Icon(AppBadgeTheme.baseIcon, color: AppBadgeTheme.colorForLevel(badge), size: 45), const SizedBox(height: 5), Text(badge.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))]); }
  Widget _buildStatusPills(double rating, int completed) { final pills = <Widget>[]; if (userData['kyc_completed'] == true) pills.add(_pill('Verified', Colors.blue, Icons.verified)); if (rating >= 4.9) pills.add(_pill('Top Rated', Colors.orange, Icons.star)); if (completed >= 50 && rating >= 4.5) pills.add(_pill('Trusted', Colors.green, Icons.shield)); return Row(mainAxisAlignment: MainAxisAlignment.center, children: pills); }
  Widget _pill(String label, Color color, IconData icon) { return Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12.0, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))])); }

  Widget _buildProfileImageWithOnline() {
    final imageUrl = _getSafeString(userData['image'], defaultValue: '');
    final hasImage = imageUrl.isNotEmpty;

    return Stack(
      children: [
        Hero(
          tag: 'profile_${widget.uid}',
          child: ClipOval(
            child: SizedBox(
              width: 130,
              height: 130,
              child: hasImage
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/profile_avatar.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                errorWidget: (context, _, __) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              )
                  : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/profile_avatar.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!widget.isOwner)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
  void _showFollowersList() { Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersFollowingScreen(userId: widget.uid, listType: FollowListType.followers))); }
  void _showFollowingList() { Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersFollowingScreen(userId: widget.uid, listType: FollowListType.following))); }
  Widget _buildSocialLinks() { final fb = userData['facebookUrl']?.toString() ?? ""; final ig = userData['instagramUrl']?.toString() ?? ""; final linkedin = userData['linkedInUrl']?.toString() ?? ""; final socialLinks = <Widget>[]; if (fb.isNotEmpty) socialLinks.add(IconButton(icon: const Icon(Icons.facebook, color: Colors.blue, size: 30), onPressed: () => _launchUrl(fb))); if (ig.isNotEmpty) socialLinks.add(IconButton(icon: const Icon(Icons.camera_alt, color: Colors.pink, size: 28), onPressed: () => _launchUrl(ig))); if (linkedin.isNotEmpty) socialLinks.add(IconButton(icon: const Icon(Icons.work, color: Color(0xFF0077B5), size: 28), onPressed: () => _launchUrl(linkedin))); return socialLinks.isEmpty ? const SizedBox.shrink() : Row(mainAxisAlignment: MainAxisAlignment.center, children: socialLinks); }
  bool _isWorkerRole() { final role = (userData['userRole'] ?? 'finder').toString().toLowerCase(); return role == 'finder'; }
  String _getSafeString(dynamic value, {String defaultValue = 'N/A'}) { if (value == null) return defaultValue; if (value is String && value.isEmpty) return defaultValue; return value.toString(); }
  Future<void> _launchUrl(String url) async { try { if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url)); } } catch (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link'))); } }
  // 📋 Updated Menu Items (Dynamic Text)
  List<PopupMenuEntry<ProfileMenuOwner>> _buildOwnerMenuItems(String subscriptionType) {
    final bool isFreeUser = subscriptionType == 'free';

    // বর্তমান স্টেট চেক করা
    final bool isLocked = userData['accountLocked'] == true;
    final bool isPaused = userData['workPaused'] == true;
    final bool isHidden = userData['profileHidden'] == true;

    Widget menuRow(IconData icon, String text, Color color, {bool showLock = false}) {
      return Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (showLock) const Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      );
    }

    return [
      PopupMenuItem(
        value: ProfileMenuOwner.edit,
        child: menuRow(Icons.edit_rounded, 'Edit Profile', Colors.blue),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.shareProfile,
        child: menuRow(Icons.share_rounded, 'Share Profile', Colors.green),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.previewPublicCard,
        child: menuRow(Icons.visibility_rounded, 'Preview Card', Colors.purple),
      ),
      const PopupMenuDivider(),

      // 🔒 Lock / Unlock
      PopupMenuItem(
        value: ProfileMenuOwner.lockAccount,
        child: menuRow(
            isLocked ? Icons.lock_open_rounded : Icons.lock_outline,
            isLocked ? 'Unlock Profile' : 'Lock Profile',
            Colors.redAccent,
            showLock: isFreeUser
        ),
      ),

      // 🎨 Theme
      PopupMenuItem(
        value: ProfileMenuOwner.theme,
        child: menuRow(Icons.palette_rounded, 'Change Theme', Colors.orange, showLock: isFreeUser),
      ),

      // 👁️ Hide / Unhide
      PopupMenuItem(
        value: ProfileMenuOwner.hideProfile,
        child: menuRow(
            isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            isHidden ? 'Unhide Profile' : 'Hide Profile',
            Colors.grey,
            showLock: isFreeUser
        ),
      ),

      // ⏸️ Pause / Resume
      PopupMenuItem(
        value: ProfileMenuOwner.pauseWork,
        child: menuRow(
            isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
            isPaused ? 'Resume Work' : 'Pause Work',
            Colors.amber.shade800,
            showLock: isFreeUser
        ),
      ),
    ];
  }
  void _handleOwnerMenu(ProfileMenuOwner value) { final subscriptionType = userData['subscription_type']?.toString() ?? 'free'; final bool isFreeUser = subscriptionType == 'free'; switch (value) { case ProfileMenuOwner.edit: Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileEditScreen(uid: widget.uid))); break; case ProfileMenuOwner.shareProfile: _shareProfile(); break; case ProfileMenuOwner.previewPublicCard: _showPublicCardPreviewBottomSheet(); break; case ProfileMenuOwner.lockAccount: case ProfileMenuOwner.hideProfile: case ProfileMenuOwner.pauseWork: if (isFreeUser) { _showUpgradeToPremiumPopup(); } else { _handlePremiumFeature(value); } break; case ProfileMenuOwner.theme: _showCardThemeBottomSheet(); break; } }
  void _handlePremiumFeature(ProfileMenuOwner value) async {
    // বর্তমান ভ্যালু টগল করা (True -> False, False -> True)
    if (value == ProfileMenuOwner.lockAccount) {
      final current = userData['accountLocked'] == true;
      await _setAccountLocked(!current);
      // লোকাল স্টেট আপডেট যাতে সাথে সাথে UI চেইঞ্জ হয়
      setState(() {
        userData['accountLocked'] = !current;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(current ? "Profile Unlocked" : "Profile Locked")));
    }
    else if (value == ProfileMenuOwner.hideProfile) {
      final current = userData['profileHidden'] == true;
      await _setProfileHidden(!current);
      setState(() {
        userData['profileHidden'] = !current;
      });
    }
    else if (value == ProfileMenuOwner.pauseWork) {
      final current = userData['workPaused'] == true;
      await _setWorkPaused(!current);
      setState(() {
        userData['workPaused'] = !current;
      });
    }
  }
  Future<void> _shareProfile() async { final userName = _getSafeString(userData['name'], defaultValue: 'FindUs User'); final profileLink = 'https://findus.app/profile/${widget.uid}'; await Share.share('Check out $userName on FindUs!\n$profileLink'); }
  void _showUpgradeToPremiumPopup() { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Upgrade to Premium'), content: const Text('Unlock exclusive features like Locking Account, Custom Themes, and more!'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')), ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())); }, child: const Text('Upgrade'))])); }
  void _showUpgradeToBusinessPopup() { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Upgrade to Business'), content: const Text('Unlock Team Management and other business features!'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')), ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())); }, child: const Text('Upgrade'))])); }
  void _openChat(String roleLabel) async { final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: widget.uid); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: cid, userName: _getSafeString(userData['name']), userRole: roleLabel, userImage: _getSafeString(userData['image'])))); }
  void _makePhoneCall() async { final phone = userData['phone']?.toString(); if (phone != null && phone.isNotEmpty) _launchUrl('tel:$phone'); }
  void _sendEmail() async { final email = userData['email']?.toString(); if (email != null && email.isNotEmpty) _launchUrl('mailto:$email'); }
  void _handleHireOrRequest(bool isWorker) { showModalBottomSheet(context: context, builder: (ctx) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(isWorker ? 'Hire Options' : 'Request Options', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10), ListTile(leading: const Icon(Icons.send), title: const Text('Send Proposal'), onTap: () { Navigator.pop(ctx); _openChat(isWorker ? 'Worker' : 'Supporter'); })]))); }
  void _openPortfolioViewer(List<String> urls, {int initialIndex = 0}) { Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => _PortfolioViewer(urls: urls, initialIndex: initialIndex))); }
  String _formatNumber(int num) { if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M'; if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K'; return num.toString(); }
  List<String> _safeStringList(dynamic value) {
    if (value is Iterable) {
      try {
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return <String>[];
      }
    }
    return <String>[];
  }
  bool get _isBusinessUser { return (userData['subscription_type'] ?? 'free') == 'business'; }
  Widget _buildShimmerLoading() { return Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: ListView(shrinkWrap: true, children: [Container(height: 200, margin: const EdgeInsets.all(16), color: Colors.white), Container(height: 100, margin: const EdgeInsets.all(16), color: Colors.white), Container(height: 100, margin: const EdgeInsets.all(16), color: Colors.white)])); }
  // ✅ Fix for UnifiedProfileState.dart

  // 👁️ Preview Public Card
  // 👁️ Preview Public Card (Updated for Hired Label)
  void _showPublicCardPreviewBottomSheet() {
    final bool isWorker = _isWorkerRole();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "PUBLIC VIEW PREVIEW",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)]
                ),
              ),
              const SizedBox(height: 15),

              UniversalWorkerCard(
                id: widget.uid,
                name: (userData['name'] ?? 'User').toString(),
                role: isWorker ? "Worker" : "Supporter",
                imageUrl: (userData['image'] ?? '').toString(),
                address: (userData['location'] ?? 'Location not set').toString(),
                rating: (userData['rating'] ?? 0).toString(),
                completed: (userData['completedCount'] ?? 0).toString(),
                reviews: (userData['reviewsCount'] ?? 0).toString(),
                price: (userData['priceText'] ?? userData['priceLabel'] ?? 'Negotiable').toString(),
                isVerifiedWorker: userData['kyc_completed'] == true,
                colorIndex: _cardThemeIndex,

                // 🔥🔥 UPDATE HERE
                // ১. সাপোর্টার হলেও এখন স্ট্যাটস দেখাবে (Hired সংখ্যা দেখানোর জন্য)
                showStats: true,

                // ২. যদি ওয়ার্কার হয় তবে "JOBS", আর সাপোর্টার হলে "HIRED"
                jobLabel: isWorker ? "JOBS" : "HIRED",

                showActionButtons: false,
                onTap: () {},
              ),

              const SizedBox(height: 30),

              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDynamicBottomSection(bool isWorker, bool isDark) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (widget.isOwner) _buildOwnerSuggestions(isWorker, isDark) else _buildVisitorContent(isWorker, isDark)]); }
  Widget _buildOwnerSuggestions(bool isWorker, bool isDark) { final target = isWorker ? 'supporter' : 'worker'; return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [_sectionTitle('Suggested for You', isDark), _buildSuggestionStream(target, 'Sponsored', Colors.amber, isDark), const SizedBox(height: 20), _buildSuggestionStream(target, 'Nearby', Colors.blue, isDark)]); }
  Widget _buildVisitorContent(bool isWorker, bool isDark) { return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [_sectionTitle('User Posts', isDark), _buildOwnerPostsStream(isDark), const SizedBox(height: 20), _sectionTitle(isWorker ? 'Similar Workers' : 'Similar Supporters', isDark), _buildSimilarStream(isWorker, isDark)]); }
  Widget _buildOwnerPostsStream(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: widget.uid)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No active posts',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          );
        }

        final docs = snap.data!.docs;

        return SizedBox(
          height: 305,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;

              return SizedBox(
                width: screenWidth * 0.85,
                child: UniversalWorkerCard(
                  id: d.id,
                  name: data['title'] ?? 'No Title',
                  role: data['roleLabel'] ?? 'Worker',
                  imageUrl: userData['image'] ?? '',
                  address: data['address'] ?? 'Location not set',
                  rating: "0.0",
                  completed: "0",
                  reviews: "0",
                  price: data['priceLabel'] ?? 'Negotiable',

                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  showActionButtons: true,
                  primaryButtonText: "View Job Details",


                  // ✅ ফিক্স করা অংশ:
                  onViewProfileTap: () {
                    // ১. সঠিক প্যারামিটার দিয়ে Worker অবজেক্ট তৈরি
                    final workerObj = Worker(
                      uid: widget.uid,
                      postId: d.id, // ✅ postId এখানে পাস করা হলো
                      name: userData['name'] ?? 'User',
                      userRole: userData['userRole'] ?? 'finder',
                      image: userData['image'] ?? '',
                      about: userData['about'] ?? '', // ✅ about ফিল্ড
                      location: userData['location'] ?? 'Unknown',
                      rating: double.tryParse(userData['rating']?.toString() ?? '0') ?? 0.0,

                      // ✅ Price লজিক
                      priceText: data['priceLabel'] ?? userData['priceText'] ?? 'Negotiable',
                      price: double.tryParse(userData['price']?.toString() ?? '0'),

                      // ✅ আপনার মডেলে এটি 'kycCompleted', 'kyc_completed' নয়
                      kycCompleted: userData['kyc_completed'] == true,

                      // ✅ আপনার মডেলে এটি 'experience' (double), String নয়
                      experience: double.tryParse(userData['experienceYears']?.toString() ?? '0'),

                      phone: userData['phone'],
                    );

                    // ২. সঠিক স্ক্রিনে পাঠানো
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerJobDetailsScreen(worker: workerObj),
                      ),
                    );
                  },

                  showSaveButton: false,
                  showShareButton: false,
                  onChatTap: null,
                ),
              );
            },
          ),
        );
      },
    );
  }
  // --- Updated Suggestion Methods ---

  Widget _buildSimilarStream(bool isWorker, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // ✅ Stream যোগ করা হয়েছে
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userRole', isEqualTo: isWorker ? 'finder' : 'maker')
          .where('kyc_completed', isEqualTo: true)
          .limit(5) // Limit একটু বাড়ানো হলো
          .snapshots(),

      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(
              height: 100,
              child: Center(
                  child: Text(
                      'No similar profiles found',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)
                  )
              )
          );
        }

        final docs = snap.data!.docs.where((d) => d.id != widget.uid).toList();
        if (docs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 260, // ✅ হাইট ফিক্সড
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;

              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: UniversalWorkerCard(
                  id: docs[index].id,
                  name: (d['name'] ?? 'User').toString(),
                  role: (d['userRole'] ?? 'worker').toString(),
                  imageUrl: (d['image'] ?? '').toString(),
                  address: (d['location'] ?? 'Location not set').toString(),
                  rating: (d['rating'] ?? 0).toString(),
                  completed: "0",
                  reviews: "0",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: docs[index].id, isOwner: false, showBack: true))
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestionStream(String role, String tag, Color col, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // ✅ Stream যোগ করা হয়েছে
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userRole', isEqualTo: role == 'worker' ? 'finder' : 'maker')
          .limit(1)
          .snapshots(),

      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(
              height: 100,
              child: Center(
                  child: Text(
                      'No suggestions available',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)
                  )
              )
          );
        }

        final doc = snap.data!.docs.first;
        final d = doc.data() as Map<String, dynamic>;

        return SizedBox(
          height: 320, // ✅ হাইট ফিক্সড
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                    tag,
                    style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.bold)
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: UniversalWorkerCard(
                    id: doc.id,
                    name: (d['name'] ?? 'User').toString(),
                    role: (d['userRole'] ?? role).toString(),
                    imageUrl: (d['image'] ?? '').toString(),
                    address: (d['location'] ?? 'Location not set').toString(),
                    rating: (d['rating'] ?? 0).toString(),
                    completed: "0",
                    reviews: "0",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: doc.id, isOwner: false, showBack: true))
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _sectionTitle(String title, bool isDark) { return Padding(padding: const EdgeInsets.only(left: 16, top: 25, right: 16, bottom: 10), child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: isDark ? Colors.white70 : Colors.black87))); }
}

class _PortfolioViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PortfolioViewer({required this.urls, this.initialIndex = 0});

  @override
  State<_PortfolioViewer> createState() => _PortfolioViewerState();
}

class _PortfolioViewerState extends State<_PortfolioViewer> {
  late PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_index + 1}/${widget.urls.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (ctx, i) {
          return Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain, // ✅ ইমেজ যেন পুরোটা দেখা যায়
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text("Failed to load image", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
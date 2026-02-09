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
import 'package:findus_app/badge/badge_service.dart';


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
import 'package:findus_app/screens/explore/notifications_page.dart';
import 'package:findus_app/screens/profile/worker_documents_screen.dart';
import 'package:findus_app/screens/rating_history_screen.dart';
import 'package:findus_app/screens/tabs/leaderboard_screen.dart';
import '../../models/worker_model.dart';
import 'card_theme_bottom_sheet.dart';
import 'followers_following_screen.dart';

// Enums
enum ProfileMenuOwner { edit, shareProfile, previewPublicCard, lockAccount, theme, hideProfile, pauseWork }
enum ProfileMenuOther { report, block }

StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStatsSub;
Map<String, dynamic> userStats = {};

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _postsSectionKey = GlobalKey();

  // Theme & Stats
  int _cardThemeIndex = 0;
  int _followersCountLive = 0;
  int _followingCountLive = 0;
  int _unreadNotifCount = 0;

  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  // 🎨 Theme Gradients (Same as BottomSheet)
  final List<List<Color>> _themeGradients = const [
    [Color(0xFF00DDFA), Color(0xFFFFFFFF)], // Teal (Light)
    [Color(0xFFffd966), Color(0xFFFFFFFF)], // Orange (Light)
    [Color(0xFF6fa8dc), Color(0xFFFFFFFF)], // Indigo (Light)
    [Color(0xFFf7bcbc), Color(0xFFFFFFFF)], // Pink (Light)
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    if (widget.isOwner) {
      _listenToNotifications();
    }
    _badgeListener = () {
      if (mounted) {
        setState(() {
          // যখনই ব্যাজ বা এক্সপি আপডেট হবে, UI রিফ্রেশ হবে
          // userData['user_badge_points'] আপডেট করার দরকার নেই যদি আমরা সরাসরি সার্ভিস থেকে ডাটা নেই
        });
      }
    };
    BadgeService.badgeNotifier.addListener(_badgeListener); // লিসেনার অন করা হলো

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
    BadgeService.badgeNotifier.removeListener(_badgeListener);
    _userSub?.cancel();
    _userStatsSub?.cancel();
    _scrollController.dispose();
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

  late VoidCallback _badgeListener;

  void _listenToUserData() {
    _listenToUserStats();
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() ?? {};

      // ✅ সার্ভিসে পয়েন্ট সেট করা (যাতে অ্যাপের সব জায়গায় আপডেট হয়)
      if (widget.isOwner) {
        final rawXp = data['user_badge_points'] ?? data['xpPoints'] ?? 0;
        final int xp = int.tryParse(rawXp.toString()) ?? 0;
        BadgeService.setPointsFromServer(xp); // এই মেথডটি সার্ভিসে থাকতে হবে
      }
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

  void _listenToUserStats() {
    _userStatsSub?.cancel();
    _userStatsSub = FirebaseFirestore.instance
        .collection('user_stats')
        .doc(widget.uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        userStats = snap.data() ?? {};
      });
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

    // ✅ এখানে নিশ্চিত করুন যে 'isRead' ফিল্ডটি বুলিয়ান (true/false) এবং ফায়ারবেসে ঠিক আছে
    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false) // শুধু আনরেড নোটিফিকেশনগুলো কাউন্ট হবে
        .snapshots()
        .listen((q) {
      if (mounted) {
        setState(() {
          _unreadNotifCount = q.docs.length; // ✅ সাইজ আপডেট হচ্ছে
        });
      }
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
            // build মেথডের actions অংশে
            actions: widget.isOwner
                ? [
              _buildActionButton(
                Icons.notifications_none_rounded,
                'Notifications',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                isDark,
                showBadge: true, // ✅ ব্যাজ দেখানো হবে
                badgeCount: _unreadNotifCount, // ✅ রিয়েল-টাইম কাউন্ট
              ),
              // ... বাকি বাটনগুলো (Team, Settings, Menu)
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
                  controller: _scrollController,
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

  // 🏞️ Header with Dynamic Theme Support
  Widget _buildHeaderCard(String roleLabel, bool isDark) {
    // ১. ডাটা লোডিং (BadgeService থেকে)
    final badgeProgress = BadgeService.badgeNotifier.value;

    // XP এবং Stars ডাটা নেওয়া
    int xp;
    double stars;

    if (widget.isOwner) {
      xp = badgeProgress.totalXP;
      stars = badgeProgress.totalStars;
    } else {
      xp = int.tryParse((userData['xpPoints'] ?? 0).toString()) ?? 0;
      stars = double.tryParse((userData['user_accumulated_stars'] ?? 0.0).toString()) ?? 0.0;
    }

    // ব্যাজ র‍্যাঙ্ক ক্যালকুলেশন
    final badgeRank = BadgeService.getBadgeByStars(stars);
    final numericLevel = BadgeService.getNumericLevel(xp);
    final badgeColor = badgeProgress.badgeColor; // অথবা _getBadgeColor(badgeRank)
    final isNewbie = badgeRank == BadgeLevel.newbie;

    // থিম কালার
    final int themeIdx = (_cardThemeIndex as int).clamp(0, _themeGradients.length - 1);
    final List<Color> selectedTheme = _themeGradients[themeIdx];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] : selectedTheme,
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
                  gradient: _getBadgeGradient(badgeRank),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -30, left: -30, child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.1))),

                    // Badge (Top Right)
                    Positioned(
                      top: 20, right: 20,
                      child: GestureDetector(
                        onTap: () => _showBadgeDetails(badgeRank, xp, stars), // ✅ আপডেটেড মেথড কল
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
                                Icons.workspace_premium, // আপনার পছন্দের নতুন আইকন
                                color: badgeColor,       // কালার ভেরিয়েবল যা আছে তাই থাকবে
                                size: 36,                // সাইজ প্রয়োজনে বাড়াতে/কমাতে পারেন
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
                                badgeRank.toString().split('.').last.toUpperCase(),
                                style: TextStyle(
                                  color: isNewbie ? Colors.white : badgeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar Section
              Positioned(
                bottom: -55,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Profile Image
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, width: 5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: ClipOval(child: _buildCoverProfileImage()),
                    ),

                    // 🔥 LEVEL BADGE (Bottom Center)
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          "LVL $numericLevel", // ✅ Level Display
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Online Status
                    if (isOnline)
                      Positioned(
                        bottom: 10, right: 6,
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 65),

          // Name and Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _getSafeString(userData['name']).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userData['accountLocked'] == true) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock_outline, size: 18, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandMain, letterSpacing: 1.5),
                ),
                const SizedBox(height: 25),

                // Social Row & Stats
                _buildHeaderStatsRow(isDark, stars.toInt(), xp), // ✅ নতুন হেল্পার মেথড
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Stats Row Helper ---

  Widget _buildHeaderStatsRow(bool isDark, int stars, int xp) {
    // 1. Rating & Completed Count
    final double rating = double.tryParse(userData['rating']?.toString() ?? '0.0') ?? 0.0;
    final int completed = int.tryParse(userData['completedCount']?.toString() ?? '0') ?? 0;

    // 2. Get Leaderboard Rank from userStats
    // যদি র‍্যাঙ্ক না থাকে তবে 'N/A' দেখাবে
    final int rank = int.tryParse(userStats['leaderboardRank']?.toString() ?? '0') ?? 0;
    final String rankDisplay = rank > 0 ? "#$rank" : "N/A";

    return Row(
      children: [
        // 1. Rating Box
        _buildFloatingStatBox(
          "RATING",
          rating.toStringAsFixed(1),
          Icons.star_rounded,
          Colors.amber,
          isDark,
          onTap: _openRatingHistory,
        ),

        const SizedBox(width: 12),

        // 2. Jobs / Hired Box
        _buildFloatingStatBox(
          _isWorkerRole() ? "JOBS" : "HIRED",
          "$completed",
          _isWorkerRole() ? Icons.work_outline : Icons.handshake_rounded,
          Colors.blue,
          isDark,
        ),

        const SizedBox(width: 12),

        // 3. RANK BOX (Replaces XP) ✅
        _buildFloatingStatBox(
          "RANK",
          rankDisplay,
          // ✅ এখানে আইকন চেঞ্জ করা হয়েছে
          Icons.workspace_premium,
          const Color(0xFFFFD700),
          isDark,
          onTap: () {
            // ✅ Rank এ ক্লিক করলে AppBar সহ লিডারবোর্ড ওপেন হবে
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaderboardScreen(isStandalone: true),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Badge Details Dialog (Updated for Dual System) ---
  void _showBadgeDetails(BadgeLevel badge, int xp, double stars) {
    final badgeColor = _getBadgeColor(badge);
    final badgeName = badge.toString().split('.').last.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Next Rank Threshold (Stars)
    final double nextStarThreshold = _getNextStarThreshold(badge);
    final double starProgress = _calculateStarProgress(stars, badge);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: badgeColor, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text("$badgeName RANK", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: badgeColor))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank Progress (Stars)
            _buildDialogProgressRow("Rank Progress", stars, nextStarThreshold, starProgress, badgeColor, "Stars", isDark),
            const SizedBox(height: 20),
            // Level Progress (XP)
            _buildDialogXPInfo(xp, isDark),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CLOSE", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildDialogProgressRow(String title, double current, double target, double progress, Color color, String unit, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation(color), minHeight: 6, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${current.toStringAsFixed(0)} $unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black)),
            Text("Goal: ${target.toStringAsFixed(0)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogXPInfo(int xp, bool isDark) {
    final lvl = BadgeService.getNumericLevel(xp);
    final nextLvlXp = BadgeService.getXpForLevel(lvl + 1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.orange),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Current Level: $lvl", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text("$xp / $nextLvlXp XP", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers
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

  double _calculateStarProgress(double stars, BadgeLevel level) {
    double next = _getNextStarThreshold(level);
    double prev = (level == BadgeLevel.newbie) ? 0 : _getNextStarThreshold(BadgeLevel.values[level.index - 1]);
    if (next <= prev) return 1.0;
    return ((stars - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  // ---------------- HELPER METHODS ----------------



// Helper: Get next level points
  int _getNextLevelPoints(BadgeLevel currentLevel) {
    switch (currentLevel) {
      case BadgeLevel.newbie:
        return 1000;
      case BadgeLevel.bronze:
        return 10000;
      case BadgeLevel.silver:
        return 50000;
      case BadgeLevel.gold:
        return 100000;
      case BadgeLevel.platinum:
        return 1000000;
      case BadgeLevel.diamond:
        return 1000000;
    }
  }

// Helper: Get next level name
  String _getNextLevelName(BadgeLevel currentLevel) {
    switch (currentLevel) {
      case BadgeLevel.newbie:
        return "BRONZE";
      case BadgeLevel.bronze:
        return "SILVER";
      case BadgeLevel.silver:
        return "GOLD";
      case BadgeLevel.gold:
        return "PLATINUM";
      case BadgeLevel.platinum:
        return "DIAMOND";
      case BadgeLevel.diamond:
        return "MAX LEVEL";
    }
  }

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

  // ✨ Helper: Clean Status Icon (Only Icon, No BG)
  Widget _buildCleanStatusIcon(IconData icon, bool isActive, Color color, String tooltip) {
    // ইনঅ্যাক্টিভ হলে গ্রে আইকন দেখাবে
    final iconColor = isActive ? color : Colors.grey.withOpacity(0.3);

    return Tooltip(
      message: isActive ? tooltip : "Not $tooltip",
      child: Container(
        padding: const EdgeInsets.all(4), // একটু টাচ এরিয়া বাড়ানোর জন্য
        decoration: isActive ? BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3), // শুধু অ্যাক্টিভ হলে গ্লো করবে
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ) : null,
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
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

  // 📦 Helper: Stat Box with Tap Support
  Widget _buildFloatingStatBox(
      String label,
      String value,
      IconData icon,
      Color iconColor,
      bool isDark,
      {VoidCallback? onTap} // ✅ onTap প্যারামিটার যোগ করা হলো
      ) {
    final boxBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50];
    final borderColor = isDark ? Colors.white10 : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Expanded(
      child: InkWell( // ✅ Container কে InkWell দিয়ে র্যাপ করা হলো
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }


  // _buildActionButton মেথডটি আপডেট করুন (নোটিফিকেশন ব্যাজ সাপোর্ট সহ)
  Widget _buildActionButton(
      IconData icon,
      String tooltip,
      VoidCallback onPressed,
      bool isDark, {
        bool showBadge = false, // ✅ নতুন প্যারামিটার
        int badgeCount = 0,     // ✅ নতুন প্যারামিটার
      }) {
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

          // 🔴 Red Dot Logic (ExploreScreen এর মতো)
          if (showBadge && badgeCount > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 10,
                height: 10,
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
  // 📞 Visitor Action Bar (Fixed Chat & Call)
  Widget _buildVisitorActionBar(bool isDark) {
    final paused = (userData['workPaused'] ?? false) == true;
    final bool isWorker = _isWorkerRole();
    final bool hasPhone = userData['phone']?.toString().isNotEmpty == true;
    final barColor = isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.all(12),
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
            // 💬 Chat Button (Fixed)
            _buildVisitorActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                color: Colors.blue,
                onPressed: () => _openChat(isWorker ? "Worker" : "Supporter"), // ✅ ওপেন চ্যাট মেথড কল
                isDark: isDark
            ),

            const SizedBox(width: 12),

            // 📞 Call Button (Always show if phone exists)
            if (hasPhone)
              _buildVisitorActionButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  color: Colors.green,
                  onPressed: _makePhoneCall, // ✅ কল মেথড
                  isDark: isDark
              )
            else
              _buildVisitorActionButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: Colors.orange,
                  onPressed: _sendEmail,
                  isDark: isDark
              ),

            const SizedBox(width: 12),

            // Hire/Request Button
            Expanded(
                child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.brandMain, AppColors.brandMain.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: paused
                                ? null
                                : () {
                              final ctx = _postsSectionKey.currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(
                                  ctx,
                                  duration: const Duration(milliseconds: 450),
                                  curve: Curves.easeInOut,
                                  alignment: 0.05,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Select a post below to apply.")),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Center(
                              child: const Text(
                                'VIEW POSTS',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            )
                        )
                    )
                )
            ),
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
  // 🌐 Social Icons (Fixed Layout)
  Widget _buildSocialLinks() {
    final fb = userData['facebookUrl']?.toString() ?? "";
    final ig = userData['instagramUrl']?.toString() ?? "";
    final linkedin = userData['linkedInUrl']?.toString() ?? "";

    final socialLinks = <Widget>[];
    if (fb.isNotEmpty) socialLinks.add(_socialBtn(Icons.facebook, Colors.blue, fb));
    if (ig.isNotEmpty) socialLinks.add(_socialBtn(Icons.camera_alt, Colors.pink, ig));
    if (linkedin.isNotEmpty) socialLinks.add(_socialBtn(Icons.work, const Color(0xFF0077B5), linkedin));

    if (socialLinks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: socialLinks,
      ),
    );
  }

  Widget _socialBtn(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }


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
  Future<void> _shareProfile() async {
    final String link = "https://findus.app/profile/${widget.uid}";
    await Share.share("Check out my profile on FindUs: $link");

    // ==================================================
    // ✅ ACHIEVEMENT & QUEST UPDATES
    // ==================================================

    // 1. Daily Share Quest
    await AchievementService.incrementProgress('daily_share');

    // 2. Long Term Invite/Share Chain
    await AchievementService.incrementProgress('lt_invite_s1');
    await AchievementService.incrementProgress('lt_invite_s2');
    await AchievementService.incrementProgress('lt_invite_s3');

    // 3. Sync Weekly Chest
    await AchievementService.syncWeeklyChestFromServer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shared successfully! Quest progress updated.")),
      );
    }
  }
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
  Widget _buildVisitorContent(bool isWorker, bool isDark) {
    // লজিক: যদি প্রোফাইলটি Worker হয়, তবে ভিজিটর সম্ভবত Maker (Supporter)।
    // তাই Worker এর সিমিলার প্রোফাইল সাজেস্ট করব।

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle('User Posts', isDark),
        Container(
          key: _postsSectionKey, // ✅ add
          child: _buildOwnerPostsStream(isDark),
        ),
        const SizedBox(height: 20),

        _sectionTitle(isWorker ? 'Similar Workers' : 'Similar Supporters', isDark),
        _buildSimilarStream(isWorker, isDark), // সিমিলার প্রোফাইল
      ],
    );
  }

  // 🗂️ User Posts Stream (Fixed Size & Actions)
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
            child: Center(child: Text('No active posts', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54))),
          );
        }

        final docs = snap.data!.docs;

        return SizedBox(
          height: 340, // ✅ হাইট বাড়ানো হয়েছে যাতে বাটনসহ পুরো কার্ড ধরে
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16), // সাইড প্যাডিং
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;

              return Container(
                width: screenWidth * 0.85, // ✅ রেসপন্সিভ উইডথ
                margin: const EdgeInsets.only(right: 16, bottom: 10), // কার্ডের মাঝে গ্যাপ
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

                  // ✅ বাটন এবং চ্যাট এনাবল
                  showActionButtons: true,
                  primaryButtonText: "View Job Details",

                  // ✅ জব ডিটেইলস অ্যাকশন
                  onViewProfileTap: () {
                    // Worker object তৈরি করে পাঠানো
                    final workerObj = Worker(
                      uid: widget.uid,
                      postId: d.id,
                      name: userData['name'] ?? 'User',
                      userRole: userData['userRole'] ?? 'finder',
                      image: userData['image'] ?? '',
                      about: userData['about'] ?? '',
                      location: userData['location'] ?? 'Unknown',
                      rating: double.tryParse(userData['rating']?.toString() ?? '0') ?? 0.0,
                      priceText: data['priceLabel'] ?? 'Negotiable',
                      price: double.tryParse(userData['price']?.toString() ?? '0'),
                      kycCompleted: userData['kyc_completed'] == true,
                      experience: double.tryParse(userData['experienceYears']?.toString() ?? '0'),
                      phone: userData['phone'],
                    );

                    Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerJobDetailsScreen(worker: workerObj)));
                  },

                  // ✅ কার্ডের চ্যাট বাটন (নিজের পোস্ট হলে চ্যাট ডিজেবল, ভিজিটর হলে এনাবল)
                  onChatTap: widget.isOwner ? null : () => _openChat("Worker"),

                  showSaveButton: false,
                  showShareButton: true,
                  onShareTap: () {
                    // শেয়ার লজিক (অপশনাল)
                  },
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
// lib/screens/profile/unified_profile_state.dart

import 'dart:async';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_theme.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/profile_color_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/team/team_management_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/settings/theme_settings_screen.dart';
import 'package:findus_app/screens/profile/followers_following_screen.dart';
import 'package:findus_app/services/card_theme_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

import '../../badge/badge_model.dart';
import '../explore/notifications_page.dart';
import 'card_theme_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';

// Enums (public, no underscore)
enum ProfileMenuOwner {
  edit,
  shareProfile,
  previewPublicCard,
  lockAccount,
  theme,
  hideProfile,
  pauseWork,
}

enum ProfileMenuOther {
  report,
  block,
}

class UnifiedProfileScreenState extends State<UnifiedProfileScreen> {

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  // follow count subs
  StreamSubscription? _followersCountSub;
  StreamSubscription? _followingCountSub;
  StreamSubscription? _onlineStatusSub;
  StreamSubscription? _themeChangeSubscription;
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  bool isFollowing = false;
  bool isBlocked = false;
  bool isOnline = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
  GlobalKey<RefreshIndicatorState>();


  final List<List<Color>> _themeGradients = const [
    [Color(0xFFB2EBF2), Color(0xFFFFFFFF)],
    [Color(0xFFFFCC80), Color(0xFFFFFFFF)],
    [Color(0xFFC5CAE9), Color(0xFFFFFFFF)],
    [Color(0xFFF8BBD0), Color(0xFFFFFFFF)],
  ];

  final List<String> _themeNames = const [
    'Teal',
    'Orange',
    'Indigo',
    'Pink',
  ];


  @override
  void dispose() {
    _userSub?.cancel();
    _onlineStatusSub?.cancel();
    _themeChangeSubscription?.cancel();

    _followersCountSub?.cancel();   // ✅ add
    _followingCountSub?.cancel();   // ✅ add
    _notifSub?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeCardTheme();
    if (widget.isOwner) {
      _listenToNotifications();
    }
  }
  int _cardThemeIndex = 0;

// ✅ ADD THESE
  int _followersCountLive = 0;
  int _followingCountLive = 0;
  int _unreadNotifCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;

  Future<void> _initializeCardTheme() async {
    // ✅ Theme index এখন user doc stream (_listenToUserData) থেকে আসবে।
    // তাই এখানে শুধু safe default দিচ্ছি।
    if (mounted) {
      setState(() => _cardThemeIndex = 0);
    }
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

  void _listenToNotifications() {
    _notifSub?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notifSub = FirebaseFirestore.instance
        .collection('notificationId')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((q) {
      if (!mounted) return;
      setState(() => _unreadNotifCount = q.size);
    }, onError: (e) {
      // optional: debug
      // print('Notification listen error: $e');
    });
  }

  void _showBlockedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('ব্লক করা ব্যবহারকারী'),
          content: const Text(
              'আপনি এই ব্যবহারকারীকে ব্লক করেছেন। প্রোফাইল দেখতে পারবেন না।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      ).then((_) => Navigator.pop(context));
    });
  }

  void _listenToFollowCounts() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();

    _followersCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('followers')
        .snapshots()
        .listen((q) {
      if (!mounted) return;
      setState(() => _followersCountLive = q.size);
    });

    _followingCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('following')
        .snapshots()
        .listen((q) {
      if (!mounted) return;
      setState(() => _followingCountLive = q.size);
    });
  }

  void _listenToUserData() {
    _userSub?.cancel();

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;

      final data = snap.data() ?? <String, dynamic>{};

      // ✅ card theme index user doc field থেকে
      final rawIdx = data['cardThemeIndex'];
      final idx = (rawIdx is int)
          ? rawIdx
          : int.tryParse(rawIdx?.toString() ?? '') ?? 0;

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


  Future<void> _checkIfFollowing() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('following')
          .doc(widget.uid)
          .get();

      if (mounted) setState(() => isFollowing = doc.exists);
    } catch (e) {
      print('Following check error: $e');
    }
  }

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
      batch.set(followRef, {
        'followedAt': DateTime.now(),
        'userName': userData['name']
      });
      batch.set(followerRef, {
        'followedAt': DateTime.now(),
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'User'
      });
      batch.update(userRef, {'followersCount': FieldValue.increment(1)});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
    }

    try {
      await batch.commit();
      if (mounted) setState(() => isFollowing = !isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _initializeCardTheme();
    // Force reload user data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get()
        .then((snap) {
      if (mounted) {
        setState(() {
          userData = snap.data() ?? {};
          isLoading = false;
        });
      }
    });
  }

  void _openPortfolioViewer(List<String> urls, {int initialIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PortfolioViewer(
          urls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _clickableInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 20, color: AppColors.brandMain),
            title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(width: 6),
                Icon(Icons.open_in_new, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setAccountLocked(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'accountLocked': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _setProfileHidden(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'profileHidden': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _setWorkPaused(bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'workPaused': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }



  // ===== UI BUILDERS =====

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ✅ Gradient Header Card (আসল UI এর মতো)
          Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Badge section
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 15),

                // Status pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildShimmerPill(),
                    const SizedBox(width: 8),
                    _buildShimmerPill(),
                    const SizedBox(width: 8),
                    _buildShimmerPill(),
                  ],
                ),

                const SizedBox(height: 25),

                // Profile image circle
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(height: 16),

                // Name and role
                Column(
                  children: [
                    Container(
                      width: 200,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Stats row (আসল UI এর মতো ৩টা আইকন)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShimmerStatItem(),
                    _buildShimmerStatItem(),
                    _buildShimmerStatItem(),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 30),

                // Followers/Following row
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[200]!, Colors.grey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildShimmerStatCard()),
                      Container(width: 1, height: 50, color: Colors.grey[300]),
                      Expanded(child: _buildShimmerStatCard()),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Social Links
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ),
            ),
          ),

          // Worker/Supporter Info Section
          _buildShimmerSection(
            titleWidth: 120,
            child: Column(
              children: List.generate(4, (index) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),

          // About Section
          _buildShimmerSection(
            titleWidth: 120,
            child: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Suggestions Section (আসল UI এর মতো horizontal list)
          _buildShimmerSection(
            titleWidth: 150,
            child: SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(3, (index) => Container(
                  width: 180,
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper methods for shimmer
  Widget _buildShimmerPill() {
    return Container(
      width: 70,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildShimmerStatItem() {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerStatCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSection({required double titleWidth, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: titleWidth,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Tooltip(
      message: 'Notifications',
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 20, color: Colors.black),
              splashRadius: 20,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications screen not set')),
                );
              },
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    _unreadNotifCount > 99 ? '99+' : _unreadNotifCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final locked = (userData['accountLocked'] ?? false) == true;
    final hidden = (userData['profileHidden'] ?? false) == true;

    if (!widget.isOwner && (locked || hidden)) {
      return Column(
        children: [
          _buildHeaderCard(_isWorkerRole() ? "Worker" : "Supporter"),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              locked
                  ? 'এই প্রোফাইলটি লক করা আছে।'
                  : 'এই প্রোফাইলটি বর্তমানে হাইড করা আছে।',
            ),
          ),
          const SizedBox(height: 100),
        ],
      );
    }
    final bool isWorker = _isWorkerRole();
    final String roleLabel = isWorker ? "Worker" : "Supporter";

    return Column(
      children: [
        _buildHeaderCard(roleLabel),
        _buildSocialLinks(),
        isWorker ? _buildWorkerInfo() : _buildSupporterInfo(),
        _buildAboutSection(),
        _buildDynamicBottomSection(isWorker),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeaderCard(String roleLabel) {
    final int xp = int.tryParse(userData['user_badge_points']?.toString() ?? '0') ?? 0;
    final double rating = double.tryParse(userData['rating']?.toString() ?? '0.0') ?? 0.0;
    final int completed = int.tryParse(userData['completedCount']?.toString() ?? '0') ?? 0;
    final int reviews = int.tryParse(userData['reviewsCount']?.toString() ?? '0') ?? 0;
    final badge = AchievementService.getBadgeLevelByPoints(xp);
    final followersCount = _followersCountLive;
    final followingCount = _followingCountLive;

    final colors = _themeGradients[_cardThemeIndex.clamp(0, _themeGradients.length - 1)];

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16, // ✅ AppBar থেকে নিচে নামবে
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBadgeSection(badge),
          const SizedBox(height: 15),
          _buildStatusPills(rating, completed),
          const SizedBox(height: 25),
          _buildProfileImageWithOnline(),
          const SizedBox(height: 16),
          _buildUserInfo(roleLabel),
          const SizedBox(height: 25),
          _buildStatsRow(rating, completed, reviews),
          const Divider(height: 30),
          _buildEngagementRow(followersCount, followingCount),
        ],
      ),
    );
  }

  void _showPortfolioBottomSheet(List<String> urls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, color: AppColors.brandMain),
                        const SizedBox(width: 10),
                        Text('Portfolio (${urls.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: urls.length,
                      itemBuilder: (context, i) {
                        final url = urls[i];
                        return GestureDetector(
                          onTap: () => _openPortfolioViewer(urls, initialIndex: i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (c, _) => Container(color: Colors.grey[200]),
                              errorWidget: (c, _, __) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeSection(BadgeLevel badge) {
    return Column(
      children: [
        Icon(
          AppBadgeTheme.baseIcon,
          color: AppBadgeTheme.colorForLevel(badge),
          size: 45,
        ),
        const SizedBox(height: 5),
        Text(
          badge.name.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPills(double rating, int completed) {
    final pills = <Widget>[];

    if (userData['kyc_completed'] == true) {
      pills.add(_pill(
        'যাচাইকৃত',
        Colors.blue,
        Icons.verified,
      ));
    }

    if (rating >= 4.9) {
      pills.add(_pill(
        'সর্বোচ্চ রেটেড',
        Colors.orange,
        Icons.star,
      ));
    }

    if (completed >= 50 && rating >= 4.5) {
      pills.add(_pill(
        'বিশ্বস্ত',
        Colors.green,
        Icons.shield,
      ));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pills,
    );
  }

  Widget _buildProfileImageWithOnline() {
    final imageUrl = _getSafeString(
      userData['image'],
      defaultValue: '',
    );

    final hasImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? _showImageFullScreen : null,
      child: Stack(
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
                        'assets/lottie/Profile Avatar.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Lottie.asset(
                        ('assets/lottie/profile_avatar.json'),
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Lottie.asset(
                      ('assets/lottie/profile_avatar.json'),
                      fit: BoxFit.contain,
                      repeat: true,
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

      ),
    );
  }

  Widget _buildSocialLinks() {
    final fb = userData['facebookUrl']?.toString() ?? "";
    final ig = userData['instagramUrl']?.toString() ?? "";
    final linkedin = userData['linkedInUrl']?.toString() ?? "";

    final socialLinks = <Widget>[];

    if (fb.isNotEmpty) {
      socialLinks.add(
        IconButton(
          icon: const Icon(Icons.facebook, color: Colors.blue, size: 30),
          onPressed: () => _launchUrl(fb),
        ),
      );
    }

    if (ig.isNotEmpty) {
      socialLinks.add(
        IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.pink, size: 28),
          onPressed: () => _launchUrl(ig),
        ),
      );
    }

    if (linkedin.isNotEmpty) {
      socialLinks.add(
        IconButton(
          icon: const Icon(Icons.work, color: Color(0xFF0077B5), size: 28),
          onPressed: () => _launchUrl(linkedin),
        ),
      );
    }

    return socialLinks.isEmpty
        ? const SizedBox.shrink()
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socialLinks,
    );
  }

  Widget _buildAboutSection() {
    final about = _getSafeString(userData['about'], defaultValue: 'কোনো বায়োডাটা যোগ করা হয়নি।');
    return _section(
      'আমার সম্পর্কে',
      Text(
        about,
        style: const TextStyle(height: 1.5),
      ),
    );
  }

  void _showImageFullScreen() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3,
          child: Hero(  // ← এখানে Hero যোগ করুন (InteractiveViewer এর ভিতরে)
            tag: 'profile_${widget.uid}',  // ← একই tag ব্যবহার করুন
            child: CachedNetworkImage(  // ← এটাকে Hero এর child করুন
              imageUrl: _getSafeString(userData['image'], defaultValue: 'https://i.pravatar.cc/150'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String roleLabel) {
    return Column(
      children: [
        Text(
          _getSafeString(userData['name']).toUpperCase(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          roleLabel.toUpperCase(),
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double rating, int completed, int reviews) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('রেটিং', rating.toStringAsFixed(1), Icons.star_border),
        _statItem('সম্পন্ন', completed.toString(), Icons.check_circle_outline),
        _statItem('রিভিউ', reviews.toString(), Icons.rate_review_outlined),
      ],
    );
  }

  Widget _buildEngagementRow(int followersCount, int followingCount) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800.withOpacity(0.3), Colors.grey.shade900.withOpacity(0.3)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: widget.isOwner
          ? _buildOwnerStats(followersCount, followingCount, isDark)
          : _buildVisitorEngagement(followersCount, followingCount, isDark),
    );
  }

  Widget _buildOwnerStats(int followers, int following, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.trending_up,
            count: followers,
            label: 'ফলোয়ার',
            growth: followers > 100 ? '+12%' : null,
            isDark: isDark,
            onTap: _showFollowersList,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            icon: Icons.group,
            count: following,
            label: 'ফলো করছেন',
            isDark: isDark,
            onTap: _showFollowingList,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorEngagement(int followers, int following, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isFollowing
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                  : AppColors.brandMain,
              boxShadow: [
                if (!isFollowing)
                  BoxShadow(
                    color: AppColors.brandMain.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleFollow,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isFollowing
                            ? Icon(Icons.done_all, key: const ValueKey('following'), color: isDark ? Colors.white70 : Colors.grey.shade700, size: 20)
                            : Icon(Icons.person_add_alt_1, key: const ValueKey('follow'), color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isFollowing
                            ? Text('ফলো করছেন'.toUpperCase(), key: const ValueKey('following_text'), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14))
                            : Text('ফলো করুন'.toUpperCase(), key: const ValueKey('follow_text'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, size: 16, color: AppColors.brandMain),
                  const SizedBox(width: 6),
                  Text(
                    _formatNumber(followers),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('ফলোয়ার', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  void _showFollowersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingScreen(
          userId: widget.uid,
          listType: FollowListType.followers,
        ),
      ),
    );
  }

  void _showFollowingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingScreen(
          userId: widget.uid,
          listType: FollowListType.following,
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required int count,
    required String label,
    String? growth,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: AppColors.brandMain),
                  const SizedBox(width: 6),
                  Text(
                    _formatNumber(count),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  if (growth != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(growth, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Widget _buildWorkerInfo() {
    final expYears = userData['experienceYears'];
    final expLabel = (expYears == null)
        ? 'নতুন'
        : '${expYears.toString()} বছর';

    final priceLabel = _getSafeString(
      userData['priceText'],
      defaultValue: 'আলোচনা সাপেক্ষে',
    );

    final workStart = userData['workStart']?.toString();
    final workEnd = userData['workEnd']?.toString();
    final timeLabel = (workStart != null && workEnd != null && workStart.isNotEmpty && workEnd.isNotEmpty)
        ? '$workStart - $workEnd'
        : _getSafeString(userData['availability'], defaultValue: 'সময় সেট করা নেই');

    final cvUrl = userData['cvUrl']?.toString() ?? '';
    final portfolioUrls = (userData['portfolioUrls'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    return _section(
      'কাজের তথ্য',
      Column(
        children: [
          _infoTile(Icons.work, 'অভিজ্ঞতা', expLabel),
          _infoTile(Icons.payments, 'দর', priceLabel),
          _infoTile(Icons.access_time, 'কাজের সময়', timeLabel),


          if (cvUrl.isNotEmpty)
            _clickableInfoTile(
              icon: Icons.description_outlined,
              title: 'CV',
              value: 'View',
              onTap: () => _launchUrl(cvUrl),
            ),

          if (portfolioUrls.isNotEmpty)
            _clickableInfoTile(
              icon: Icons.photo_library_outlined,
              title: 'Portfolio',
              value: '${portfolioUrls.length} files',
              onTap: () => _showPortfolioBottomSheet(portfolioUrls),
            ),
        ],
      ),
    );
  }

  Widget _buildSupporterInfo() {
    return _section(
      'কোম্পানি তথ্য',
      Column(
        children: [
          _infoTile(Icons.business, 'কোম্পানি', _getSafeString(userData['companyName'], defaultValue: 'ব্যক্তিগত')),
          _infoTile(Icons.phone, 'যোগাযোগ', _getSafeString(userData['companyContact'], defaultValue: 'সেট করা নেই')),
        ],
      ),
    );
  }

  Widget _buildDynamicBottomSection(bool isWorker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isOwner)
          _buildOwnerSuggestions(isWorker)
        else
          _buildVisitorContent(isWorker),
      ],
    );
  }

  Widget _buildOwnerSuggestions(bool isWorker) {
    final target = isWorker ? 'supporter' : 'worker';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle('আপনার জন্য সুপারিশকৃত'),
        _buildSuggestionStream(target, 'স্পন্সরড পোস্ট', Colors.amber),
        const SizedBox(height: 20),
        _buildSuggestionStream(target, 'আপনার নিকটবর্তী', Colors.blue),
      ],
    );
  }

  Widget _buildVisitorContent(bool isWorker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle('ব্যবহারকারীর পোস্ট'),
        _buildOwnerPostsStream(),
        const SizedBox(height: 20),
        _sectionTitle(isWorker ? 'অনুরূপ কর্মী' : 'অনুরূপ সমর্থক'),
        _buildSimilarStream(isWorker),
      ],
    );
  }

  Widget _buildOwnerPostsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: widget.uid)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(child: Text('কোনো পোস্ট পাওয়া যায়নি')),
          );
        }

        final docs = snap.data!.docs;
        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            shrinkWrap: true, // ✅ ADD THIS
            physics: const ClampingScrollPhysics(), // ✅ optional but good
            itemBuilder: (context, index) {
              final d = docs[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: UniversalWorkerCard(
                  id: d.id,
                  name: d['title'] ?? 'No Title',
                  role: d['roleLabel'] ?? 'Worker',
                  imageUrl: userData['image'],
                  address: d['address'] ?? 'Address not set',
                  rating: "0",
                  completed: "0",
                  reviews: "0",
                  price: d['priceLabel'] ?? 'Negotiable',
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSimilarStream(bool isWorker) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userRole', isEqualTo: isWorker ? 'finder' : 'maker')
          .where('kyc_completed', isEqualTo: true)
          .limit(2)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(height: 100, child: Center(child: Text('কোনো ব্যবহারকারী পাওয়া যায়নি', style: TextStyle(color: Colors.grey[600]))));
        }

        final docs = snap.data!.docs.where((d) => d.id != widget.uid).toList();
        if (docs.isEmpty) {
          return SizedBox(height: 100, child: Center(child: Text('অনুরূপ ব্যবহারকারী পাওয়া যায়নি', style: TextStyle(color: Colors.grey[600]))));
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: UniversalWorkerCard(
                  id: d.id,
                  name: d['name'] ?? 'User',
                  role: d['userRole'] ?? 'worker',
                  imageUrl: d['image'],
                  address: d['location'] ?? 'Location not set',
                  rating: (d['rating'] ?? 0).toString(),
                  completed: "0",
                  reviews: "0",
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestionStream(String role, String tag, Color col) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('userRole', isEqualTo: role == 'worker' ? 'finder' : 'maker')
          .where('kyc_completed', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(height: 200, child: Center(child: Text('কোনো সুপারিশ নেই', style: TextStyle(color: Colors.grey[600]))));
        }

        final d = snap.data!.docs.first;
        return SizedBox(
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(tag, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: UniversalWorkerCard(
                  id: d.id,
                  name: d['name'] ?? 'User',
                  role: d['userRole'] ?? role,
                  imageUrl: d['image'],
                  address: d['location'] ?? 'Location not set',
                  rating: (d['rating'] ?? 0).toString(),
                  completed: "0",
                  reviews: "0",
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitorActionBar() {
    final paused = (userData['workPaused'] ?? false) == true;
    final bool isWorker = _isWorkerRole();
    final bool hasPhone = userData['phone']?.toString().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildVisitorActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              color: Colors.blue,
              onPressed: () => _openChat(isWorker ? "Worker" : "Supporter"),
            ),
            const SizedBox(width: 12),
            if (hasPhone && isWorker)
              _buildVisitorActionButton(
                icon: Icons.call_outlined,
                label: 'Call',
                color: Colors.green,
                onPressed: _makePhoneCall,
              )
            else if (!isWorker)
              _buildVisitorActionButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: Colors.orange,
                onPressed: _sendEmail,
              ),
            if ((hasPhone && isWorker) || !isWorker) const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brandMain, AppColors.brandMain.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: paused ? null : () => _handleHireOrRequest(isWorker),
                    borderRadius: BorderRadius.circular(15),
                    child: Center(
                      child: Text(
                        isWorker ? 'নিয়োগ করুন'.toUpperCase() : 'অনুরোধ পাঠান'.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: Colors.black),
          onPressed: onPressed,
          splashRadius: 20,
        ),
      ),
    );
  }

  Widget _buildVisitorMenuButton() {
    return PopupMenuButton<ProfileMenuOther>(
      onSelected: (value) {
        if (value == ProfileMenuOther.block) {
          BlockedUserService().blockUser(widget.uid, _getSafeString(userData['name'])).then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ব্যবহারকারী ব্লক করা হয়েছে')));
          });
        } else if (value == ProfileMenuOther.report) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
        }
      },
      icon: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.more_vert, color: Colors.black, size: 20),
      ),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      tooltip: 'Options',
      itemBuilder: (ctx) => [
        PopupMenuItem<ProfileMenuOther>(
          value: ProfileMenuOther.report,
          child: Row(children: [const Icon(Icons.report, size: 20), const SizedBox(width: 12), const Text('রিপোর্ট')]),
        ),
        PopupMenuItem<ProfileMenuOther>(
          value: ProfileMenuOther.block,
          child: Row(children: [const Icon(Icons.block, size: 20), const SizedBox(width: 12), const Text('ব্লক করুন')]),
        ),
      ],
    );
  }

  Widget _buildFloatingMenuButton(String subscriptionType) {
    return PopupMenuButton<ProfileMenuOwner>(
      onSelected: (value) => _handleOwnerMenu(value),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      tooltip: 'More Options',
      itemBuilder: (ctx) => _buildOwnerMenuItems(subscriptionType),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: IconButton(icon: const Icon(Icons.more_vert, size: 20, color: Colors.black), onPressed: null, splashRadius: 20),
      ),
    );
  }

  List<PopupMenuEntry<ProfileMenuOwner>> _buildOwnerMenuItems(String subscriptionType) {
    final bool isFreeUser = subscriptionType == 'free';

    return [
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.edit,
        child: Row(children: [const Icon(Icons.edit, size: 20, color: Colors.blue), const SizedBox(width: 12), const Expanded(child: Text('সম্পাদনা'))]),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.shareProfile,
        child: Row(children: [const Icon(Icons.share, size: 20, color: Colors.green), const SizedBox(width: 12), const Expanded(child: Text('প্রোফাইল শেয়ার করুন'))]),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.previewPublicCard,
        child: Row(children: [const Icon(Icons.preview, size: 20, color: Colors.purple), const SizedBox(width: 12), const Expanded(child: Text('পাবলিক কার্ড প্রিভিউ'))]),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.lockAccount,
        child: Row(
          children: [
            Icon(Icons.lock, size: 20, color: isFreeUser ? Colors.grey : Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text('অ্যাকাউন্ট লক করুন', style: TextStyle(color: isFreeUser ? Colors.grey : null, fontWeight: FontWeight.w600))),
            if (isFreeUser) const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
          ],
        ),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.theme,
        child: Row(
          children: [
            Icon(Icons.color_lens, size: 20, color: isFreeUser ? Colors.grey : Colors.purpleAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('থিম', style: TextStyle(color: isFreeUser ? Colors.grey : null, fontWeight: FontWeight.w600))),
            if (isFreeUser) const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
          ],
        ),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.hideProfile,
        child: Row(
          children: [
            Icon(Icons.visibility_off, size: 20, color: isFreeUser ? Colors.grey : Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('প্রোফাইল লুকান', style: TextStyle(color: isFreeUser ? Colors.grey : null, fontWeight: FontWeight.w600))),
            if (isFreeUser) const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
          ],
        ),
      ),
      PopupMenuItem<ProfileMenuOwner>(
        value: ProfileMenuOwner.pauseWork,
        child: Row(
          children: [
            Icon(Icons.pause_circle, size: 20, color: isFreeUser ? Colors.grey : Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('কাজ বিরতি', style: TextStyle(color: isFreeUser ? Colors.grey : null, fontWeight: FontWeight.w600))),
            if (isFreeUser) const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
          ],
        ),
      ),
    ];
  }

  void _handleOwnerMenu(ProfileMenuOwner value) {
    final subscriptionType = userData['subscription_type']?.toString() ?? 'free';
    final bool isFreeUser = subscriptionType == 'free';

    switch (value) {
      case ProfileMenuOwner.edit:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedProfileEditScreen(uid: widget.uid),
          ),
        );
        break;

      case ProfileMenuOwner.shareProfile:
        _shareProfile();
        break;

      case ProfileMenuOwner.previewPublicCard:
        _previewPublicCard();
        break;

      case ProfileMenuOwner.lockAccount:
      case ProfileMenuOwner.hideProfile:
      case ProfileMenuOwner.pauseWork:
        if (isFreeUser) {
          _showUpgradeToPremiumPopup();
        } else {
          _handlePremiumFeature(value);
        }
        break;

      case ProfileMenuOwner.theme:
        _showCardThemeBottomSheet();
        break;
    }
  }

  void _showPublicCardPreviewBottomSheet() {
    final bool isWorker = _isWorkerRole();
    final int xp = int.tryParse(userData['user_badge_points']?.toString() ?? '0') ?? 0;
    final badgeLevel = AchievementService.getBadgeLevelByPoints(xp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, color: AppColors.brandMain, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('পাবলিক প্রোফাইল প্রিভিউ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[300], height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.brandLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.brandMain, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'এটি অন্যরা কিভাবে আপনার প্রোফাইল দেখবে।\nআপনি এখন প্রিভিউ মোডে আছেন।',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          UniversalWorkerCard(
                            id: widget.uid,
                            name: _getSafeString(userData['name']),
                            role: isWorker ? "Worker" : "Supporter",
                            imageUrl: _getSafeString(userData['image'], defaultValue: 'https://i.pravatar.cc/150'),
                            address: _getSafeString(userData['location'], defaultValue: 'ঠিকানা সেট করা নেই'),
                            rating: (userData['rating'] ?? 0.0).toStringAsFixed(1),
                            completed: (userData['completedCount'] ?? 0).toString(),
                            reviews: (userData['reviewsCount'] ?? 0).toString(),
                            price: _getSafeString(userData['price'], defaultValue: 'আলোচনা সাপেক্ষে'),
                            time: 'Available Now',
                            isVerifiedWorker: userData['kyc_completed'] ?? false,
                            isTopRated: (userData['rating'] ?? 0.0) >= 4.8,
                            isTrusted: (userData['completedCount'] ?? 0) >= 50 && (userData['rating'] ?? 0.0) >= 4.5,
                            badgeLevel: badgeLevel,
                            followersCount: userData['followersCount'] ?? 0,
                            showActionButtons: true,
                            showStats: true,
                            showSaveButton: false,
                            showShareButton: true,
                            showOnlineStatus: false,
                            onViewProfileTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('আপনি ইতিমধ্যে আপনার প্রোফাইল দেখছেন')));
                            },
                            onChatTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নিজের সাথে চ্যাট করা যায় না')));
                            },
                            onShareTap: () {
                              Navigator.pop(context);
                              _shareProfile();
                            },
                            onSaveTap: null,
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 5,
                            borderRadius: BorderRadius.circular(20),
                            enableImageZoom: true,
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('প্রিভিউ অপশন:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildPreviewOptionButton(Icons.share, 'শেয়ার করুন', _shareProfile),
                                    _buildPreviewOptionButton(Icons.screenshot, 'স্ক্রিনশট নিন', _takeScreenshot),
                                    _buildPreviewOptionButton(Icons.edit, 'এডিট করুন', () {
                                      Navigator.pop(context);
                                      _handleOwnerMenu(ProfileMenuOwner.edit);
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewOptionButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandLight.withOpacity(0.1),
        foregroundColor: AppColors.brandMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Future<void> _takeScreenshot() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('স্ক্রিনশট নেওয়া হচ্ছে...')));
  }

  void _showCardThemeBottomSheet() async {
    try {
      final subscriptionType = userData?['subscription_type']?.toString() ?? 'free';
      final bool isProUser = subscriptionType != 'free';

      // ✅ CardThemeService ব্যবহার করুন
      final currentColorIndex = await CardThemeService.getCardThemeIndex(widget.uid);

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
              setState(() {
                // ✅ _cardThemeIndex আপডেট করুন
                _cardThemeIndex = index;
              });
              // ✅ CardThemeService ব্যবহার করুন
              CardThemeService.setCardThemeIndex(widget.uid, index);

              // Optional: Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('কার্ড থিম পরিবর্তন করা হয়েছে'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error showing card theme bottom sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('থিম পরিবর্তন করতে সমস্যা হয়েছে'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  Widget _buildThemeColorOption({
    required BuildContext context,
    required int index,
    required bool isSelected,
    required bool isProUser,
    required VoidCallback onTap,
  }) {
    final colors = _themeGradients[index];

    return GestureDetector(
      onTap: isProUser ? onTap : _showUpgradeToPremiumPopup,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.brandMain : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.brandMain.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: !isProUser
                    ? Icon(Icons.lock_outline, color: Colors.white, size: 20)
                    : null,
              ),
              if (isSelected && isProUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.brandMain,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _themeNames[index],
            style: TextStyle(
              fontSize: 11,
              color: isProUser ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          // Add a small indicator for current theme
          if (isSelected && isProUser)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'বর্তমান',
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.brandMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUpgradeToPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('Upgrade to Premium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPremiumFeatureItem('Lock Account (প্রোফাইল লক)'),
            _buildPremiumFeatureItem('Custom Theme (থিম পরিবর্তন)'),
            _buildPremiumFeatureItem('Hide Profile (প্রোফাইল লুকানো)'),
            _buildPremiumFeatureItem('Pause Work (কাজ বন্ধ রাখা)'),
            const SizedBox(height: 15),
            const Text('Unlock all premium features!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(feature, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _handlePremiumFeature(ProfileMenuOwner value) async {
    try {
      switch (value) {
        case ProfileMenuOwner.lockAccount: {
          final current = (userData['accountLocked'] ?? false) == true;
          await _setAccountLocked(!current);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(!current ? 'Account locked' : 'Account unlocked')),
          );
          break;
        }
        case ProfileMenuOwner.hideProfile: {
          final current = (userData['profileHidden'] ?? false) == true;
          await _setProfileHidden(!current);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(!current ? 'Profile hidden' : 'Profile visible')),
          );
          break;
        }
        case ProfileMenuOwner.pauseWork: {
          final current = (userData['workPaused'] ?? false) == true;
          await _setWorkPaused(!current);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(!current ? 'Work paused' : 'Work resumed')),
          );
          break;
        }

      // non-premium cases (keep exhaustive)
        case ProfileMenuOwner.edit:
        case ProfileMenuOwner.shareProfile:
        case ProfileMenuOwner.previewPublicCard:
        case ProfileMenuOwner.theme:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showUpgradeToBusinessPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Upgrade to Business', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildBusinessFeatureItem('Manage multiple workers in one account.'),
            _buildBusinessFeatureItem('Assign jobs to specific team members.'),
            _buildBusinessFeatureItem('Team dashboard (jobs & earnings).'),
            _buildBusinessFeatureItem('Custom reporting & analytics.'),
            _buildBusinessFeatureItem('Highest support priority.'),
            const SizedBox(height: 10),
            const Text('Unlock team management and more!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(feature, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _previewPublicCard() {
    _showPublicCardPreviewBottomSheet();
  }

  bool get _isPremiumUser {
    final subscription = userData['subscription_type']?.toString();
    return subscription == 'premium' || subscription == 'business';
  }

  bool get _isBusinessUser {
    final subscription = userData['subscription_type']?.toString();
    return subscription == 'business';
  }

  // ===== HELPER METHODS =====

  String _getSafeString(dynamic value, {String defaultValue = 'N/A'}) {
    if (value == null) return defaultValue;
    if (value is String && value.isEmpty) return defaultValue;
    return value.toString();
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('লিংক খোলা যায়নি: $e')));
    }
  }

  Future<void> _shareProfile() async {
    try {
      final userName = _getSafeString(userData['name'], defaultValue: 'FindUs User');

      // ✅ যদি তোমার real deep link/domain থাকে এখানে দাও
      // নাহলে fallback text share হবে
      final profileLink = 'https://yourapp.com/profile/${widget.uid}';

      final message = 'FindUs Profile: $userName\n$profileLink';

      // Optional: share position from widget for better UX (works on mobile)
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.share(
        message,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('শেয়ার করতে সমস্যা হয়েছে: $e')),
      );
    }
  }

  bool _isWorkerRole() {
    final role = (userData['userRole'] ?? 'finder').toString().toLowerCase();
    return role == 'finder';
  }

  void _openChat(String roleLabel) async {
    final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: widget.uid);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: cid,
            userName: _getSafeString(userData['name']),
            userRole: roleLabel,
            userImage: _getSafeString(userData['image']),
          ),
        ),
      );
    }
  }

  void _makePhoneCall() async {
    final phone = userData['phone']?.toString();
    if (phone != null && phone.isNotEmpty) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone call not supported')));
      }
    }
  }

  void _sendEmail() async {
    final email = userData['email']?.toString();
    if (email != null && email.isNotEmpty) {
      final url = 'mailto:$email';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not supported')));
      }
    }
  }

  void _handleHireOrRequest(bool isWorker) {
    if (isWorker) {
      _showHireOptions();
    } else {
      _showRequestOptions();
    }
  }

  void _showHireOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hire ${_getSafeString(userData['name'])}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.blue),
                title: const Text('Send Job Proposal'),
                subtitle: const Text('Send a detailed job proposal'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: Colors.green),
                title: const Text('Schedule Interview'),
                subtitle: const Text('Arrange a meeting or interview'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_outlined, color: Colors.orange),
                title: const Text('Make an Offer'),
                subtitle: const Text('Send a formal job offer'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRequestOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send Request to ${_getSafeString(userData['name'])}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.business_outlined, color: Colors.purple),
                title: const Text('Partnership Request'),
                subtitle: const Text('Request for business partnership'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.handshake_outlined, color: Colors.teal),
                title: const Text('Collaboration Request'),
                subtitle: const Text('Request for collaboration on projects'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined, color: Colors.indigo),
                title: const Text('General Inquiry'),
                subtitle: const Text('Send a general message or inquiry'),
                onTap: () {
                  Navigator.pop(context);
                  _openChat('Supporter');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String label, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.0, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20.0, color: AppColors.brandMain),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _section(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppColors.brandMain),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 25, right: 16, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('প্রোফাইল')),
        body: const Center(child: Text('ব্লক করা ব্যবহারকারী')),
      );
    }

    final subscriptionType = userData['subscription_type']?.toString() ?? 'free';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: (!widget.isOwner)
          ? SafeArea(top: false, child: _buildVisitorActionBar())
          : null,
      body: Builder(
        // ✅ Builder দিলে এখানে যে context পাওয়া যায় সেটা FloatingScaffold-এর উপরের
        // route context হবে, তাই canPop reliable হবে।
        builder: (ctx) {
          final bool shouldShowBack =
              widget.showBack ?? Navigator.of(ctx).canPop();

          return FloatingScaffold(
            showBack: shouldShowBack, // ✅ FIX
            title: 'Profile',
            backgroundColor: AppColors.brandLight,
            titleColor: AppColors.brandDark,
            iconColor: AppColors.brandDark,
            actions: widget.isOwner
                ? [
              _buildFloatingActionButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
              ),
              _buildFloatingActionButton(
                icon: Icons.groups_outlined,
                tooltip: 'Team Management',
                onPressed: () {
                  if (_isBusinessUser) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamManagementScreen(uid: widget.uid),
                      ),
                    );
                  } else {
                    _showUpgradeToBusinessPopup();
                  }
                },
              ),
              _buildFloatingActionButton(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _buildFloatingMenuButton(subscriptionType),
            ]
                : [
              _buildVisitorMenuButton(),
            ],
            scrollable: false,
            bodyPadding: EdgeInsets.zero,
            body: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: isLoading ? _buildShimmerLoading() : _buildBody(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PortfolioViewer({
    required this.urls,
    this.initialIndex = 0,
  });

  @override
  State<_PortfolioViewer> createState() => _PortfolioViewerState();
}

class _PortfolioViewerState extends State<_PortfolioViewer> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1}/${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final url = widget.urls[i];

          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (c, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (c, _, __) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
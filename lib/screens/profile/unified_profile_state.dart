// lib/screens/profile/unified_profile_state.dart

import 'dart:async';
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
import 'package:findus_app/screens/profile/unified_profile_screen.dart'; // Parent screen import
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/team/team_management_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import '../explore/notifications_page.dart';
import 'card_theme_bottom_sheet.dart';
import 'followers_following_screen.dart';

// Enums
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

  final List<List<Color>> _themeGradients = const [
    [Color(0xFFB2EBF2), Color(0xFFFFFFFF)],
    [Color(0xFFFFCC80), Color(0xFFFFFFFF)],
    [Color(0xFFC5CAE9), Color(0xFFFFFFFF)],
    [Color(0xFFF8BBD0), Color(0xFFFFFFFF)],
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
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;

      final data = snap.data() ?? <String, dynamic>{};

      // Card Theme Index from Firestore or Default
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

  void _listenToFollowCounts() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();

    _followersCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('followers')
        .snapshots()
        .listen((q) {
      if (mounted) setState(() => _followersCountLive = q.size);
    });

    _followingCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('following')
        .snapshots()
        .listen((q) {
      if (mounted) setState(() => _followingCountLive = q.size);
    });
  }

  void _listenToNotifications() {
    _notifSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notifSub = FirebaseFirestore.instance
        .collection('notifications') // ✅ কালেকশনের নাম 'notificationId' থেকে 'notifications' করা হয়েছে
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((q) {
      if (mounted) setState(() => _unreadNotifCount = q.size);
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
      debugPrint('Following check error: $e');
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    // Reload logic is mainly handled by stream listener, but we can force fetch once
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (mounted && snap.exists) {
        // setState handled by stream
      }
    } catch (_) {}
  }

  void _showBlockedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Blocked User'),
          content: const Text('You have blocked this user. Cannot view profile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) => Navigator.pop(context));
    });
  }

  // --- Theme Management ---

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading themes')),
      );
    }
  }

  // --- Premium Actions ---

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

  @override
  Widget build(BuildContext context) {
    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User Blocked')),
      );
    }

    final subscriptionType = userData['subscription_type']?.toString() ?? 'free';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
     ? const Color(0xFF121212)
     : AppColors.bgBlue,
      bottomNavigationBar: (!widget.isOwner)
          ? SafeArea(top: false, child: _buildVisitorActionBar())
          : null,
      body: Builder(
        builder: (ctx) {
          final bool shouldShowBack = widget.showBack ?? Navigator.of(ctx).canPop();

          return FloatingScaffold(
            showBack: shouldShowBack,
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
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
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
                        builder: (_) => TeamManagementScreen(userId: widget.uid), // ✅ সঠিক নাম
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
                : [_buildVisitorMenuButton()],
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
                  ? 'This profile is locked.'
                  : 'This profile is currently hidden.',
              textAlign: TextAlign.center,
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

  // --- Header Card ---

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
        top: MediaQuery.of(context).padding.top + 16,
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildStatusPills(double rating, int completed) {
    final pills = <Widget>[];

    if (userData['kyc_completed'] == true) {
      pills.add(_pill('Verified', Colors.blue, Icons.verified));
    }
    if (rating >= 4.9) {
      pills.add(_pill('Top Rated', Colors.orange, Icons.star));
    }
    if (completed >= 50 && rating >= 4.5) {
      pills.add(_pill('Trusted', Colors.green, Icons.shield));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pills,
    );
  }

  Widget _buildProfileImageWithOnline() {
    final imageUrl = _getSafeString(userData['image'], defaultValue: '');
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
                      child: Lottie.asset('assets/animations/profile_avatar.json', fit: BoxFit.contain),
                    ),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Lottie.asset('assets/animations/profile_avatar.json', fit: BoxFit.contain),
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
          child: Hero(
            tag: 'profile_${widget.uid}',
            child: CachedNetworkImage(
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          roleLabel.toUpperCase(),
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double rating, int completed, int reviews) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('Rating', rating.toStringAsFixed(1), Icons.star_border),
        _statItem('Completed', completed.toString(), Icons.check_circle_outline),
        _statItem('Reviews', reviews.toString(), Icons.rate_review_outlined),
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
            label: 'Followers',
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
            label: 'Following',
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
                            : const Icon(Icons.person_add_alt_1, key: ValueKey('follow'), color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isFollowing
                            ? Text('Following'.toUpperCase(), key: const ValueKey('following_text'), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14))
                            : Text('Follow'.toUpperCase(), key: const ValueKey('follow_text'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.brandMain),
                  const SizedBox(width: 6),
                  Text(
                    _formatNumber(followers),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Followers', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Info Sections ---

  Widget _buildWorkerInfo() {
    final expYears = userData['experienceYears'];
    final expLabel = (expYears == null) ? 'New' : '$expYears Years';
    final priceLabel = _getSafeString(userData['priceText'], defaultValue: 'Negotiable');
    final timeLabel = _getSafeString(userData['availability'], defaultValue: 'Not Set');
    final cvUrl = userData['cvUrl']?.toString() ?? '';
    final portfolioUrls = (userData['portfolioUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return _section(
      'Work Information',
      Column(
        children: [
          _infoTile(Icons.work, 'Experience', expLabel),
          _infoTile(Icons.payments, 'Rate', priceLabel),
          _infoTile(Icons.access_time, 'Hours', timeLabel),
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
              onTap: () => _openPortfolioViewer(portfolioUrls),
            ),
        ],
      ),
    );
  }

  Widget _buildSupporterInfo() {
    return _section(
      'Company Information',
      Column(
        children: [
          _infoTile(Icons.business, 'Company', _getSafeString(userData['companyName'], defaultValue: 'Individual')),
          _infoTile(Icons.phone, 'Contact', _getSafeString(userData['companyContact'], defaultValue: 'Not Set')),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final about = _getSafeString(userData['about'], defaultValue: 'No bio added yet.');
    return _section(
      'About Me',
      Text(about, style: const TextStyle(height: 1.5)),
    );
  }

  // --- Dynamic Content ---

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
        _sectionTitle('Suggested for You'),
        _buildSuggestionStream(target, 'Sponsored', Colors.amber),
        const SizedBox(height: 20),
        _buildSuggestionStream(target, 'Nearby', Colors.blue),
      ],
    );
  }

  Widget _buildVisitorContent(bool isWorker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionTitle('User Posts'),
        _buildOwnerPostsStream(),
        const SizedBox(height: 20),
        _sectionTitle(isWorker ? 'Similar Workers' : 'Similar Supporters'),
        _buildSimilarStream(isWorker),
      ],
    );
  }

  // --- Streams ---

  Widget _buildOwnerPostsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: widget.uid)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox(height: 100, child: Center(child: Text('No posts found')));
        }
        final docs = snap.data!.docs;
        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
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
                  address: d['address'] ?? 'Not set',
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
          return SizedBox(height: 100, child: Center(child: Text('No users found', style: TextStyle(color: Colors.grey[600]))));
        }
        final docs = snap.data!.docs.where((d) => d.id != widget.uid).toList();
        if (docs.isEmpty) return const SizedBox.shrink();

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
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SizedBox(height: 100, child: Center(child: Text('No suggestions', style: TextStyle(color: Colors.grey[600]))));
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

  // --- Visitor Actions ---

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
                        isWorker ? 'HIRE NOW' : 'SEND REQUEST',
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

  // --- Helpers ---

  void _openPortfolioViewer(List<String> urls, {int initialIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PortfolioViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
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

  Widget _buildSocialLinks() {
    final fb = userData['facebookUrl']?.toString() ?? "";
    final ig = userData['instagramUrl']?.toString() ?? "";
    final linkedin = userData['linkedInUrl']?.toString() ?? "";

    final socialLinks = <Widget>[];

    if (fb.isNotEmpty) {
      socialLinks.add(IconButton(icon: const Icon(Icons.facebook, color: Colors.blue, size: 30), onPressed: () => _launchUrl(fb)));
    }
    if (ig.isNotEmpty) {
      socialLinks.add(IconButton(icon: const Icon(Icons.camera_alt, color: Colors.pink, size: 28), onPressed: () => _launchUrl(ig)));
    }
    if (linkedin.isNotEmpty) {
      socialLinks.add(IconButton(icon: const Icon(Icons.work, color: Color(0xFF0077B5), size: 28), onPressed: () => _launchUrl(linkedin)));
    }

    return socialLinks.isEmpty ? const SizedBox.shrink() : Row(mainAxisAlignment: MainAxisAlignment.center, children: socialLinks);
  }

  bool _isWorkerRole() {
    final role = (userData['userRole'] ?? 'finder').toString().toLowerCase();
    return role == 'finder';
  }

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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link')));
    }
  }

  // --- Menus & Dialogs ---

  Widget _buildFloatingActionButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: IconButton(icon: Icon(icon, size: 20, color: Colors.black), onPressed: onPressed, splashRadius: 20),
      ),
    );
  }

  Widget _buildFloatingMenuButton(String subscriptionType) {
    return PopupMenuButton<ProfileMenuOwner>(
      onSelected: _handleOwnerMenu,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (ctx) => _buildOwnerMenuItems(subscriptionType),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.more_vert, size: 20, color: Colors.black)),
      ),
    );
  }

  List<PopupMenuEntry<ProfileMenuOwner>> _buildOwnerMenuItems(String subscriptionType) {
    final bool isFreeUser = subscriptionType == 'free';

    // হেল্পার উইজেট (আইকন + টেক্সট)
    Widget _menuRow(IconData icon, String text, Color color, {bool showLock = false}) {
      return Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (showLock) const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      );
    }

    return [
      PopupMenuItem(
        value: ProfileMenuOwner.edit,
        child: _menuRow(Icons.edit_rounded, 'Edit Profile', Colors.blue),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.shareProfile,
        child: _menuRow(Icons.share_rounded, 'Share Profile', Colors.green),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.previewPublicCard,
        child: _menuRow(Icons.visibility_rounded, 'Preview Card', Colors.purple),
      ),
      const PopupMenuDivider(), // সেপারেটর
      PopupMenuItem(
        value: ProfileMenuOwner.lockAccount,
        child: _menuRow(
            Icons.privacy_tip_rounded,
            'Lock Account',
            Colors.redAccent,
            showLock: isFreeUser
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.theme,
        child: _menuRow(
            Icons.palette_rounded,
            'Theme',
            Colors.orange,
            showLock: isFreeUser
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.hideProfile,
        child: _menuRow(
            Icons.visibility_off_rounded,
            'Hide Profile',
            Colors.grey,
            showLock: isFreeUser
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.pauseWork,
        child: _menuRow(
            Icons.pause_circle_filled_rounded,
            'Pause Work',
            Colors.amber.shade800,
            showLock: isFreeUser
        ),
      ),
    ];
  }

  void _handleOwnerMenu(ProfileMenuOwner value) {
    final subscriptionType = userData['subscription_type']?.toString() ?? 'free';
    final bool isFreeUser = subscriptionType == 'free';

    switch (value) {
      case ProfileMenuOwner.edit:
        Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileEditScreen(uid: widget.uid)));
        break;
      case ProfileMenuOwner.shareProfile:
        _shareProfile();
        break;
      case ProfileMenuOwner.previewPublicCard:
        _showPublicCardPreviewBottomSheet();
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

  void _handlePremiumFeature(ProfileMenuOwner value) async {
    // Implement toggle logic here
    if (value == ProfileMenuOwner.lockAccount) {
      _setAccountLocked(!(userData['accountLocked'] ?? false));
    } else if (value == ProfileMenuOwner.hideProfile) {
      _setProfileHidden(!(userData['profileHidden'] ?? false));
    } else if (value == ProfileMenuOwner.pauseWork) {
      _setWorkPaused(!(userData['workPaused'] ?? false));
    }
  }

  Future<void> _shareProfile() async {
    final userName = _getSafeString(userData['name'], defaultValue: 'FindUs User');
    final profileLink = 'https://findus.app/profile/${widget.uid}';
    await Share.share('Check out $userName on FindUs!\n$profileLink');
  }

  void _showUpgradeToPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text('Unlock exclusive features like Locking Account, Custom Themes, and more!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeToBusinessPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Business'),
        content: const Text('Unlock Team Management and other business features!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorMenuButton() {
    return PopupMenuButton<ProfileMenuOther>(
      onSelected: (value) {
        if (value == ProfileMenuOther.block) {
          BlockedUserService().blockUser(widget.uid, _getSafeString(userData['name'])).then((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Blocked')));
          });
        } else if (value == ProfileMenuOther.report) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
        }
      },
      icon: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.more_vert, color: Colors.black, size: 20),
      ),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: ProfileMenuOther.report, child: Text('Report')),
        const PopupMenuItem(value: ProfileMenuOther.block, child: Text('Block')),
      ],
    );
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
      _launchUrl('tel:$phone');
    }
  }

  void _sendEmail() async {
    final email = userData['email']?.toString();
    if (email != null && email.isNotEmpty) {
      _launchUrl('mailto:$email');
    }
  }

  void _handleHireOrRequest(bool isWorker) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isWorker ? 'Hire Options' : 'Request Options', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Proposal'),
              onTap: () {
                Navigator.pop(ctx);
                _openChat(isWorker ? 'Worker' : 'Supporter');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Common Widgets ---

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

  Widget _clickableInfoTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppColors.brandMain),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 25, right: 16, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
    );
  }

  // Stats Card for Followers/Following
  Widget _statCard({required IconData icon, required int count, required String label, String? growth, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandMain),
          Text(_formatNumber(count), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  bool get _isBusinessUser {
    final subscription = userData['subscription_type']?.toString();
    return subscription == 'business';
  }

  // --- Shimmer Loading ---

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        shrinkWrap: true,
        children: [
          Container(height: 200, margin: const EdgeInsets.all(16), color: Colors.white),
          Container(height: 100, margin: const EdgeInsets.all(16), color: Colors.white),
          Container(height: 100, margin: const EdgeInsets.all(16), color: Colors.white),
        ],
      ),
    );
  }

  // --- Public Card Preview ---

  void _showPublicCardPreviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: UniversalWorkerCard(
            id: widget.uid,
            name: _getSafeString(userData['name']),
            role: _isWorkerRole() ? "Worker" : "Supporter",
            imageUrl: userData['image'],
            address: _getSafeString(userData['location']),
            rating: "0",
            completed: "0",
            reviews: "0",
          ),
        ),
      ),
    );
  }
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
        itemBuilder: (ctx, i) => Center(
          child: CachedNetworkImage(imageUrl: widget.urls[i]),
        ),
      ),
    );
  }
}
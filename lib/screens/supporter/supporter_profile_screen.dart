import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/constants/badge_theme.dart';
import 'package:findus_app/constants/status_theme.dart';

import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/supporter/supporter_profile_edit_screen.dart';
import 'package:findus_app/screens/team/team_management_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/conversation_storage.dart';
import 'package:findus_app/services/firestore_chat_service.dart';

import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/rating_history_screen.dart';

import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/profile_lock_service.dart';
import 'package:findus_app/services/profile_color_service.dart';

import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';

enum _SupporterMenuOwner { lockAccount, theme, hideProfile, pauseWork }
enum _SupporterMenuOther { report, block }

class SupporterProfileScreen extends StatefulWidget {
  final bool isOwner;
  final String name;
  final String role;
  final String location;
  final String phone;
  final String? email;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? linkedInUrl;
  final String completedText;
  final String ratingText;
  final String reviewsText;
  final String subscriptionPlan;
  final List<Worker>? suggestions;

  const SupporterProfileScreen({
    super.key,
    required this.isOwner,
    required this.name,
    required this.role,
    required this.location,
    required this.phone,
    this.email,
    this.facebookUrl,
    this.instagramUrl,
    this.linkedInUrl,
    this.completedText = "0",
    this.ratingText = "0.0",
    this.reviewsText = "0",
    this.subscriptionPlan = 'free',
    this.suggestions,
  });

  @override
  State<SupporterProfileScreen> createState() => _SupporterProfileScreenState();
}

class _SupporterProfileScreenState extends State<SupporterProfileScreen> {
  String? _profileImageUrl;
  String _displayName = "";
  String _displayLocation = "";
  String _companyName = "";
  int _profileColorIndex = 0;
  bool _isLocked = false;
  bool _isHiddenFromExplore = false;
  bool _isPausedWork = false;
  bool _isViewerWorker = false;

  // Option B follow state
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  String? _viewerUid;
  late final String _profileUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _followingSub;

  String _experience = "Posted many jobs";
  String _languages = "Bangla, English";
  String _availability = "Flexible";

  String get _supporterKey => widget.phone.trim().isNotEmpty ? widget.phone.trim() : widget.name;

  @override
  void initState() {
    super.initState();
    _displayName = widget.name;
    _displayLocation = widget.location;

    // Owner হলে নিজের uid, না হলে _supporterKey (fallback)
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    _profileUid = widget.isOwner ? (currentUid ?? _supporterKey) : _supporterKey;

    _loadAllData();

    // Follow state init (Option B)
    _viewerUid = FirebaseAuth.instance.currentUser?.uid;
    _attachFollowingListener();
    _loadFollowCounts();
  }

  @override
  void dispose() {
    _followingSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _supporterKey;

    final colorIdx = await ProfileColorService.getColorIndex(key);
    final locked = await ProfileLockService.isLocked(key);
    final role = prefs.getString('user_role');

    if (mounted) {
      setState(() {
        _profileColorIndex = colorIdx;
        _isLocked = locked;
        _isViewerWorker = role == 'finder';
        _profileImageUrl = prefs.getString('user_profile_image');
        _displayName = prefs.getString('user_name') ?? widget.name;
        _displayLocation = prefs.getString('user_location') ?? widget.location;
        _companyName = prefs.getString('company_name') ?? "";
        _experience = prefs.getString('supporter_experience') ?? _experience;
        _languages = prefs.getString('supporter_languages') ?? _languages;
        _availability = prefs.getString('supporter_availability') ?? _availability;
        _isHiddenFromExplore = prefs.getBool('supporter_hide_from_explore') ?? false;
        _isPausedWork = prefs.getBool('supporter_pause_work') ?? false;
      });
    }
  }

  // Option B: aggregate count() দিয়ে followers/following লোড
  Future<void> _loadFollowCounts() async {
    try {
      final followersAgg = await FirebaseFirestore.instance
          .collection('users')
          .doc(_profileUid)
          .collection('followers')
          .count()
          .get();

      final int followers = followersAgg.count ?? 0;

      int following = 0;
      if (_viewerUid != null) {
        final followingAgg = await FirebaseFirestore.instance
            .collection('users')
            .doc(_viewerUid)
            .collection('following_workers')
            .count()
            .get();
        following = followingAgg.count ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _followersCount = followers;
        _followingCount = following;
      });
    } catch (_) {}
  }

  // isFollowing রিয়েলটাইম
  Future<void> _attachFollowingListener() async {
    if (_viewerUid == null || widget.isOwner || _profileUid.isEmpty) return;

    _followingSub?.cancel();
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_viewerUid)
        .collection('following_workers')
        .doc(_profileUid);

    _followingSub = ref.snapshots().listen((snap) {
      if (!mounted) return;
      setState(() => _isFollowing = snap.exists);
    });
  }

  // Follow / Unfollow (Option B) – দুই সাবকলেকশন
  Future<void> _toggleFollow() async {
    if (_viewerUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("লগইন প্রয়োজন।")));
      return;
    }
    if (_profileUid.isEmpty || _viewerUid == _profileUid) return;

    final db = FirebaseFirestore.instance;
    final viewerRef = db.collection('users').doc(_viewerUid);
    final profileRef = db.collection('users').doc(_profileUid);

    final followingRef = viewerRef.collection('following_workers').doc(_profileUid);
    final followerRef = profileRef.collection('followers').doc(_viewerUid);

    final next = !_isFollowing;

    // Optimistic UI
    setState(() {
      _isFollowing = next;
      _followersCount = next ? _followersCount + 1 : (_followersCount > 0 ? _followersCount - 1 : 0);
    });

    try {
      final batch = db.batch();
      if (next) {
        batch.set(followingRef, {
          'workerId': _profileUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.set(followerRef, {
          'viewerId': _viewerUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(followingRef);
        batch.delete(followerRef);
      }
      await batch.commit();

      await _loadFollowCounts(); // সার্ভার ট্রুথ
    } catch (e) {
      if (!mounted) return;
      // revert
      setState(() {
        _isFollowing = !next;
        _followersCount = next ? (_followersCount > 0 ? _followersCount - 1 : 0) : _followersCount + 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("অ্যাকশন ব্যর্থ: $e")));
    }
  }

  // এটি আপনার স্ক্রিন ক্লাসের ভেতরে থাকবে
  Future<void> _handleChatOpen(BuildContext context, {
    required String otherUserId,
    required String name,
    required String image,
    required String role
  }) async {

    // ১. স্ক্রিনের ওপর লোডিং দেখানো
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
    );

    try {
      // ২. আইডি নিয়ে আসা
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUserId);

      // ৩. লোডিং বন্ধ করা
      if (!mounted) return;
      Navigator.pop(context);

      // ৪. চ্যাট স্ক্রিনে পাঠানো
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(
          conversationId: convId,
          userName: name,
          userImage: image,
          userRole: role,
        )),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // লোডিং বন্ধ
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _onOwnerMenuSelected(_SupporterMenuOwner action) async {
    final prefs = await SharedPreferences.getInstance();
    switch (action) {
      case _SupporterMenuOwner.lockAccount:
        final locked = await ProfileLockService.toggleLock(_supporterKey);
        setState(() => _isLocked = locked);
        break;
      case _SupporterMenuOwner.theme:
        final selected = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => ThemeChooserBottomSheet(currentIndex: _profileColorIndex),
        );
        if (selected != null) {
          await ProfileColorService.setColorIndex(_supporterKey, selected);
          setState(() => _profileColorIndex = selected);
        }
        break;
      case _SupporterMenuOwner.hideProfile:
        final val = !_isHiddenFromExplore;
        await prefs.setBool('supporter_hide_from_explore', val);
        setState(() => _isHiddenFromExplore = val);
        break;
      case _SupporterMenuOwner.pauseWork:
        final val = !_isPausedWork;
        await prefs.setBool('supporter_pause_work', val);
        setState(() => _isPausedWork = val);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isOwner ? "My Profile" : _displayName, style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        actions: [
          if (widget.isOwner) ...[
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupporterProfileEditScreen()));
                if (result == true) _loadAllData();
              },
            ),
            PopupMenuButton<_SupporterMenuOwner>(
              onSelected: _onOwnerMenuSelected,
              itemBuilder: (ctx) => [
                PopupMenuItem(value: _SupporterMenuOwner.lockAccount, child: Text(_isLocked ? "Unlock account" : "Lock account")),
                const PopupMenuItem(value: _SupporterMenuOwner.theme, child: Text("Theme option")),
                PopupMenuItem(value: _SupporterMenuOwner.hideProfile, child: Text(_isHiddenFromExplore ? "Show in Explore" : "Hide from Explore")),
                PopupMenuItem(value: _SupporterMenuOwner.pauseWork, child: Text(_isPausedWork ? "Resume Work" : "Pause Work")),
              ],
            ),
          ] else
            PopupMenuButton<_SupporterMenuOther>(
              onSelected: (a) async {
                if (a == _SupporterMenuOther.report) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                if (a == _SupporterMenuOther.block) {
                  await BlockedUserService().blockUser(_supporterKey, _displayName);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_displayName blocked.')));
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: _SupporterMenuOther.report, child: Text("Report")),
                PopupMenuItem(value: _SupporterMenuOther.block, child: Text("Block")),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 10),
                    _buildSection(title: "About Me", child: const Text("Responsible job maker with clear communication and respect for workers. Ensures fair payment.", style: TextStyle(color: Colors.black87, height: 1.5))),
                    _buildSection(title: "Portfolio / Previous Workers Hired", child: SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [_buildPortfolioImage("https://images.unsplash.com/photo-1581244277943-fe4a9c777189?q=80&w=300"), _buildPortfolioImage("https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300")]))),
                    _buildSection(title: "Details", child: Column(children: [_infoRow(Icons.work_history, "Experience", _experience), _infoRow(Icons.translate, "Languages", _languages), _infoRow(Icons.schedule, "Availability", _availability), if (_companyName.isNotEmpty) _infoRow(Icons.business, "Company", _companyName)])),
                    _buildSectionWithAction(title: "Recent Reviews", onActionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RatingHistoryScreen())), child: Column(children: const [_ReviewItem(reviewer: "Worker 1", comment: "Paid on time.", stars: 5), Divider(), _ReviewItem(reviewer: "Worker 2", comment: "Friendly.", stars: 4)])),
                    // ... অন্য সব ইমপোর্ট ঠিক থাকবে ...

// সাজেশন সেকশনের কোডটুকু এভাবে পরিবর্তন করা হয়েছে:
                    if (widget.suggestions != null && widget.suggestions!.isNotEmpty)
                      _buildSection(
                        title: _isViewerWorker ? "Suggested Supporters Near You" : "Suggested Workers Near You",
                        child: Column(
                          children: widget.suggestions!.map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: UniversalWorkerCard(
                              name: w.name,
                              role: w.role,
                              imageUrl: w.image,
                              address: w.location,
                              rating: w.rating.toStringAsFixed(1),
                              completed: "0", // ডামি বা রিয়েল ডাটা
                              reviews: "0",   // ডামি বা রিয়েল ডাটা
                              price: w.price,
                              time: "Available Now",
                              phoneNumber: null,
                              isVerifiedWorker: w.isVerified,
                              isTopRated: w.rating >= 4.8,
                              isTrusted: w.rating >= 4.2,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: w, isOwner: false)));
                              },
                              onChatTap: () async {
                                final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: w.id);
                                if (!mounted) return;
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId, userName: w.name, userRole: w.role, userImage: w.image)));
                              },
                              // আপনার নতুন প্যারামিটারগুলো এখানে অ্যাড করা হয়েছে
                              badgeLevel: null,
                              facebookUrl: null,
                              emailAddress: null,
                            ),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final colors = [
      [const Color(0xFFB2EBF2), const Color(0xFFE0F7FA)],
      [const Color(0xFFFFCC80), const Color(0xFFFFE0B2)],
      [const Color(0xFFC5CAE9), const Color(0xFFE8EAF6)],
      [const Color(0xFFF8BBD0), const Color(0xFFFCE4EC)],
    ][_profileColorIndex.clamp(0, 3)];

    final ratingVal = double.tryParse(widget.ratingText) ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _badgeItem("BRONZE", AppBadgeTheme.bronze, ratingVal >= 3.5),
            _badgeItem("SILVER", AppBadgeTheme.silver, ratingVal >= 4.0),
            _badgeItem("GOLD", AppBadgeTheme.gold, ratingVal >= 4.5),
            _badgeItem("PLATINUM", AppBadgeTheme.platinum, ratingVal >= 4.7),
            _badgeItem("DIAMOND", AppBadgeTheme.diamond, ratingVal >= 4.9),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _statusItem(StatusTheme.topRatedIcon, "Top rated", ratingVal >= 4.8, StatusTheme.topRatedColor),
            _statusItem(StatusTheme.verifiedIcon, "Verified", true, StatusTheme.verifiedColor),
            _statusItem(StatusTheme.trustedIcon, "Trusted", ratingVal >= 4.2, StatusTheme.trustedColor),
          ]),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 70, backgroundColor: Colors.white,
            backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) ? NetworkImage(_profileImageUrl!) : null,
            child: (_profileImageUrl == null || _profileImageUrl!.isEmpty) ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text(_displayName.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF263238)))),
            if (_isLocked) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock, size: 18, color: Colors.redAccent)),
          ]),
          Text(widget.role.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          Text(_displayLocation, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _statItem(Icons.check_circle_outline, "COMPLETED", widget.completedText),
            _statItem(Icons.star, "RATING", widget.ratingText),
            _statItem(Icons.reviews_outlined, "REVIEWS", widget.reviewsText),
          ]),
          const SizedBox(height: 24),

          // NEW: Counts + Follow button (Option B)
          if (widget.isOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _countCol("Followers", _followersCount),
                  Container(height: 30, width: 1, color: Colors.grey.shade400),
                  _countCol("Following", _followingCount),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$_followersCount followers", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? AppColors.brandDark : Colors.transparent,
                      foregroundColor: _isFollowing ? Colors.white : AppColors.brandDark,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.brandDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(_isFollowing ? "FOLLOWING" : "FOLLOW", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Existing call/chat row (unchanged)
          if (!widget.isOwner)
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse("tel:${widget.phone}")),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB2FF59), foregroundColor: Colors.black),
                  icon: const Icon(Icons.call),
                  label: const Text("CALL NOW"),
                ),
              ),
              const SizedBox(width: 8),
              _roundIconButton(Icons.chat_bubble_outline, onTap: () async {
                final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: _supporterKey);
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: convId,
                        userName: _displayName,
                        userRole: widget.role,
                        userImage: _profileImageUrl ?? "",
                      ),
                    ),
                  );
                }
              }),
            ]),
        ],
      ),
    );
  }

  // --- Helper Widgets ( missing methods added back ) ---
  Widget _countCol(String label, int count) => Column(
    children: [
      Text(
        "$count",
        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandDark),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ],
  );

  Widget _roundIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _badgeItem(String label, Color color, bool active) => Opacity(opacity: active ? 1 : 0.25, child: Column(children: [Icon(AppBadgeTheme.baseIcon, color: active ? color : Colors.black, size: 30), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]));
  Widget _statusItem(IconData icon, String label, bool active, Color color) => Opacity(opacity: active ? 1 : 0.3, child: Column(children: [Icon(icon, color: active ? color : Colors.black, size: 26), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))]));
  Widget _statItem(IconData icon, String label, String val) => Column(children: [Icon(icon, size: 20, color: const Color(0xFF263238)), Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54))]);
  Widget _infoRow(IconData icon, String label, String val) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(val, style: const TextStyle(fontWeight: FontWeight.w600))]));
  Widget _buildSection({required String title, required Widget child}) => Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark)), const SizedBox(height: 12), child]));
  Widget _buildSectionWithAction({required String title, required VoidCallback onActionTap, required Widget child}) => Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark))), TextButton(onPressed: onActionTap, child: const Text("See all"))]), const SizedBox(height: 12), child]));
  Widget _buildPortfolioImage(String url) => Container(margin: const EdgeInsets.only(right: 10), width: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)));
}

class _ReviewItem extends StatelessWidget {
  final String reviewer, comment; final int stars;
  const _ReviewItem({required this.reviewer, required this.comment, required this.stars});
  @override Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.account_circle, color: Colors.grey), const SizedBox(width: 8), Text(reviewer, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < stars ? Colors.amber : Colors.grey[300])))],), const SizedBox(height: 4), Text(comment, style: const TextStyle(fontSize: 13, color: Colors.black54))])); }
}

class ThemeChooserBottomSheet extends StatelessWidget {
  final int currentIndex;
  const ThemeChooserBottomSheet({super.key, required this.currentIndex});
  @override Widget build(BuildContext context) {
    final gradients = [[const Color(0xFFB2EBF2), const Color(0xFFE0F7FA)], [const Color(0xFFFFCC80), const Color(0xFFFFE0B2)], [const Color(0xFFC5CAE9), const Color(0xFFE8EAF6)], [const Color(0xFFF8BBD0), const Color(0xFFFCE4EC)]];
    return Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Choose Profile Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(gradients.length, (i) => GestureDetector(onTap: () => Navigator.pop(context, i), child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 60, height: 60, decoration: BoxDecoration(gradient: LinearGradient(colors: gradients[i]), shape: BoxShape.circle, border: Border.all(color: i == currentIndex ? AppColors.brandDark : Colors.transparent, width: 4))))))]));
  }
}
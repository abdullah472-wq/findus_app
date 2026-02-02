import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:intl/intl.dart';

enum FollowListType { followers, following }

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final FollowListType listType;

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.listType,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  Stream<QuerySnapshot>? _userStream;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final collectionName = widget.listType == FollowListType.followers
        ? 'followers'
        : 'following';

    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection(collectionName)
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  // ✅ Unfollow or Remove Follower Logic
  Future<void> _handleUnfollowOrRemove(String targetUserId, String targetUserName) async {
    final bool isMyProfile = widget.userId == _currentUid;
    if (!isMyProfile) return; // অন্য কারো প্রোফাইল দেখলে রিমুভ করা যাবে না

    final action = widget.listType == FollowListType.following ? "Unfollow" : "Remove";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$action $targetUserName?"),
        content: Text("Are you sure you want to $action this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action.toUpperCase(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // রেফারেন্সগুলো
      final meRef = FirebaseFirestore.instance.collection('users').doc(_currentUid);
      final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUserId);

      if (widget.listType == FollowListType.following) {
        // আমি তাকে আনফলো করছি
        batch.delete(meRef.collection('following').doc(targetUserId));
        batch.delete(targetRef.collection('followers').doc(_currentUid));

        batch.update(meRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(targetRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        // আমি আমার ফলোয়ার রিমুভ করছি
        batch.delete(meRef.collection('followers').doc(targetUserId));
        batch.delete(targetRef.collection('following').doc(_currentUid));

        batch.update(meRef, {'followersCount': FieldValue.increment(-1)});
        batch.update(targetRef, {'followingCount': FieldValue.increment(-1)});
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User ${action}ed successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: widget.listType == FollowListType.followers ? 'Followers' : 'Following',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserItem(users[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.listType == FollowListType.followers
                ? Icons.people_outline_rounded
                : Icons.person_add_alt_1_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            widget.listType == FollowListType.followers
                ? 'No followers yet'
                : 'Not following anyone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(DocumentSnapshot userDoc, bool isDark) {
    final targetUserId = userDoc.id;
    final bool isMyProfileList = widget.userId == _currentUid; // আমি আমার লিস্ট দেখছি কি না

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final userProfile = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userName = userProfile['name'] ?? 'Unknown User';
        final userRole = (userProfile['userRole'] ?? 'finder').toString().toLowerCase();
        final profileImage = userProfile['image'] ?? '';
        final roleLabel = userRole == 'finder' ? 'Worker' : 'Supporter';
        final roleColor = userRole == 'finder' ? Colors.blue : Colors.orange;

        final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: GestureDetector(
              onTap: () => _viewProfile(targetUserId),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.brandLight,
                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty ? const Icon(Icons.person, color: AppColors.brandDark) : null,
              ),
            ),
            title: Text(
              userName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                  ),
                ),
              ],
            ),
            trailing: isMyProfileList
                ? OutlinedButton(
              onPressed: () => _handleUnfollowOrRemove(targetUserId, userName),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              child: Text(
                widget.listType == FollowListType.following ? "Unfollow" : "Remove",
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
            )
                : null,
            onTap: () => _viewProfile(targetUserId),
          ),
        );
      },
    );
  }

  void _viewProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: userId,
          isOwner: userId == _currentUid,
          showBack: true,
        ),
      ),
    );
  }
}
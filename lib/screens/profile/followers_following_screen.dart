import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          const SizedBox(height: 8),
          Text(
            widget.listType == FollowListType.followers
                ? 'People who follow you will appear here.'
                : 'Profiles you follow will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(DocumentSnapshot userDoc, bool isDark) {
    final followData = userDoc.data() as Map<String, dynamic>? ?? {};

    // Followers/Following সাবকালেকশনে সাধারণত শুধু uid সেভ থাকে
    // অথবা মিনিমাম ইনফো থাকে। এখানে আমরা ধরে নিচ্ছি ডকের ID টাই হলো টার্গেট ইউজার ID
    final targetUserId = userDoc.id;

    final followedAt = followData['followedAt'] != null
        ? (followData['followedAt'] as Timestamp).toDate()
        : DateTime.now();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final userProfile = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final userName = userProfile['name'] ?? 'Unknown User';
        final userRole = (userProfile['userRole'] ?? 'finder').toString().toUpperCase();
        final profileImage = userProfile['image'] ?? '';
        // final isVerified = userProfile['kyc_completed'] == true;

        final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.brandLight,
                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty
                    ? const Icon(Icons.person, color: AppColors.brandDark)
                    : null,
              ),
              const SizedBox(width: 14),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandMain.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            userRole == 'MAKER' ? 'SUPPORTER' : 'WORKER',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(followedAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // View Profile Button
              IconButton(
                onPressed: () => _viewProfile(targetUserId),
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _viewProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: userId,
          isOwner: false, // যেহেতু অন্য কারো প্রোফাইল দেখছে
          showBack: true,
        ),
      ),
    );
  }
}
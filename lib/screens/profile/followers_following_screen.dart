import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listType == FollowListType.followers
              ? 'ফলোয়ার'
              : 'ফলো করছেন',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserItem(users[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.listType == FollowListType.followers
                ? Icons.people_outline
                : Icons.group_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.listType == FollowListType.followers
                ? 'কোনো ফলোয়ার নেই'
                : 'কাউকে ফলো করছেন না',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.listType == FollowListType.followers
                ? 'আপনার প্রোফাইল ভিজিট করে নতুন মানুষজন আপনাকে ফলো করবে'
                : 'অন্যান্য ব্যবহারকারীদের প্রোফাইল ভিজিট করুন এবং ফলো করুন',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final userId = userDoc.id;
    final userName = userData['userName'] ?? 'User';
    final followedAt = userData['followedAt'] != null
        ? (userData['followedAt'] as Timestamp).toDate()
        : DateTime.now();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final profileImage = userProfile['image'] ?? '';
        final userRole = userProfile['userRole'] ?? 'user';
        final isOnline = userProfile['isOnline'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Image
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImage.isNotEmpty
                          ? Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 30),
                      )
                          : const Icon(Icons.person, size: 30),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole == 'worker' ? 'Worker' :
                      userRole == 'supporter' ? 'Supporter' : 'User',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(followedAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // View Profile Button
              IconButton(
                onPressed: () => _viewProfile(userId),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                  size: 20,
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

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years বছর আগে';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months মাস আগে';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks সপ্তাহ আগে';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} দিন আগে';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ঘণ্টা আগে';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} মিনিট আগে';
    } else {
      return 'এইমাত্র';
    }
  }

  void _viewProfile(String userId) {
    // এখানে নেভিগেশন যোগ করুন
    // আপনি চাইলে UnifiedProfileScreen এ নেভিগেট করতে পারেন
    // অথবা অন্য কোন প্রোফাইল স্ক্রিনে নিয়ে যেতে পারেন
    Navigator.pop(context);
    // TODO: প্রোফাইল নেভিগেশন যোগ করুন
  }
}
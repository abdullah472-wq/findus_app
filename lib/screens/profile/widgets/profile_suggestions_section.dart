import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/models/worker_model.dart';

// Screens
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_constants.dart';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';
import 'package:findus_app/screens/profile/suggestion_see_all_screen.dart';

class ProfileSuggestionsSection extends StatelessWidget {
  final SuggestionType type;
  final String targetRole;
  final bool isDark;
  final String? excludeUid;
  final String? targetUid;
  final int limit;
  final bool showSeeAll;
  final VoidCallback? onSeeAllTap;

  const ProfileSuggestionsSection({
    super.key,
    required this.type,
    required this.targetRole,
    required this.isDark,
    this.excludeUid,
    this.targetUid,
    this.limit = 4, // ✅ Default 4 cards per section
    this.showSeeAll = true,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildSectionHeader(context),

        const SizedBox(height: 12),

        // Content based on type
        if (type == SuggestionType.userPosts)
          _buildUserPostsSection(context)
        else
          _buildUsersSection(context),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icon with colored background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type.icon,
              color: type.color,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              type.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // "See All" button
          if (showSeeAll && type != SuggestionType.userPosts)
            TextButton(
              onPressed: () {
                if (onSeeAllTap != null) {
                  onSeeAllTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuggestionSeeAllScreen(
                        type: type,
                        targetRole: targetRole,
                        excludeUid: excludeUid,
                      ),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "See All",
                    style: TextStyle(
                      fontSize: 12,
                      color: type.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: type.color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // USER POSTS SECTION (Vertical List)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserPostsSection(BuildContext context) {
    final String uid = targetUid ?? '';
    if (uid.isEmpty) {
      return _buildEmptyState(
        title: "No posts available",
        subtitle: "User ID not found",
        icon: Icons.article_outlined,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snap) {
        // Loading State
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildVerticalShimmer();
        }

        // Error State
        if (snap.hasError) {
          debugPrint("❌ Posts error: ${snap.error}");
          return _buildEmptyState(
            title: "Couldn't load posts",
            subtitle: "Please try again later",
            icon: Icons.error_outline,
          );
        }

        // Empty State
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _buildEmptyState(
            title: "No active posts",
            subtitle: "This user hasn't posted any jobs yet",
            icon: Icons.article_outlined,
          );
        }

        final docs = snap.data!.docs;

        // ✅ Vertical List of Cards
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, ownerSnap) {
                final ownerData = ownerSnap.data?.data() as Map<String, dynamic>? ?? {};

                return _buildPostCard(
                  context: context,
                  postId: doc.id,
                  postData: data,
                  ownerUid: uid,
                  ownerData: ownerData,
                );
              },
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // USERS SECTION (Vertical List)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUsersSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getQueryForType(),
      builder: (context, snap) {
        // Loading State
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildVerticalShimmer();
        }

        // Error State
        if (snap.hasError) {
          debugPrint("❌ Users error: ${snap.error}");
          return _buildEmptyState(
            title: "Couldn't load users",
            subtitle: "Please try again later",
            icon: Icons.error_outline,
          );
        }

        // Filter out current user and excluded uid
        var docs = snap.data?.docs ?? [];
        final currentUid = FirebaseAuth.instance.currentUser?.uid;

        docs = docs.where((d) {
          if (d.id == currentUid) return false;
          if (excludeUid != null && d.id == excludeUid) return false;
          return true;
        }).toList();

        // Empty State
        if (docs.isEmpty) {
          return _buildEmptyState(
            title: "No ${type.title.toLowerCase()} found",
            subtitle: "Check back later for more suggestions",
            icon: type.icon,
          );
        }

        // ✅ Vertical List of Cards
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildUserCard(context, doc.id, data);
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UNIVERSAL WORKER CARD FOR POSTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPostCard({
    required BuildContext context,
    required String postId,
    required Map<String, dynamic> postData,
    required String ownerUid,
    required Map<String, dynamic> ownerData,
  }) {
    // Post Data
    final String title = postData['title']?.toString() ?? 'Untitled';
    final String location = postData['address']?.toString() ?? 'Location not set';
    final String price = postData['priceLabel']?.toString() ?? 'Negotiable';
    final String category = postData['category']?.toString() ?? postData['roleLabel']?.toString() ?? 'Job';

    // Owner Data
    final String ownerName = ownerData['name']?.toString() ?? 'User';
    final String ownerImage = ownerData['image']?.toString() ?? '';
    final String ownerRole = ownerData['userRole']?.toString() ?? 'finder';
    final double rating = double.tryParse(ownerData['rating']?.toString() ?? '0') ?? 0.0;
    final int completed = int.tryParse(ownerData['completedCount']?.toString() ?? '0') ?? 0;
    final int followers = int.tryParse(ownerData['followersCount']?.toString() ?? '0') ?? 0;
    final bool isVerified = ownerData['kyc_completed'] == true;

    // Role Label
    final String roleLabel = ownerRole == 'finder' ? 'Worker' : 'Supporter';

    // Navigate to job details
    void navigateToJobDetails() {
      final workerObj = Worker(
        uid: ownerUid,
        postId: postId,
        name: ownerName,
        userRole: ownerRole,
        image: ownerImage,
        about: ownerData['about']?.toString() ?? '',
        location: location,
        rating: rating,
        priceText: price,
        price: double.tryParse(postData['price']?.toString() ?? '0'),
        kycCompleted: isVerified,
        experience: double.tryParse(ownerData['experienceYears']?.toString() ?? '0'),
        phone: ownerData['phone']?.toString(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerJobDetailsScreen(worker: workerObj),
        ),
      );
    }

    return UniversalWorkerCard(
      id: ownerUid,
      name: title, // ✅ Post title as card name
      role: roleLabel,
      imageUrl: ownerImage,
      address: location,
      rating: rating.toStringAsFixed(1),
      completed: completed.toString(),
      reviews: "0",
      price: price,
      followersCount: followers,
      isVerifiedWorker: isVerified,
      isTopRated: rating >= 4.9,
      isTrusted: completed >= 50 && rating >= 4.5,
      showStats: true,
      showActionButtons: true,
      showSaveButton: true,
      showShareButton: true,
      primaryButtonText: "View Job Details",
      jobLabel: "JOBS",
      tagText: category,
      tagColor: type.color,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: navigateToJobDetails,
      onViewProfileTap: navigateToJobDetails,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UNIVERSAL WORKER CARD FOR USERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserCard(BuildContext context, String uid, Map<String, dynamic> data) {
    // User Data
    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();
    final String role = (data['userRole'] ?? 'finder').toString();
    final String location = (data['location'] ?? 'Location not set').toString();
    final double rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
    final int completed = int.tryParse(data['completedCount']?.toString() ?? '0') ?? 0;
    final int followers = int.tryParse(data['followersCount']?.toString() ?? '0') ?? 0;
    final bool isVerified = data['kyc_completed'] == true;
    final String priceText = data['priceText']?.toString() ?? 'Negotiable';

    // Role Label
    final String roleLabel = role == 'finder' ? 'Worker' : 'Supporter';

    // Get tag based on suggestion type
    String? tagText;
    Color? tagColor;
    IconData? tagIcon;

    switch (type) {
      case SuggestionType.topRated:
        tagText = "Top Rated";
        tagColor = Colors.orange;
        tagIcon = Icons.star;
        break;
      case SuggestionType.newUsers:
        tagText = "New";
        tagColor = Colors.green;
        tagIcon = Icons.fiber_new;
        break;
      case SuggestionType.recommended:
        tagText = "Recommended";
        tagColor = AppColors.brandMain;
        tagIcon = Icons.thumb_up;
        break;
      case SuggestionType.recentlyActive:
        tagText = "Active";
        tagColor = Colors.teal;
        tagIcon = Icons.access_time;
        break;
      case SuggestionType.similarProfiles:
        tagText = "Similar";
        tagColor = Colors.purple;
        tagIcon = Icons.people;
        break;
      case SuggestionType.sponsored:
        tagText = "Featured";
        tagColor = Colors.amber;
        tagIcon = Icons.verified;
        break;
      default:
        break;
    }

    // Navigate to profile
    void navigateToProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProfileScreen(
            uid: uid,
            isOwner: false,
            showBack: true,
          ),
        ),
      );
    }

    return UniversalWorkerCard(
      id: uid,
      name: name,
      role: roleLabel,
      imageUrl: image,
      address: location,
      rating: rating.toStringAsFixed(1),
      completed: completed.toString(),
      reviews: "0",
      price: priceText,
      followersCount: followers,
      isVerifiedWorker: isVerified,
      isTopRated: rating >= 4.9,
      isTrusted: completed >= 50 && rating >= 4.5,
      showStats: true,
      showActionButtons: true,
      showSaveButton: true,
      showShareButton: true,
      primaryButtonText: "View Profile",
      jobLabel: role == 'finder' ? "JOBS" : "HIRED",
      tagText: tagText,
      tagColor: tagColor,
      tagIcon: tagIcon,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: navigateToProfile,
      onViewProfileTap: navigateToProfile,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERY BUILDER
  // ═══════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> _getQueryForType() {
    final collection = FirebaseFirestore.instance.collection('users');

    switch (type) {
      case SuggestionType.sponsored:
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('isSponsored', isEqualTo: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.topRated:
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('rating', isGreaterThanOrEqualTo: 4.0)
            .orderBy('rating', descending: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.recentlyActive:
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .orderBy('lastActiveAt', descending: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.newUsers:
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.nearbyWorkers:
        return collection
            .where('userRole', isEqualTo: 'finder')
            .where('kyc_completed', isEqualTo: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.nearbySupporters:
        return collection
            .where('userRole', isEqualTo: 'maker')
            .where('kyc_completed', isEqualTo: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.similarProfiles:
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('kyc_completed', isEqualTo: true)
            .orderBy('completedCount', descending: true)
            .limit(limit)
            .snapshots();

      case SuggestionType.recommended:
        return collection
            .where('userRole', isEqualTo: targetRole)
            .where('kyc_completed', isEqualTo: true)
            .orderBy('xpPoints', descending: true)
            .limit(limit)
            .snapshots();

      default:
        return collection
            .where('userRole', isEqualTo: targetRole)
            .limit(limit)
            .snapshots();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VERTICAL SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildVerticalShimmer() {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white60 : Colors.grey[600];
    final subTextColor = isDark ? Colors.white38 : Colors.grey[500];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: type.color.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: subTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
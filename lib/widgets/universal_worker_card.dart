// lib/widgets/universal_worker_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';

class UniversalWorkerCard extends StatelessWidget {
  final String? id;
  final String name;
  final String role;
  final String imageUrl;
  final String address;
  final String rating;
  final String completed;
  final String reviews;
  final String price;
  final String time;
  final String? phoneNumber;
  final EdgeInsetsGeometry margin;
  final int? followersCount;
  final String? facebookUrl;
  final String? emailAddress;
  final String? whatsappNumber;
  final String? websiteUrl;
  final int? colorIndex;
  final bool isVerifiedWorker;
  final bool isTopRated;
  final bool isTrusted;
  final bool isEditable;
  final bool isOnline;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onViewProfileTap;
  final VoidCallback? onShareTap;
  final BadgeLevel? badgeLevel;
  final bool isSaved;
  final VoidCallback? onSaveTap;
  final bool showActionButtons;
  final bool showStats;
  final bool showSaveButton;
  final bool showShareButton;
  final bool showOnlineStatus;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enableImageZoom;

  /// 🔹 নতুন: বাটনের টেক্সট কাস্টমাইজ করার জন্য
  final String primaryButtonText;

  const UniversalWorkerCard({
    super.key,
    this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.completed,
    required this.reviews,
    this.price = "Negotiable",
    this.time = "Available Now",
    this.phoneNumber,
    this.facebookUrl,
    this.emailAddress,
    this.whatsappNumber,
    this.websiteUrl,
    this.isVerifiedWorker = false,
    this.isTopRated = false,
    this.isTrusted = false,
    this.isEditable = false,
    this.isOnline = false,
    this.onTap,
    this.onChatTap,
    this.onViewProfileTap,
    this.onShareTap,
    this.badgeLevel,
    this.colorIndex,
    this.isSaved = false,
    this.onSaveTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    this.followersCount,
    this.showActionButtons = true,
    this.showStats = true,
    this.showSaveButton = true,
    this.showShareButton = false,
    this.showOnlineStatus = false,
    this.elevation,
    this.borderRadius,
    this.enableImageZoom = true,
    this.primaryButtonText = "View Job Details", // ✅ ডিফল্ট এখন View Job Details
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation ?? 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with image and basic info
              _buildHeaderSection(context),

              if (showStats) ...[
                const SizedBox(height: 12),
                _buildStatsSection(context),
              ],

              // Action buttons
              if (showActionButtons) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Image
        _buildProfileImage(context),
        const SizedBox(width: 12),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and verification
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerifiedWorker) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ],
                ],
              ),

              // Role
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Price and Time
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const Text(
                      " • ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    const double size = 80;

    // ✅ imageUrl ফাঁকা / "null" হলে placeholder দেখাবে
    final String url = imageUrl.trim();
    final bool hasImage = url.isNotEmpty && url.toLowerCase() != 'null';

    Widget imageChild;

    if (!hasImage) {
      imageChild = Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.person, size: 40, color: Colors.grey),
        ),
      );
    } else {
      imageChild = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageChild,
        ),

        // Online status indicator
        if (showOnlineStatus && isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.brandMain,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            completed,
            "Completed",
            Icons.check_circle_outline,
          ),
          Container(
            height: 20,
            width: 1,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            rating,
            "Rating",
            Icons.star_outline,
          ),
          Container(
            height: 20,
            width: 1,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            reviews,
            "Reviews",
            Icons.rate_review_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Primary Button
        Expanded(
          child: _buildViewProfileButton(context),
        ),

        const SizedBox(width: 8),

        // Chat Button
        if (onChatTap != null)
          _buildIconButton(
            onTap: onChatTap!,
            icon: Icons.chat_outlined,
            color: AppColors.brandMain,
            bgColor: AppColors.brandMain.withOpacity(0.1),
          ),

        // Save Button
        if (showSaveButton && onSaveTap != null) ...[
          const SizedBox(width: 8),
          _buildIconButton(
            onTap: onSaveTap!,
            icon: isSaved ? Icons.favorite : Icons.favorite_border,
            color: isSaved ? Colors.red : Colors.grey[600]!,
            bgColor: Colors.grey[100]!,
          ),
        ],

        // Share Button
        if (showShareButton && onShareTap != null) ...[
          const SizedBox(width: 8),
          _buildIconButton(
            onTap: onShareTap!,
            icon: Icons.share_outlined,
            color: Colors.grey[600]!,
            bgColor: Colors.grey[100]!,
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildViewProfileButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: onViewProfileTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.brandMain),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          primaryButtonText, // ✅ এখন কাস্টমাইজযোগ্য, ডিফল্ট "View Job Details"
          style: const TextStyle(
            color: AppColors.brandMain,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
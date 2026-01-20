import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/localization/localization_extension.dart';

class UniversalWorkerCard extends StatelessWidget {
  final String? id;
  final String name;
  final String role;
  final String? imageUrl; // ✅ null-safe
  final String address;
  final String rating;
  final String completed;
  final String reviews;
  final String price;
  final String time;

  final String? phoneNumber;
  final String? facebookUrl;
  final String? emailAddress;
  final String? whatsappNumber;
  final String? websiteUrl;

  final EdgeInsetsGeometry margin;
  final int followersCount; // ✅ always show (default 0)

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

  const UniversalWorkerCard({
    super.key,
    this.id,
    required this.name,
    required this.role,
    this.imageUrl,
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
    this.followersCount = 0, // ✅ default
    this.showActionButtons = true,
    this.showStats = true,
    this.showSaveButton = true,
    this.showShareButton = false,
    this.showOnlineStatus = false,
    this.elevation,
    this.borderRadius,
    this.enableImageZoom = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(15);

    return Card(
      margin: margin,
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(borderRadius: br),
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context),
              const SizedBox(height: 12),
              if (showStats) _buildStatsSection(context),
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
        _buildProfileImage(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
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
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ],
              ),
              Text(
                role,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                address,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    "$price • ",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandMain,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final hasUrl = url.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasUrl
              ? CachedNetworkImage(
            imageUrl: url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (_, __) => _imageFallback(),
            errorWidget: (_, __, ___) => _imageFallback(),
          )
              : _imageFallback(),
        ),
        if (showOnlineStatus && isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.brandMain),
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
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ followers always visible, same section style
  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                completed,
                context.tr('completed'),
                Icons.check_circle_outline,
              ),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStatItem(
                rating,
                context.tr('rating'),
                Icons.star_outline,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatItem(
                reviews,
                context.tr('reviews'),
                Icons.reviews_outlined,
              ),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStatItem(
                followersCount.toString(),
                'Followers',
                Icons.people_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildViewProfileButton(context)),
        const SizedBox(width: 8),

        if (onChatTap != null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onChatTap,
              icon: const Icon(
                Icons.chat_outlined,
                color: AppColors.brandMain,
                size: 20,
              ),
            ),
          ),

        if (showSaveButton && onSaveTap != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onSaveTap,
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? Colors.red : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],

        if (showShareButton && onShareTap != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onShareTap,
              icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
            ),
          ),
        ],
      ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
        child: Text(
          context.tr('view_profile'),
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
// lib/widgets/universal_worker_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_theme.dart';

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
    this.primaryButtonText = "View Job Details",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    // Badge color helper
    final Color badgeColor = _getBadgeColor(badgeLevel);

    // Price Logic: Check if price is simply "Negotiable" text
    final bool isNegotiableText = price.toLowerCase().contains('negotiable');

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: Stack(
            children: [
              // 🎨 Background Watermark
              Positioned(
                right: -15,
                top: -15,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.workspace_premium,
                    size: 120,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),

              // 🪪 Main Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ID Photo
                        _buildIDProfileImage(context, isDark),

                        const SizedBox(width: 14),

                        // Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Name & Badge Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name Part
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.brandMain,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔥 BADGE SECTION
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.workspace_premium,
                                          size: 28,
                                          color: badgeColor,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (badgeLevel?.name ?? 'MEMBER').toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Verification & Address
                              Row(
                                children: [
                                  if (isVerifiedWorker) ...[
                                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // 💰 Price Pill with Fixed Taka Icon
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.brandMain.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // যদি Negotiable না হয়, তবে টাকার আইকন দেখাবে
                                    if (!isNegotiableText)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 3),
                                        child: Text(
                                          "৳", // Fixed Taka Icon
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandMain,
                                          ),
                                        ),
                                      ),

                                    // Amount Text
                                    Text(
                                      price,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Stats Section
                    if (showStats) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIDStat(completed, "JOBS", isDark),
                            _verticalDivider(isDark),
                            _buildIDStat(rating, "RATING", isDark),
                            _verticalDivider(isDark),
                            _buildIDStat(reviews, "REVIEWS", isDark),
                          ],
                        ),
                      ),
                    ],

                    // Action Buttons
                    if (showActionButtons) ...[
                      const SizedBox(height: 16),
                      _buildActionButtons(context, isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Helper: Get Badge Color
  Color _getBadgeColor(BadgeLevel? level) {
    if (level == null) return Colors.grey;
    switch (level) {
      case BadgeLevel.bronze: return const Color(0xFFCD7F32);
      case BadgeLevel.silver: return const Color(0xFF757575);
      case BadgeLevel.gold: return const Color(0xFFD4AF37);
      case BadgeLevel.platinum: return const Color(0xFF795548);
      case BadgeLevel.diamond: return const Color(0xFF00ACC1);
      default: return Colors.grey;
    }
  }

  // 🖼️ Helper: Squircle Image
  Widget _buildIDProfileImage(BuildContext context, bool isDark) {
    const double size = 75;
    final String url = imageUrl.trim();
    final bool hasImage = url.isNotEmpty && url.toLowerCase() != 'null';

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 2
            ),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasImage
                ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: Icon(Icons.person, color: Colors.grey)),
              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.person, color: Colors.grey)),
            )
                : const Center(child: Icon(Icons.person, size: 35, color: Colors.grey)),
          ),
        ),
        if (showOnlineStatus && isOnline)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
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

  // 📊 Helper: Stats
  Widget _buildIDStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      height: 20,
      width: 1,
      color: isDark ? Colors.white12 : Colors.grey.shade300,
    );
  }

  // 🔘 Helper: Buttons
  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onViewProfileTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brandMain),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: isDark ? Colors.transparent : Colors.white,
                foregroundColor: AppColors.brandMain,
              ),
              child: Text(
                primaryButtonText.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onChatTap != null)
          _buildIDIconButton(Icons.chat_bubble_outline, onChatTap!, AppColors.brandMain, isDark),
        if (showSaveButton && onSaveTap != null) ...[
          const SizedBox(width: 8),
          _buildIDIconButton(
              isSaved ? Icons.favorite : Icons.favorite_border,
              onSaveTap!,
              isSaved ? Colors.red : (isDark ? Colors.white70 : Colors.grey.shade600),
              isDark
          ),
        ],
        if (showShareButton && onShareTap != null) ...[
          const SizedBox(width: 8),
          _buildIDIconButton(Icons.share_outlined, onShareTap!, isDark ? Colors.white70 : Colors.grey.shade600, isDark),
        ],
      ],
    );
  }

  Widget _buildIDIconButton(IconData icon, VoidCallback onTap, Color color, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
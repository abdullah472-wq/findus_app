// lib/widgets/universal_worker_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_theme.dart'; // Ensure this exists
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';

class UniversalWorkerCard extends StatefulWidget {
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

  // Optional Social Links
  final String? facebookUrl;
  final String? emailAddress;
  final String? whatsappNumber;
  final String? websiteUrl;

  final int? colorIndex;

  // Status Flags
  final bool isVerifiedWorker;
  final bool isTopRated;
  final bool isTrusted;

  final bool isEditable;
  final bool isOnline;

  // Callbacks
  final VoidCallback? onChatTap;
  final VoidCallback? onTap;
  final VoidCallback? onViewProfileTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;

  final BadgeLevel? badgeLevel;
  final bool isSaved;

  final bool showActionButtons;
  final bool showStats;
  final bool showSaveButton;
  final bool showShareButton;
  final bool showOnlineStatus;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enableImageZoom;
  final String primaryButtonText;
  final String jobLabel;

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
    this.showShareButton = true,
    this.showOnlineStatus = false,
    this.elevation,
    this.borderRadius,
    this.enableImageZoom = true,
    this.primaryButtonText = "View Job Details",
    this.jobLabel = "JOBS",
  });

  @override
  State<UniversalWorkerCard> createState() => _UniversalWorkerCardState();
}

class _UniversalWorkerCardState extends State<UniversalWorkerCard> {
  late bool _isSavedLocal;

  // 🎨 Theme Gradients List (Matching BottomSheet)
  final List<List<Color>> _themeGradients = const [
    [Color(0xFFE0F7FA), Color(0xFFFFFFFF)], // Teal (Light)
    [Color(0xFFFFF3E0), Color(0xFFFFFFFF)], // Orange (Light)
    [Color(0xFFE8EAF6), Color(0xFFFFFFFF)], // Indigo (Light)
    [Color(0xFFFCE4EC), Color(0xFFFFFFFF)], // Pink (Light)
  ];

  @override
  void initState() {
    super.initState();
    _isSavedLocal = widget.isSaved;
  }

  Future<void> _toggleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.id == null) return;

    setState(() => _isSavedLocal = !_isSavedLocal);

    final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('saved_profiles').doc(widget.id);

    if (_isSavedLocal) {
      await ref.set({
        'savedAt': FieldValue.serverTimestamp(),
        'workerId': widget.id,
        'name': widget.name,
        'image': widget.imageUrl,
        'role': widget.role,
      });
    } else {
      await ref.delete();
    }

    if (widget.onSaveTap != null) widget.onSaveTap!();
  }

  void _shareProfile() {
    if (widget.onShareTap != null) {
      widget.onShareTap!();
      return;
    }
    if (widget.id == null) return;
    final String link = "https://findus.app/profile/${widget.id}";
    final String text = "Check out ${widget.name} on FindUs!\nRole: ${widget.role}\nRating: ${widget.rating} ⭐\n$link";
    Share.share(text);
  }

  void _openChat() async {
    if (widget.id == null) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == widget.id) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: widget.id!);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: cid, userName: widget.name, userRole: widget.role, userImage: widget.imageUrl)),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Dynamic Theme Logic
    List<Color> bgColors;
    if (widget.colorIndex != null) {
      final index = widget.colorIndex!.clamp(0, _themeGradients.length - 1);
      final theme = _themeGradients[index];
      // Dark mode will overlay dark tint on theme
      bgColors = isDark ? [theme[0].withOpacity(0.8), const Color(0xFF1E1E1E)] : theme;
    } else {
      // Default colors if no theme selected
      bgColors = isDark ? [const Color(0xFF2C2C2C), const Color(0xFF2C2C2C)] : [Colors.white, Colors.white];
    }

    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    // ✅ Dynamic Badge Logic
    final activeBadge = widget.badgeLevel ?? BadgeLevel.newbie;
    final badgeColor = AppBadgeTheme.colorForLevel(activeBadge); // Assuming AppBadgeTheme exists
    final badgeName = activeBadge.name.toUpperCase();

    final bool isNegotiableText = widget.price.toLowerCase().contains('negotiable');
    String followersDisplay = widget.followersCount != null ? "${widget.followersCount}" : widget.reviews;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        // 🔥 Gradient Background Applied Here
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
          child: Stack(
            children: [
              // 🎨 Background Watermark (Your preferred design)
              Positioned(
                right: -15, top: -15,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.workspace_premium, size: 120, color: isDark ? Colors.white : Colors.black),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIDProfileImage(context, isDark),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name & Status Icons
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(widget.name.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  if (widget.isVerifiedWorker) _statusIcon(Icons.verified, Colors.blue),
                                  if (widget.isTopRated) _statusIcon(Icons.star, Colors.orange),
                                  if (widget.isTrusted) _statusIcon(Icons.shield, Colors.green),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(widget.role.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.brandMain, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(widget.address, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.brandMain.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isNegotiableText) const Padding(padding: EdgeInsets.only(right: 3), child: Text("৳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandMain))),
                                    Text(widget.price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔥🔥 Dynamic Badge Display
                        Column(
                          children: [
                            Icon(Icons.workspace_premium, size: 28, color: badgeColor),
                            Text(badgeName, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),

                    if (widget.showStats) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIDStat(widget.completed, widget.jobLabel, isDark),
                            _verticalDivider(isDark),
                            _buildIDStat(widget.rating, "RATING", isDark),
                            _verticalDivider(isDark),
                            _buildIDStat(followersDisplay, "FOLLOWERS", isDark),
                          ],
                        ),
                      ),
                    ],

                    if (widget.showActionButtons) ...[
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

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: () { if (widget.onViewProfileTap != null) widget.onViewProfileTap!(); },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brandMain),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: isDark ? Colors.transparent : Colors.white,
                foregroundColor: AppColors.brandMain,
              ),
              child: Text(widget.primaryButtonText.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildIDIconButton(Icons.chat_bubble_outline, widget.onChatTap ?? _openChat, AppColors.brandMain, isDark),
        if (widget.showSaveButton) ...[
          const SizedBox(width: 8),
          _buildIDIconButton(_isSavedLocal ? Icons.favorite : Icons.favorite_border, _toggleSave, _isSavedLocal ? Colors.red : (isDark ? Colors.white70 : Colors.grey.shade600), isDark),
        ],
        if (widget.showShareButton) ...[
          const SizedBox(width: 8),
          _buildIDIconButton(Icons.share_outlined, widget.onShareTap ?? _shareProfile, isDark ? Colors.white70 : Colors.grey.shade600, isDark),
        ],
      ],
    );
  }

  Widget _buildIDIconButton(IconData icon, VoidCallback onTap, Color color, bool isDark) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
      child: IconButton(onPressed: onTap, padding: EdgeInsets.zero, icon: Icon(icon, color: color, size: 18)),
    );
  }

  Widget _statusIcon(IconData icon, Color color) { return Padding(padding: const EdgeInsets.only(right: 4), child: Icon(icon, size: 16, color: color)); }
  Widget _buildIDProfileImage(BuildContext context, bool isDark) { const double size = 75; final String url = widget.imageUrl.trim(); final bool hasImage = url.isNotEmpty && url.toLowerCase() != 'null'; return Stack(children: [Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2), color: Colors.grey[200]), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: hasImage ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Center(child: Icon(Icons.person, color: Colors.grey))) : const Center(child: Icon(Icons.person, size: 35, color: Colors.grey)))), if (widget.showOnlineStatus && widget.isOnline) Positioned(right: -2, top: -2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))))]); }
  Widget _buildIDStat(String value, String label, bool isDark, {IconData? icon}) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.grey),
          const SizedBox(height: 2),
        ],
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
  Widget _verticalDivider(bool isDark) { return Container(height: 20, width: 1, color: isDark ? Colors.white12 : Colors.grey.shade300); }
}
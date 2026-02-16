import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/apply/apply_to_post_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/badge/badge_model.dart'; // ✅ Import for Badge

class WorkerJobDetailsScreen extends StatefulWidget {
  final Worker worker;

  const WorkerJobDetailsScreen({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerJobDetailsScreen> createState() => _WorkerJobDetailsScreenState();
}

class _WorkerJobDetailsScreenState extends State<WorkerJobDetailsScreen> {
  Map<String, dynamic>? _postData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trackJobView();
    _fetchPostDetails();
  }

  Future<void> _trackJobView() async {
    await AchievementService.incrementProgress('daily_view_jobs', amount: 1);
    await AchievementService.syncWeeklyChestFromServer();
  }

  Future<void> _fetchPostDetails() async {
    if (widget.worker.postId == null || widget.worker.postId!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.worker.postId)
          .get();

      if (doc.exists) {
        PostService.trackCardClick(doc.id, widget.worker.uid);

        setState(() {
          _postData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching post: $e");
      setState(() => _isLoading = false);
    }
  }

  String get _roleLabel {
    final r = widget.worker.userRole.toLowerCase().trim();
    return r == 'finder' ? 'Worker' : 'Supporter';
  }

  void _navigateToProfile(BuildContext context) {
    if (widget.worker.uid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: widget.worker.uid,
          isOwner: false,
          showBack: true,
        ),
      ),
    );
  }

  void _openChat(BuildContext context) async {
    if (widget.worker.uid.isEmpty) return;
    final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: widget.worker.uid);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: cid,
          userName: widget.worker.name,
          userRole: widget.worker.userRole,
          userImage: widget.worker.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black87;

    // ✅ 1. BADGE LOGIC CALCULATION
    final ratingVal = widget.worker.rating;
    final completedJobs = widget.worker.completedCount;

    final badgeLevel = (ratingVal >= 4.5 && completedJobs >= 500)
        ? BadgeLevel.gold
        : (completedJobs >= 100 ? BadgeLevel.silver : BadgeLevel.bronze);

    // Data extraction
    final String title = _postData?['title'] ?? "${_roleLabel} Service";
    final String description = _postData?['description'] ?? "No description provided.";
    final List<dynamic> mediaList = _postData?['images'] ?? [];

    // ✅ FIXED: Safe casting for slots
    final int slots = (_postData?['slots'] as num?)?.toInt() ?? 1;

    return FloatingScaffold(
      title: "JOB DETAILS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,

      body: Container(
        color: bgColor,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 UNIVERSAL WORKER CARD
                    UniversalWorkerCard(
                      id: widget.worker.uid,
                      name: widget.worker.name,
                      role: _roleLabel,
                      imageUrl: widget.worker.image,
                      address: widget.worker.location,
                      rating: widget.worker.rating.toStringAsFixed(1),
                      completed: widget.worker.completedCount.toString(),
                      reviews: widget.worker.reviewsCount.toString(),
                      price: widget.worker.priceText.isNotEmpty ? widget.worker.priceText : "Negotiable",

                      // ✅ PASSING BADGE LEVEL
                      badgeLevel: badgeLevel,

                      isVerifiedWorker: widget.worker.kycCompleted,
                      isTopRated: widget.worker.rating >= 4.8,
                      isTrusted: widget.worker.completedCount >= 50 && widget.worker.rating >= 4.5,

                      showActionButtons: true,
                      primaryButtonText: "View Profile",
                      onViewProfileTap: () => _navigateToProfile(context),

                      showSaveButton: true,
                      showShareButton: true,
                      onChatTap: () => _openChat(context),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      // 📄 Title Section
                      _buildSectionTitle("JOB TITLE", textColor),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      // ✅ 3. SLOTS DISPLAY UI
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group, color: AppColors.brandMain, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "People Needed: $slots",
                              style: const TextStyle(
                                color: AppColors.brandMain,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📄 Description Section
                      _buildSectionTitle("DESCRIPTION", textColor),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 📸 Media Section
                      if (mediaList.isNotEmpty) ...[
                        _buildSectionTitle("ATTACHMENTS", textColor),
                        const SizedBox(height: 10),
                        _buildMediaGrid(mediaList, cardColor, isDark),
                      ],
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomBar(context, isDark, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color.withOpacity(0.6),
        letterSpacing: 1,
      ),
    );
  }

  bool _isVideo(String url) => url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');
  bool _isAudio(String url) => url.toLowerCase().endsWith('.mp3') || url.toLowerCase().endsWith('.wav') || url.toLowerCase().endsWith('.m4a');

  Widget _buildMediaGrid(List<dynamic> urls, Color cardColor, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index].toString();

          return GestureDetector(
            onTap: () {
              // Full screen view logic here
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isVideo(url))
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                      ),
                    )
                  else if (_isAudio(url))
                    Container(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.audiotrack, color: AppColors.brandMain, size: 40),
                          const SizedBox(height: 5),
                          Text("Audio", style: TextStyle(fontSize: 10, color: AppColors.brandMain)),
                        ],
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade300),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),

                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isVideo(url) ? "VIDEO" : (_isAudio(url) ? "AUDIO" : "IMAGE"),
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openChat(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brandMain),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(50),
                backgroundColor: isDark ? Colors.transparent : Colors.white,
                foregroundColor: AppColors.brandMain,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("CHAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final postId = widget.worker.postId.toString().trim();
                if (postId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post ID not found.")),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplyToPostScreen(postId: postId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(50),
                elevation: 4,
              ),
              child: const Text(
                "APPLY NOW",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
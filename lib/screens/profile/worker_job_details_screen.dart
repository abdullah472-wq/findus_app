import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/hire_request_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart'; // ✅ Universal Card Import

class WorkerJobDetailsScreen extends StatelessWidget {
  final Worker worker;

  const WorkerJobDetailsScreen({
    super.key,
    required this.worker,
  });

  String get _roleLabel {
    final r = worker.userRole.toLowerCase().trim();
    return r == 'finder' ? 'Worker' : 'Supporter';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black87;

    final jobTitle = "$_roleLabel Service Details";
    final jobDescription =
        "This ${_roleLabel.toLowerCase()} is offering professional services in ${worker.location}.\n\n"
        "• Verified Profile: ${worker.kycCompleted ? 'Yes' : 'No'}\n"
        "• Experience: ${worker.experienceYears ?? 'Fresh'} Years\n"
        "• You can discuss work details, timing, and final pricing in chat.";

    // Price Display
    String displayPrice = worker.priceText.trim().isNotEmpty
        ? worker.priceText
        : (worker.price != null ? "${worker.price!.toInt()}" : "Negotiable");

    return FloatingScaffold(
      title: "JOB DETAILS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,

      // ✅ AppBar Action to View Profile
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline, color: textColor),
          tooltip: "View Profile",
          onPressed: () => _navigateToProfile(context),
        ),
      ],

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
                    // 🔥🔥 UNIVERSAL WORKER CARD (Instead of Custom Header)
                    UniversalWorkerCard(
                      id: worker.uid,
                      name: worker.name,
                      role: _roleLabel,
                      imageUrl: worker.image,
                      address: worker.location,
                      rating: worker.rating.toStringAsFixed(1),
                      completed: worker.completedCount.toString(),
                      reviews: worker.reviewsCount.toString(),
                      price: displayPrice,

                      isVerifiedWorker: worker.kycCompleted,
                      isTopRated: worker.rating >= 4.8,
                      isTrusted: worker.completedCount >= 50 && worker.rating >= 4.5,

                      // ✅ Button & Actions Config
                      showActionButtons: true,
                      primaryButtonText: "View Profile", // ✅ Button Text Change
                      onViewProfileTap: () => _navigateToProfile(context), // ✅ Action

                      showSaveButton: true,
                      showShareButton: true,

                      // Chat Action inside Card
                      onChatTap: () => _openChat(context),
                    ),

                    const SizedBox(height: 20),

                    // 📄 Description Card
                    _buildJobInfoCard(jobTitle, jobDescription, cardColor, textColor, subtitleColor, isDark),

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

  // ✅ Navigate to Profile
  void _navigateToProfile(BuildContext context) {
    if (worker.uid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: worker.uid,
          isOwner: false,
          showBack: true,
        ),
      ),
    );
  }

  // ✅ Open Chat
  void _openChat(BuildContext context) async {
    if (worker.uid.isEmpty) return;
    final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: worker.uid);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: cid,
          userName: worker.name,
          userRole: worker.userRole,
          userImage: worker.image,
        ),
      ),
    );
  }

  // 📝 Job Info Card (বাকি অংশ ঠিক রাখা হয়েছে)
  Widget _buildJobInfoCard(String title, String description, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.brandMain, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.6)),
        ],
      ),
    );
  }

  // 👇 Bottom Action Bar
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => HireRequestScreen(worker: worker)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(50),
                elevation: 4,
              ),
              child: const Text("HIRE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
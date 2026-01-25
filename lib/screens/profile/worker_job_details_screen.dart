// lib/screens/profile/worker_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/hire_request_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

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
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black87;

    final ratingText = worker.rating.toStringAsFixed(1);
    final jobTitle = "$_roleLabel service";
    final priceLabel = worker.priceText.trim().isNotEmpty
        ? worker.priceText
        : (worker.price != null ? "৳ ${worker.price!.toInt()}" : "Negotiable");

    final jobDescription =
        "This ${_roleLabel.toLowerCase()} is offering service near ${worker.location}.\n\n"
        "• You can discuss exact work details and timing in chat.\n"
        "• Price is $priceLabel (negotiable).";

    return FloatingScaffold(
      title: "Job Details",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline, color: textColor),
          onPressed: () {
            final uid = worker.uid.trim();
            if (uid.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile ID missing")),
              );
              return;
            }

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
          },
        ),
      ],
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, ratingText, priceLabel, isDark, cardColor, textColor),
                    const SizedBox(height: 16),
                    _buildJobInfoCard(jobTitle, jobDescription, cardColor, textColor, subtitleColor),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom fixed bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uid = worker.uid.trim();
                        if (uid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Chat user ID missing")),
                          );
                          return;
                        }

                        final cid = await FirestoreChatService.getOrCreateConversation(
                          otherUserId: uid,
                        );

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
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.brandMain),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: isDark ? Colors.transparent : Colors.white,
                        foregroundColor: AppColors.brandMain,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        "CHAT",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HireRequestScreen(worker: worker),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(45),
                      ),
                      child: const Text(
                        "HIRE NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header card ----------
  Widget _buildHeaderCard(
      BuildContext context,
      String ratingText,
      String priceLabel,
      bool isDark,
      Color cardColor,
      Color textColor,
      ) {
    final hasImg = worker.image.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.brandLight,
            backgroundImage: hasImg ? NetworkImage(worker.image) : null,
            child: hasImg ? null : Icon(Icons.person, color: AppColors.brandDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    ratingText,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // ---------- Job info card ----------
  Widget _buildJobInfoCard(
      String title,
      String description,
      Color cardColor,
      Color textColor,
      Color subtitleColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
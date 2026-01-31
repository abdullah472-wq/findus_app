// lib/screens/profile/worker_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ ইমেজ ক্যাশিং অ্যাড করা হলো
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
    final jobTitle = "$_roleLabel Service Details";

    // ✅ প্রাইস লেবেল লজিক (টাকা আইকন সহ)
    String displayPrice = worker.priceText.trim().isNotEmpty
        ? worker.priceText
        : (worker.price != null ? "${worker.price!.toInt()}" : "Negotiable");

    final jobDescription =
        "This ${_roleLabel.toLowerCase()} is offering professional services in ${worker.location}.\n\n"
        "• Verified Profile: ${worker.kycCompleted ? 'Yes' : 'No'}\n"
        "• Experience: ${worker.experienceYears ?? 'Fresh'} Years\n"
        "• You can discuss work details, timing, and final pricing in chat.";

    return FloatingScaffold(
      title: "JOB DETAILS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline, color: textColor),
          tooltip: "View Profile",
          onPressed: () {
            final uid = worker.uid.trim();
            if (uid.isEmpty) return;
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 ID Card Style Header
                    _buildHeaderCard(context, ratingText, displayPrice, isDark, cardColor, textColor),

                    const SizedBox(height: 20),

                    // 📄 Description Card
                    _buildJobInfoCard(jobTitle, jobDescription, cardColor, textColor, subtitleColor, isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom fixed bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uid = worker.uid.trim();
                        if (uid.isEmpty) return;

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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: isDark ? Colors.transparent : Colors.white,
                        foregroundColor: AppColors.brandMain,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        "CHAT",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        backgroundColor: AppColors.brandMain, // Brand Color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(50),
                        elevation: 4,
                      ),
                      child: const Text(
                        "HIRE NOW",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  // ---------- 🔥 Header card (ID Style) ----------
  Widget _buildHeaderCard(
      BuildContext context,
      String ratingText,
      String displayPrice,
      bool isDark,
      Color cardColor,
      Color textColor,
      ) {
    final hasImg = worker.image.trim().isNotEmpty;
    final bool isNegotiable = displayPrice.toLowerCase().contains('negotiable');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Squircle Image (ID Style)
          Container(
            width: 80,
            height: 80,
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
              child: hasImg
                  ? CachedNetworkImage(
                imageUrl: worker.image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
              )
                  : const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Name & FINDUS Stamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                    ),
                    // FINDUS Stamp
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.brandMain.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.brandMain.withOpacity(0.05),
                      ),
                      child: Text(
                        "FINDUS",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.brandMain,
                        ),
                      ),
                    ),
                  ],
                ),

                Text(
                  _roleLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.brandMain,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Rating & Reviews
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            ratingText,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // 💰 Fixed Taka Icon Logic
                    Row(
                      children: [
                        if (!isNegotiable)
                          Text("৳ ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandMain)),
                        Text(
                          displayPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      bool isDark,
      ) {
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
              Icon(Icons.description_outlined, color: AppColors.brandMain, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/profile/worker_job_details_screen.dart
//
// ✅ FIXED for new Worker model:
// - worker.role  ❌  -> use worker.userRole (finder/maker) OR show a nicer label
// - worker.price (num?) ❌ -> use worker.priceText (String) for display
// - ChatScreen userRole -> worker.userRole
// - Profile uid -> worker.uid (or worker.id getter if you kept it)
// ✅ Uses FloatingScaffold + bg AppColors.brandLight

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
    final ratingText = worker.rating.toStringAsFixed(1);

    // ✅ role label fixed
    final jobTitle = "${_roleLabel} service";

    // ✅ priceText fixed (string)
    final priceLabel = worker.priceText.trim().isNotEmpty
        ? worker.priceText
        : (worker.price != null ? "৳ ${worker.price!.toInt()}" : "Negotiable");

    final jobDescription =
        "This ${_roleLabel.toLowerCase()} is offering service near ${worker.location}.\n\n"
        "• You can discuss exact work details and timing in chat.\n"
        "• Price is $priceLabel (negotiable).";

    return FloatingScaffold(
      title: "Job Details",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.brandDark),
          onPressed: () {
            final uid = worker.uid.trim(); // ✅ was worker.id / ''
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
        color: AppColors.brandLight,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, ratingText, priceLabel),
                    const SizedBox(height: 16),
                    _buildJobInfoCard(jobTitle, jobDescription),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom fixed bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
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
                              userRole: worker.userRole, // ✅ was worker.role
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
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.brandMain,
                      ),
                      label: const Text(
                        "CHAT",
                        style: TextStyle(
                          color: AppColors.brandMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
  Widget _buildHeaderCard(BuildContext context, String ratingText, String priceLabel) {
    final hasImg = worker.image.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.brandLight,
            backgroundImage: hasImg ? NetworkImage(worker.image) : null,
            child: hasImg ? null : const Icon(Icons.person, color: AppColors.brandDark),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleLabel.toUpperCase(), // ✅ was worker.role.toUpperCase()
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
                priceLabel, // ✅ was worker.price (num? -> String error)
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
  Widget _buildJobInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/profile/worker_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                    // 🔥 Full Cover Style Header
                    _buildModernHeader(context, isDark, cardColor, textColor),

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

  // ------------------------------------------
  // 🔥 MODERN HEADER DESIGN (MATCHING PROFILE)
  // ------------------------------------------
  Widget _buildModernHeader(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    // Price Logic
    String displayPrice = worker.priceText.trim().isNotEmpty
        ? worker.priceText
        : (worker.price != null ? "${worker.price!.toInt()}" : "Negotiable");
    final bool isNegotiable = displayPrice.toLowerCase().contains('negotiable');

    // Status Logic
    final bool isVerified = worker.kycCompleted;
    final bool isTopRated = worker.rating >= 4.8;
    final bool isTrusted = worker.completedCount >= 50 && worker.rating >= 4.5;

    // Cover Gradient (Soft Blue/Purple)
    const Gradient coverGradient = LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Cover & Avatar
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              Positioned(
                bottom: -40,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipOval(child: _buildProfileImage()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 50),

          // 2. Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Name
                Text(
                  worker.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Role & Status Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _roleLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandMain,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isVerified || isTopRated || isTrusted) ...[
                      const SizedBox(width: 8),
                      Container(width: 1, height: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      if (isVerified) _statusIcon(Icons.verified, Colors.blue),
                      if (isTopRated) _statusIcon(Icons.star, Colors.orange),
                      if (isTrusted) _statusIcon(Icons.shield, Colors.green),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Stats & Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating Box
                    _buildStatBox(
                        "RATING",
                        worker.rating.toStringAsFixed(1),
                        Icons.star_rounded,
                        Colors.amber,
                        isDark
                    ),

                    const SizedBox(width: 10),

                    // Price Box (Highlighted)
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "PRICE",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandMain.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isNegotiable)
                                  Text("৳", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    displayPrice,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.brandMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🖼️ Helper: Profile Image
  Widget _buildProfileImage() {
    if (worker.image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: worker.image,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
      );
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey));
  }

  // 📦 Helper: Stat Box
  Widget _buildStatBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 16, color: color),
    );
  }

  // 📝 Job Info Card
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
              onPressed: () async {
                if (worker.uid.isEmpty) return;
                final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: worker.uid);
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: cid, userName: worker.name, userRole: worker.userRole, userImage: worker.image)));
              },
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
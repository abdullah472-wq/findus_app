import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';
import 'package:findus_app/services/profile_lock_service.dart';
import 'package:findus_app/services/firestore_chat_service.dart';

import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/screens/auth/login_screen.dart';

Future<void> showWorkerProfileBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required bool isWorker,
  required List<Map<String, dynamic>> allWorkers,
  required Worker workerModel,
}) async {
  bool isSaved = SavedService.isSaved(data);
  final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);

  // ✅ login check helper
  bool checkLogin(BuildContext ctx) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Login Required"),
          content: const Text("You need to login to access this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(ctx); // close bottom sheet
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
              child: const Text("LOGIN NOW"),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  // ✅ suggestion list (exclude current)
  final currentId = (data['ownerId'] ?? data['id'] ?? workerModel.uid).toString();
  final suggestions = allWorkers.where((w) {
    final wId = (w['ownerId'] ?? w['id'] ?? '').toString();
    return wId.isNotEmpty && wId != currentId;
  }).take(5).toList();

  Future<void> openProfile() async {
    if (!checkLogin(context)) return;
    Navigator.pop(context);

    final uid = workerModel.uid.trim();
    if (uid.isEmpty) return;

    final locked = await ProfileLockService.isLocked(uid);
    if (locked) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text('This profile is locked by the owner.')),
      );
      return;
    }

    rootNav.push(
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: uid, isOwner: false, showBack: true),
      ),
    );
  }

  // ✅ FIXED: always open WorkerJobDetailsScreen (post-centric flow)
  // ✅ FIXED: Directly open WorkerJobDetailsScreen (No loading/ad delay)
  Future<void> openJobDetails() async {
    if (!checkLogin(context)) return;

    final postId = workerModel.postId.toString().trim();
    if (postId.isEmpty) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text("No post found. Please select a post to view details.")),
      );
      return;
    }

    // ১. বটম শিট বন্ধ করা
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // ২. সরাসরি জব ডিটেইলস পেজে যাওয়া
    if (rootNav.context.mounted) {
      rootNav.push(
        MaterialPageRoute(
          builder: (_) => WorkerJobDetailsScreen(worker: workerModel),
        ),
      );
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final ratingVal = AchievementService.getRating(data);
          final completedJobs = AchievementService.getCompletedCount(data);

          final badgeLevel = (ratingVal >= 4.5 && completedJobs >= 500)
              ? BadgeLevel.gold
              : (completedJobs >= 100 ? BadgeLevel.silver : BadgeLevel.bronze);

          final isVerified = data['verified'] == true || data['isVerified'] == true;
          final isTrusted = ratingVal >= 4.2 && completedJobs >= 100;
          final isTopRated = ratingVal >= 4.8;
          final reviewsStr = (data['reviews'] ?? "0").toString();
          final priceStr = (data['price'] ?? data['priceLabel'] ?? "Negotiable").toString();

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (scrollCtx, controller) {
              final isDark = Theme.of(scrollCtx).brightness == Brightness.dark;
              final bgColor = isDark ? const Color(0xFF1E1E1E) : AppColors.bgBlue;
              final handleColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
              final sectionTitleColor = isDark ? Colors.white70 : Colors.black87;

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(10),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // 🔹 Main card
                    UniversalWorkerCard(
                      id: workerModel.uid,
                      name: (data['name'] ?? 'Unknown').toString(),
                      role: (data['role'] ?? 'Worker').toString(),
                      imageUrl: (data['image'] ?? "https://i.pravatar.cc/150").toString(),
                      address: (data['address'] ?? 'Bangladesh').toString(),
                      rating: ratingVal.toStringAsFixed(1),
                      completed: completedJobs.toString(),
                      reviews: reviewsStr,
                      price: priceStr,
                      time: (data['time'] ?? "Available now").toString(),
                      badgeLevel: badgeLevel,
                      isVerifiedWorker: isVerified,
                      isTrusted: isTrusted,
                      isTopRated: isTopRated,
                      isSaved: isSaved,

                      onTap: openProfile,

                      // ✅ Primary button is "VIEW DETAILS"
                      primaryButtonText: "View Details",
                      onViewProfileTap: openJobDetails,
                      showActionButtons: true,

                      onSaveTap: () async {
                        if (!checkLogin(context)) return;
                        await SavedService.toggleSave(data);
                        setSheetState(() => isSaved = SavedService.isSaved(data));
                      },

                      onChatTap: () async {
                        if (!checkLogin(context)) return;
                        final otherUid = workerModel.uid.trim();
                        final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUid);
                        if (rootNav.canPop()) rootNav.pop();
                        rootNav.push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convId,
                              userName: workerModel.name,
                              userRole: workerModel.userRole,
                              userImage: workerModel.image,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // 🔹 Suggestions Section
                    if (suggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 10),
                        child: Text(
                          "Nearby Verified Workers",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sectionTitleColor,
                          ),
                        ),
                      ),
                      Column(
                        children: suggestions.map((s) {
                          final sRating = AchievementService.getRating(s);
                          final sCompleted = AchievementService.getCompletedCount(s);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: UniversalWorkerCard(
                              id: (s['ownerId'] ?? s['id'] ?? '').toString(),
                              name: (s['name'] ?? 'Unknown').toString(),
                              role: (s['role'] ?? 'Worker').toString(),
                              imageUrl: (s['image'] ?? "https://i.pravatar.cc/150").toString(),
                              address: (s['address'] ?? 'Bangladesh').toString(),
                              rating: sRating.toStringAsFixed(1),
                              completed: sCompleted.toString(),
                              reviews: (s['reviews'] ?? "0").toString(),
                              price: (s['price'] ?? s['priceLabel'] ?? "Negotiable").toString(),
                              time: "Available now",
                              isVerifiedWorker: true,

                              // open suggestion sheet
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                showWorkerProfileBottomSheet(
                                  context: rootNav.context,
                                  data: s,
                                  isWorker: isWorker,
                                  allWorkers: allWorkers,
                                  workerModel: Worker(
                                    uid: (s['ownerId'] ?? s['id'] ?? '').toString(),
                                    postId: (s['id'] ?? '').toString(), // best-effort; suggestions no actions anyway
                                    name: (s['name'] ?? '').toString(),
                                    userRole: 'finder',
                                    image: (s['image'] ?? '').toString(),
                                    location: (s['address'] ?? '').toString(),
                                    priceText: (s['price'] ?? s['priceLabel'] ?? 'Negotiable').toString(),
                                    rating: sRating,
                                    kycCompleted: true,
                                  ),
                                );
                              },

                              showActionButtons: false,
                              showSaveButton: false,
                              showShareButton: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
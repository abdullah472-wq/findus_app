import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/services/profile_lock_service.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/badge/badge_model.dart';

import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';


Future<void> showWorkerProfileBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required bool isWorker,
  required List<Map<String, dynamic>> allWorkers,
  required Worker workerModel,
}) async {
  bool isSaved = SavedService.isSaved(data);
  final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);

  // ✅ CONSOLIDATED DATA EXTRACTION
  // Priority: workerModel -> data map -> fallback

  // 1. Name
  String displayName = workerModel.name.isNotEmpty
      ? workerModel.name
      : (data['name'] ?? data['workerName'] ?? 'Unknown User').toString();

  // 2. Image
  String displayImage = workerModel.image.isNotEmpty
      ? workerModel.image
      : (data['image'] ?? data['imageUrl'] ?? '').toString();

  // Fallback for empty/null image strings
  if (displayImage.isEmpty || displayImage == 'null') {
    displayImage = 'https://i.pravatar.cc/150';
  }

  // 3. Role
  final String displayRole = workerModel.userRole.isNotEmpty
      ? workerModel.userRole
      : (data['role'] ?? data['roleLabel'] ?? 'Worker').toString();

  // 4. Address
  final String displayAddress = workerModel.location.isNotEmpty
      ? workerModel.location
      : (data['address'] ?? data['location'] ?? 'Location not available').toString();

  // ✅ Login Check Helper
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
                Navigator.pop(dialogCtx); // Close Dialog
                Navigator.pop(ctx);       // Close Bottom Sheet
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

  // ✅ Suggestions (Exclude Current)
  final currentId = (data['ownerId'] ?? data['id'] ?? workerModel.uid).toString();
  final suggestions = allWorkers.where((w) {
    final wId = (w['ownerId'] ?? w['id'] ?? '').toString();
    return wId.isNotEmpty && wId != currentId;
  }).take(5).toList();

  // --- Action Handlers ---

  Future<void> openProfile() async {
    if (!checkLogin(context)) return;

    final uid = workerModel.uid.trim();
    if (uid.isEmpty) return;

    // ✅ STEP 1: Track Profile View
    await PostService.trackProfileClick(uid);

    // ✅ STEP 2: Check Lock & Navigate
    final locked = await ProfileLockService.isLocked(uid);
    if (locked) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text('This profile is locked by the owner.')),
      );
      return;
    }

    Navigator.pop(context); // Close bottom sheet

    rootNav.push(
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: uid, isOwner: false, showBack: true),
      ),
    );
  }

  Future<void> openJobDetails() async {
    if (!checkLogin(context)) return;

    final postId = workerModel.postId?.toString().trim() ?? '';
    if (postId.isEmpty) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text("No post found.")),
      );
      return;
    }

    // ✅ STEP 1: Track Click & Impression in Database
    // নোট: নিজের পোস্টে ক্লিক করলে সার্ভিস অটোমেটিক ইগনোর করবে
    await PostService.trackCardClick(postId, workerModel.uid);

    // ✅ STEP 2: Navigate
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (rootNav.context.mounted) {
      rootNav.push(
        MaterialPageRoute(
          builder: (_) => WorkerJobDetailsScreen(worker: workerModel),
        ),
      );
    }
  }

  // --- Bottom Sheet UI ---

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

                    // 🔹 Main Card
                    UniversalWorkerCard(
                      id: workerModel.uid,
                      name: displayName, // ✅ Using validated variable
                      role: displayRole,
                      imageUrl: displayImage, // ✅ Using validated variable
                      address: displayAddress,
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
                        if (otherUid.isEmpty) return;

                        try {
                          final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUid);
                          if (rootNav.canPop()) rootNav.pop();

                          rootNav.push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: convId,
                                userName: displayName,
                                userRole: displayRole,
                                userImage: displayImage,
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint("Chat Error: $e");
                        }
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
                          final sId = (s['ownerId'] ?? s['id'] ?? '').toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: UniversalWorkerCard(
                              id: sId,
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

                              // Recursive call for suggestions
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                showWorkerProfileBottomSheet(
                                  context: rootNav.context,
                                  data: s,
                                  isWorker: true, // Assuming suggestions are workers
                                  allWorkers: allWorkers,
                                  workerModel: Worker(
                                    uid: sId,
                                    postId: (s['id'] ?? '').toString(),
                                    name: (s['name'] ?? '').toString(),
                                    userRole: (s['role'] ?? 'finder').toString(),
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
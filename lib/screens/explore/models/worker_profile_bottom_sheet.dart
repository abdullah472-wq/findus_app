// lib/screens/explore/models/worker_profile_bottom_sheet.dart
//
// ✅ Fixed for new Worker model (uid/userRole/priceText/kycCompleted, no id/role/isVerified)
// ✅ Also fixes profile open: uses workerModel.uid
// ✅ Chat uses workerModel.uid
// ✅ UniversalWorkerCard role label uses data['role'] (pin label), not Worker.userRole
//
// NOTE: This file assumes your updated Worker model is the "production-grade" one I gave:
//   Worker(uid: ..., userRole: ..., priceText: ..., kycCompleted: ...)
//   plus getter: String get id => uid
// If you removed the id getter, replace workerModel.id with workerModel.uid below.

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';
import 'package:findus_app/screens/profile/job_post_gate_screen.dart';
import 'package:findus_app/services/profile_lock_service.dart';
import 'package:findus_app/services/firestore_chat_service.dart';

import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/badge/badge_model.dart';

Future<void> showWorkerProfileBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required bool isWorker,
  required List<Map<String, dynamic>> allWorkers,
  required Worker workerModel,
}) async {
  bool isSaved = SavedService.isSaved(data);
  final bool viewerIsWorker = isWorker;

  final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);

  final suggestions = allWorkers.where((w) {
    final wid = (w['id'] ?? '').toString();
    final did = (data['id'] ?? '').toString();
    final wname = (w['name'] ?? '').toString();
    final dname = (data['name'] ?? '').toString();

    if (wid.isNotEmpty && did.isNotEmpty && wid == did) return false;
    if (wid.isEmpty && did.isEmpty && wname == dname) return false;

    final isDemoWorker = wid.startsWith('demo_worker_');
    final isDemoSupporter = wid.startsWith('demo_supporter_');

    if (viewerIsWorker) {
      if (isDemoWorker) return false;
    } else {
      if (isDemoSupporter) return false;
    }
    return w['verified'] == true;
  }).take(5).toList();

  Future<void> openProfile() async {
    Navigator.pop(context); // close sheet first

    // ✅ Use user UID to check lock + open profile
    final uid = workerModel.uid.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text('Profile ID missing.')),
      );
      return;
    }

    final lockKey = uid.isNotEmpty
        ? uid
        : ((data['phone'] ?? '').toString().trim().isNotEmpty
        ? (data['phone'] as String).trim()
        : (data['name'] ?? '').toString());

    final locked = await ProfileLockService.isLocked(lockKey);
    if (locked) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text('This profile is locked by the owner.')),
      );
      return;
    }

    rootNav.push(
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: uid,
          isOwner: false,
          showBack: true,
        ),
      ),
    );
  }

  Future<void> openJobDetails() async {
    await showDialog(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dialogCtx).canPop()) Navigator.of(dialogCtx).pop();
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 12),
              Expanded(
                child: Text("Showing short ad to view details...", style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );

    Navigator.pop(context); // close bottom sheet

    if (isWorker) {
      rootNav.push(MaterialPageRoute(builder: (_) => JobPostGateScreen(worker: workerModel)));
    } else {
      rootNav.push(MaterialPageRoute(builder: (_) => WorkerJobDetailsScreen(worker: workerModel)));
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
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(10),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    UniversalWorkerCard(
                      id: workerModel.uid,
                      name: (data['name'] ?? 'Unknown').toString(),
                      role: (data['role'] ?? 'Worker').toString(), // label for UI
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

                      onSaveTap: () async {
                        await SavedService.toggleSave(data);
                        setSheetState(() => isSaved = SavedService.isSaved(data));
                      },

                      onChatTap: () async {
                        showDialog(
                          context: rootNav.context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        final otherUid = workerModel.uid.trim();
                        if (otherUid.isEmpty) {
                          if (rootNav.canPop()) rootNav.pop();
                          ScaffoldMessenger.of(rootNav.context).showSnackBar(
                            const SnackBar(content: Text("Chat user ID missing")),
                          );
                          return;
                        }

                        final convId = await FirestoreChatService.getOrCreateConversation(
                          otherUserId: otherUid,
                        );

                        if (rootNav.canPop()) rootNav.pop(); // close loading

                        rootNav.push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convId,
                              userName: workerModel.name,
                              userRole: workerModel.userRole, // ✅ was workerModel.role
                              userImage: workerModel.image,
                            ),
                          ),
                        );
                      },

                      onTap: openProfile,
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: openJobDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'VIEW JOB DETAILS',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (suggestions.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 15, bottom: 8),
                        child: Text(
                          "Nearby Verified Workers",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),

                    if (suggestions.isNotEmpty)
                      Column(
                        children: suggestions.map((s) {
                          final sRating = AchievementService.getRating(s);
                          final sCompleted = AchievementService.getCompletedCount(s);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                showWorkerProfileBottomSheet(
                                  context: rootNav.context,
                                  data: s,
                                  isWorker: isWorker,
                                  allWorkers: allWorkers,
                                  workerModel: Worker(
                                    uid: (s['ownerId'] ?? s['id'] ?? '').toString(),
                                    postId: (s['id'] ?? '').toString(),
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
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 50),
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
// lib/screens/explore/models/worker_profile_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/screens/earner/worker_job_details_screen.dart';
import 'package:findus_app/screens/supporter/job_post_gate_screen.dart';
import 'package:findus_app/services/profile_lock_service.dart';

// 🔹 badge/achievement হিসাবের জন্য
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/models/badge_model.dart';

Future<void> showWorkerProfileBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> data,             // raw worker map
  required bool isWorker,                         // current user role
  required List<Map<String, dynamic>> allWorkers, // suggestion এর জন্য
  required Worker workerModel,                    // map → Worker model
}) async {
  // পুরো data map দিয়েই saved চেক
  bool isSaved = SavedService.isSaved(data);

  // সাজেশন: current user রোল অনুযায়ী উল্টো রোলের পোস্ট দেখাবে
  //
  // isWorker == true  → user worker → শুধু supporter পোস্ট/কার্ড (demo_supporter + Firestore supporter)
  // isWorker == false → user supporter → শুধু worker পোস্ট/কার্ড (demo_worker + Firestore worker)
  final bool viewerIsWorker = isWorker;

  final suggestions = allWorkers.where((w) {
    // নিজেকে বাদ দাও (id match থাকলে, নইলে name match)
    final wid = (w['id'] ?? '').toString();
    final did = (data['id'] ?? '').toString();
    final wname = (w['name'] ?? '').toString();
    final dname = (data['name'] ?? '').toString();

    if (wid.isNotEmpty && did.isNotEmpty && wid == did) return false;
    if (wid.isEmpty && did.isEmpty && wname == dname) return false;

    // demo data তে type detect: demo_worker_ / demo_supporter_
    final isDemoWorker = wid.startsWith('demo_worker_');
    final isDemoSupporter = wid.startsWith('demo_supporter_');

    // user যদি worker → supporter-only দেখাব
    if (viewerIsWorker) {
      // worker viewer হলে worker demo বাদ
      if (isDemoWorker) return false;
      // বাকি সব (demo_supporter + Firestore supporter) allowed
    } else {
      // user যদি supporter → worker-only দেখাব
      if (isDemoSupporter) return false;
      // বাকি সব (demo_worker + Firestore worker) allowed
    }

    // চাইলে শুধু verified গুলো নাও
    if (w['verified'] != true) return false;

    return true;
  }).take(5).toList();

  // ----- View Profile লজিক -----
  void _openProfile() async {
    Navigator.pop(context); // bottom sheet বন্ধ

    // current worker এর lock key (id, না থাকলে phone, না থাকলে name)
    final lockKey = workerModel.id.isNotEmpty
        ? workerModel.id
        : ((data['phone'] ?? '').toString().trim().isNotEmpty
        ? (data['phone'] as String).trim()
        : (data['name'] as String));

    final locked = await ProfileLockService.isLocked(lockKey);

    if (locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This profile is locked by the owner.'),
        ),
      );
      return; // প্রোফাইল আর ওপেন হবে না
    }

    if (isWorker) {
      // Worker user ⇒ ভবিষ্যতে supporter profile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This profile is locked by the owner."),
        ),
      );
    } else {
      // Supporter user ⇒ worker profile-এ যাবে
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerProfileScreen(worker: workerModel),
        ),
      );
    }
  }

  // ----- View Job Details লজিক -----
  Future<void> _openJobDetails() async {
    // ছোট fake বিজ্ঞাপন dialog (২ সেকেন্ড)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dialogCtx).canPop()) {
            Navigator.of(dialogCtx).pop();
          }
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: const [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandMain),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Showing short ad to view job details...",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );

    // ad শেষ, এবার bottom sheet বন্ধ
    Navigator.pop(context);

    // তারপর role অনুযায়ী পেজে নিয়ে যাও
    if (isWorker) {
      // Worker user ⇒ supporter job gate
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobPostGateScreen(worker: workerModel),
        ),
      );
    } else {
      // Supporter user ⇒ worker job details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerJobDetailsScreen(worker: workerModel),
        ),
      );
    }
  }

  // ----- আসল bottom sheet UI -----
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          // 🔹 মূল worker data থেকে achievement info
          final ratingVal = AchievementService.getRatingFromData(data);
          final completedJobs =
          AchievementService.getCompletedFromData(data);
          final badgeLevel = AchievementService.getBadgeLevel(
            rating: ratingVal,
            completedJobs: completedJobs,
          );
          final isVerified =
          AchievementService.isVerifiedFromData(data);
          final isTrusted =
          AchievementService.isTrustedFromData(data);
          final isTopRated =
          AchievementService.isTopRated(ratingVal);

          final reviewsStr = (data['reviews'] ?? "0").toString();
          final priceStr =
          (data['price'] ?? data['priceLabel'] ?? "Negotiable")
              .toString();
          final timeStr =
          (data['time'] ?? "Available now").toString();

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(10),
                  children: [
                    // ছোট drag handle
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

                    // উপরের UniversalWorkerCard + bookmark
                    UniversalWorkerCard(
                      name: data['name'] ?? 'Unknown',
                      role: data['role'] ?? 'Worker',
                      imageUrl: data['image'] ?? "https://i.pravatar.cc/150",
                      address: data['address'] ?? 'Bangladesh',
                      rating: ratingVal.toStringAsFixed(1),
                      completed: completedJobs.toString(),
                      reviews: reviewsStr,
                      price: priceStr,
                      time: timeStr,
                      phoneNumber: data['phone'],

                      // 🔹 badge + status
                      badgeLevel: badgeLevel,
                      isVerifiedWorker: isVerified,
                      isTrusted: isTrusted,
                      isTopRated: isTopRated,

                      // 🔹 bookmark state
                      isSaved: isSaved,
                      onSaveTap: () async {
                        await SavedService.toggleSave(data);
                        setSheetState(() {
                          isSaved = SavedService.isSaved(data);
                        });
                      },

                      onChatTap: () {
                        final convId = (workerModel.id.isNotEmpty
                            ? workerModel.id
                            : (data['phone'] ?? data['name']))
                            .toString();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: convId,
                              userName: workerModel.name,
                              userRole: workerModel.role,
                              userImage: workerModel.image,
                            ),
                          ),
                        );
                      },
                      onTap: _openProfile,
                    ),

                    const SizedBox(height: 10),

                    // VIEW JOB DETAILS বাটন
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _openJobDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'VIEW JOB DETAILS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nearby Verified Workers title
                    if (suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 8),
                        child: Text(
                          "Nearby Verified Workers",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),

                    // 🔹 Suggestion গুলো vertical full UniversalWorkerCard
                    if (suggestions.isNotEmpty)
                      Column(
                        children: suggestions.map((s) {
                          final sRating =
                          AchievementService.getRatingFromData(s);
                          final sCompleted =
                          AchievementService.getCompletedFromData(s);
                          final sBadge = AchievementService.getBadgeLevel(
                            rating: sRating,
                            completedJobs: sCompleted,
                          );
                          final sVerified =
                          AchievementService.isVerifiedFromData(s);
                          final sTrusted =
                          AchievementService.isTrustedFromData(s);
                          final sTopRated =
                          AchievementService.isTopRated(sRating);

                          final sReviews =
                          (s['reviews'] ?? "0").toString();
                          final sPrice =
                          (s['price'] ?? s['priceLabel'] ?? "Negotiable")
                              .toString();
                          final sTime =
                          (s['time'] ?? "Available now").toString();

                          final sugWorker = Worker(
                            id: s["id"] ?? '',
                            name: s['name'] ?? '',
                            role: s['role'] ?? '',
                            image: s['image'] ?? "https://i.pravatar.cc/150",
                            location: s['address'] ?? 'Bangladesh',
                            price: sPrice,
                            isVerified: sVerified,
                            rating: sRating,
                          );

                          final bool sugIsSaved =
                          SavedService.isSaved(s);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: UniversalWorkerCard(
                              name: s['name'] ?? 'Unknown',
                              role: s['role'] ?? 'Worker',
                              imageUrl:
                              s['image'] ?? "https://i.pravatar.cc/150",
                              address: s['address'] ?? 'Bangladesh',
                              rating: sRating.toStringAsFixed(1),
                              completed: sCompleted.toString(),
                              reviews: sReviews,
                              price: sPrice,
                              time: sTime,
                              phoneNumber: s['phone'],

                              badgeLevel: sBadge,
                              isVerifiedWorker: sVerified,
                              isTrusted: sTrusted,
                              isTopRated: sTopRated,

                              isSaved: sugIsSaved,
                              onSaveTap: () async {
                                await SavedService.toggleSave(s);
                                setSheetState(() {});
                              },

                              onTap: () {
                                Navigator.pop(context);
                                showWorkerProfileBottomSheet(
                                  context: context,
                                  data: s,
                                  isWorker: isWorker,
                                  allWorkers: allWorkers,
                                  workerModel: sugWorker,
                                );
                              },
                              onChatTap: () {
                                final convId =
                                (sugWorker.id.isNotEmpty
                                    ? sugWorker.id
                                    : (s['phone'] ?? s['name']))
                                    .toString();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: convId,
                                      userName: sugWorker.name,
                                      userRole: sugWorker.role,
                                      userImage: sugWorker.image,
                                    ),
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
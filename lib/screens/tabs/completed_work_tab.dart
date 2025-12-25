import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/models/badge_model.dart';           // BadgeLevel
import 'package:findus_app/screens/hire_request_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/services/completed_work_service.dart';

// Firebase-backed review screen
import 'package:findus_app/screens/tabs/review_screen.dart';

class CompletedWorkTab extends StatelessWidget {
  const CompletedWorkTab({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = CompletedWorkService.getAllCompletedJobs();

    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          "No completed work yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      children: jobs.map((j) {
        // এখানে ধরে নিচ্ছি CompletedWorkJob এ workerKey, name, role আছে
        final workerKey = j.workerKey;
        final name = j.name;
        final role = j.role;

        return _buildHistoryItem(
          context,
          workerId: workerKey,
          postId: 'N/A', // future এ চাইলে model এ postId যোগ করবে
          name: name,
          role: role,
          imgUrl: "https://i.pravatar.cc/150?u=$workerKey", // demo avatar
          address: "Bangladesh",
          price: "Negotiable",
          rating: "0.0",
          completed: "0",
          reviews: "0",
          phoneNumber: "",
          isPaymentPending: false,
        );
      }).toList(),
    );
  }
}

Widget _buildHistoryItem(
    BuildContext context, {
      required String workerId,
      required String postId,
      required String name,
      required String role,
      required String imgUrl,
      required String address,
      required String price,
      required String rating,
      required String completed,
      required String reviews,
      required String phoneNumber,
      required bool isPaymentPending,
    }) {
  final double ratingValue = double.tryParse(rating) ?? 0.0;

  // "800+" এর মতো ভ্যালু থেকে সংখ্যা বের করা
  final match = RegExp(r'\d+').firstMatch(completed);
  final int completedJobs = int.tryParse(match?.group(0) ?? '0') ?? 0;

  // badge logic
  final bool isVerified = completedJobs >= 100;
  final bool isTopRated = ratingValue >= 4.5;
  final bool isTrusted = completedJobs >= 500 && ratingValue >= 4.2;

  BadgeLevel? badgeLevel;
  if (completedJobs > 0 && completedJobs < 100) {
    badgeLevel = BadgeLevel.bronze;
  } else if (completedJobs >= 100 && completedJobs < 500) {
    badgeLevel = BadgeLevel.silver;
  } else if (completedJobs >= 500) {
    badgeLevel = BadgeLevel.gold;
  }

  final String timeText =
  isPaymentPending ? "Payment Pending" : "Completed";

  // Worker অবজেক্ট – CONNECT AGAIN / PROFILE এ কাজে লাগবে
  final workerObj = Worker(
    id: workerId,
    name: name,
    role: role,
    image: imgUrl,
    location: address,
    rating: ratingValue,
    price: price,
    isVerified: isVerified,
  );

  return Column(
    children: [
      UniversalWorkerCard(
        name: name,
        role: role,
        imageUrl: imgUrl,
        address: address,
        rating: rating,
        completed: completed,
        reviews: reviews,
        price: price,
        time: timeText,
        phoneNumber: phoneNumber,
        isVerifiedWorker: isVerified,
        isTopRated: isTopRated,
        isTrusted: isTrusted,
        badgeLevel: badgeLevel,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerProfileScreen(
                worker: workerObj,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        onViewProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerProfileScreen(
                worker: workerObj,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        onChatTap: () {
          final convId =
          phoneNumber.trim().isNotEmpty ? phoneNumber.trim() : workerId;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: convId,
                userName: name,
                userRole: role,
                userImage: imgUrl,
              ),
            ),
          );
        },
      ),

      // নিচের action bar
      Container(
        margin: const EdgeInsets.only(
          left: 15,
          right: 15,
          bottom: 20,
          top: 0,
        ),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    if (isPaymentPending) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            workerName: name,
                            amount: price,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            workerId: workerId,
                            postId: postId,
                            workerName: name,
                            role: role,
                            imageUrl: imgUrl,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaymentPending
                        ? const Color(0xFFE1BEE7)
                        : const Color(0xFFFFF59D),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isPaymentPending
                        ? "PAY NOW"
                        : "Give Rating & Review",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HireRequestScreen(worker: workerObj),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5E1A5),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "CONNECT AGAIN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// ----------------- Placeholder Payment Screen -----------------
class PaymentScreen extends StatelessWidget {
  final String workerName;
  final String amount;

  const PaymentScreen({
    super.key,
    required this.workerName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme:
        const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              "Pay to $workerName",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Amount: $amount",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Payment flow will be implemented later.\nHere you can integrate bKash/Nagad/Card etc.",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
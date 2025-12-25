import 'package:flutter/material.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/models/badge_model.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';

/// Work-in-progress job model
class WorkInProgressJob {
  final String name;
  final String role;
  final String imageUrl;
  final String address;
  final String rating;
  final String completed;
  final String reviews;
  final String price;
  final String time;
  final String phoneNumber;

  const WorkInProgressJob({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.completed,
    required this.reviews,
    required this.price,
    required this.time,
    required this.phoneNumber,
  });
}

/// Global store: অন্য জায়গা থেকে APPROVE করলে এখানকার লিস্ট আপডেট হবে
class WorkInProgressStore {
  static final ValueNotifier<List<WorkInProgressJob>> jobsNotifier =
  ValueNotifier<List<WorkInProgressJob>>([
    // আগের demo গুলো initial হিসেবে
    const WorkInProgressJob(
      name: "Ashikur Rahman",
      role: "COMPUTER OPERATOR",
      imageUrl: "https://i.pravatar.cc/150?img=33",
      address: "Bholagonj, Sylhet",
      rating: "4.5",
      completed: "120",
      reviews: "45",
      price: "130 ৳",
      time: "RUNNING NOW",
      phoneNumber: "01711111111",
    ),
    const WorkInProgressJob(
      name: "Mijanur Rahman",
      role: "FARMER",
      imageUrl: "https://i.pravatar.cc/150?img=13",
      address: "Bhakoadi, Gazipur",
      rating: "4.8",
      completed: "800+",
      reviews: "150",
      price: "800 ৳",
      time: "STARTED 10 MIN AGO",
      phoneNumber: "01811111111",
    ),
  ]);

  static void addJob(WorkInProgressJob job) {
    final list = List<WorkInProgressJob>.from(jobsNotifier.value);
    list.insert(0, job); // new job top এ
    jobsNotifier.value = list;
  }
}

class WorkInProgressTab extends StatelessWidget {
  const WorkInProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WorkInProgressJob>>(
      valueListenable: WorkInProgressStore.jobsNotifier,
      builder: (context, jobs, _) {
        if (jobs.isEmpty) {
          return const Center(
            child: Text(
              "No jobs in progress.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: jobs
              .map((job) => _buildWorkCard(context, job: job))
              .toList(),
        );
      },
    );
  }

  Widget _buildWorkCard(
      BuildContext context, {
        required WorkInProgressJob job,
      }) {
    final double ratingValue = double.tryParse(job.rating) ?? 0.0;

    // "800+" এর মতো string থেকে 800 বের করা
    final match = RegExp(r'\d+').firstMatch(job.completed);
    final int completedJobs =
        int.tryParse(match?.group(0) ?? '0') ?? 0;

    // badge logic
    final bool isVerified = completedJobs >= 50;
    final bool isTopRated = ratingValue >= 4.5;
    final bool isTrusted =
        completedJobs >= 200 && ratingValue >= 4.2;

    BadgeLevel? badgeLevel;
    if (completedJobs > 0 && completedJobs < 100) {
      badgeLevel = BadgeLevel.bronze;
    } else if (completedJobs >= 100 && completedJobs < 500) {
      badgeLevel = BadgeLevel.silver;
    } else if (completedJobs >= 500) {
      badgeLevel = BadgeLevel.gold;
    }

    return UniversalWorkerCard(
      name: job.name,
      role: job.role,
      imageUrl: job.imageUrl,
      address: job.address,
      rating: job.rating,
      completed: job.completed,
      reviews: job.reviews,
      price: job.price,
      time: job.time,
      phoneNumber: job.phoneNumber,
      isVerifiedWorker: isVerified,
      isTopRated: isTopRated,
      isTrusted: isTrusted,
      badgeLevel: badgeLevel,

      // প্রোফাইল বাটন ক্লিক
      onTap: () {
        final workerObj = Worker(
          name: job.name,
          role: job.role,
          image: job.imageUrl,
          location: job.address,
          rating: ratingValue,
          price: job.price,
          isVerified: isVerified,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerProfileScreen(worker: workerObj),
          ),
        );
      },

      // চ্যাট বাটন ক্লিক
      onChatTap: () {
        // প্রতিটি ongoing job এর জন্য ইউনিক convId – এখানে phone ব্যবহার করছি
        final convId = job.phoneNumber; // চাইলে name+role মিলিয়েও বানাতে পারো

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: convId,   // 🔹 এখন phone কে conversationId ধরলাম
              userName: job.name,
              userRole: job.role,
              userImage: job.imageUrl,
            ),
          ),
        );
      },
    );
  }
}
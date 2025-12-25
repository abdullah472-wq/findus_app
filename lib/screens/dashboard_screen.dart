import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'rating_history_screen.dart';

/// ---------------- Dashboard Screen ----------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _openRatingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RatingHistoryScreen(),
      ),
    );
  }

  void _openPendingJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PendingJobsScreen(),
      ),
    );
  }

  void _openCompletedJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompletedWorkScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text(
          "DASHBOARD",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // ১. Analytics highlight card – একদম উপরে
          _buildPerformanceCard(),

          const SizedBox(height: 20),

          // ২. Work summary – ৪টা ছোট কার্ড
          const Text(
            "Work Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                "Jobs Done",
                "24",
                Icons.work,
                Colors.blue,
                onTap: _openCompletedJobs,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                "Pending Jobs",
                "03",
                Icons.pending_actions,
                Colors.orange,
                onTap: _openPendingJobs,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                "Avg Rating",
                "4.8",
                Icons.star,
                Colors.purple,
                onTap: _openRatingHistory,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                "Response Rate",
                "92%",
                Icons.speed,
                Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ৩. নিজের Posted Pins লিস্ট
          const Text(
            "Your Posted Pins",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPostedPinsSection(),
        ],
      ),
    );
  }

  // ---------- Helper widgets for Dashboard ----------

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Ad performance / Analytics card – আরও highlight করা
  Widget _buildPerformanceCard() {
    const int impressions = 1280;
    const int profileViews = 210;
    const int chats = 34;
    const int hires = 9;

    final double ctr =
    impressions == 0 ? 0 : (profileViews / impressions) * 100;
    final double hireRate =
    chats == 0 ? 0 : (hires / chats) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last 7 days performance",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "How many people are discovering you on FINDUS.",
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _perfStatItem(
                "Impressions",
                impressions.toString(),
                Icons.remove_red_eye_outlined,
                Colors.teal,
              ),
              _perfStatItem(
                "Profile views",
                profileViews.toString(),
                Icons.account_circle_outlined,
                Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _perfStatItem(
                "Chats started",
                chats.toString(),
                Icons.chat_bubble_outline,
                Colors.orange,
              ),
              _perfStatItem(
                "Hires / Responses",
                hires.toString(),
                Icons.handshake_outlined,
                Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "View→Profile CTR: ${ctr.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "Chat→Hire rate: ${hireRate.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _perfStatItem(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Firestore থেকে নিজের পোস্ট করা pins দেখানো
  Widget _buildPostedPinsSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text(
        "Log in to see your posted pins.",
        style: TextStyle(color: Colors.grey),
      );
    }

    final postsQuery = FirebaseFirestore.instance
        .collection('posts')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postsQuery.snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Text(
            'Error loading your posts.',
            style: TextStyle(color: Colors.redAccent),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            "You haven't posted any pins yet.",
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final title = (data['title'] ?? 'Post').toString();
            final roleLabel = (data['roleLabel'] ?? '').toString();
            final address = (data['address'] ?? '').toString();
            final priceLabel =
            (data['priceLabel'] ?? 'Negotiable').toString();

            String createdAtText = '';
            final createdAt = data['createdAt'];
            if (createdAt is Timestamp) {
              final dt = createdAt.toDate();
              createdAtText =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
                  ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (roleLabel.isNotEmpty)
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  if (createdAtText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Posted: $createdAtText',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// ---------------- Pending Jobs Screen ----------------

class PendingJobsScreen extends StatefulWidget {
  const PendingJobsScreen({super.key});

  @override
  State<PendingJobsScreen> createState() => _PendingJobsScreenState();
}

class _PendingJobsScreenState extends State<PendingJobsScreen> {
  // 🔹 mutable pending list (demo data)
  final List<Map<String, String>> _pendingJobs = [
    {
      "name": "Rahim Uddin",
      "role": "DRIVER",
      "img": "https://i.pravatar.cc/150?img=14",
      "address": "Mirpur, Dhaka",
      "price": "৳ 500",
      "rating": "4.9",
      "completed": "120",
      "reviews": "45",
      "phone": "01711111111",
    },
    {
      "name": "Karim Electrician",
      "role": "ELECTRICIAN",
      "img": "https://i.pravatar.cc/150?img=11",
      "address": "Banani, Dhaka",
      "price": "৳ 800",
      "rating": "4.7",
      "completed": "80",
      "reviews": "30",
      "phone": "01811111111",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text("Pending Jobs"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: _pendingJobs.isEmpty
          ? const Center(
        child: Text(
          "No pending jobs.",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingJobs.length,
        itemBuilder: (context, index) {
          final j = _pendingJobs[index];

          return Column(
            children: [
              UniversalWorkerCard(
                name: j["name"]!,
                role: j["role"]!,
                imageUrl: j["img"]!,
                address: j["address"]!,
                rating: j["rating"]!,
                completed: j["completed"]!,
                reviews: j["reviews"]!,
                price: j["price"]!,
                time: "PENDING APPROVAL",
                phoneNumber: j["phone"],
                isVerifiedWorker: true,
                isTopRated: true,
                isTrusted: true,
                onChatTap: () {
                  final convId =
                      j["phone"] ?? j["name"]!; // demo convId

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: convId,
                        userName: j["name"]!,
                        userRole: j["role"]!,
                        userImage: j["img"]!,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),

              // Approve / Reject row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                        ),
                        onPressed: () {
                          setState(() {
                            _pendingJobs.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Job Rejected"),
                            ),
                          );
                        },
                        child: const Text(
                          "REJECT",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                        ),
                        onPressed: () {
                          // Work in progress এ add
                          WorkInProgressStore.addJob(
                            WorkInProgressJob(
                              name: j["name"]!,
                              role: j["role"]!,
                              imageUrl: j["img"]!,
                              address: j["address"]!,
                              rating: j["rating"]!,
                              completed: j["completed"]!,
                              reviews: j["reviews"]!,
                              price: j["price"]!,
                              time: "RUNNING NOW",
                              phoneNumber: j["phone"]!,
                            ),
                          );

                          setState(() {
                            _pendingJobs.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Job moved to Work in Progress",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "APPROVE",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

/// ---------------- Completed Work Screen (wraps CompletedWorkTab) ----------------

class CompletedWorkScreen extends StatelessWidget {
  const CompletedWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text("Completed Jobs"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: const CompletedWorkTab(),
    );
  }
}
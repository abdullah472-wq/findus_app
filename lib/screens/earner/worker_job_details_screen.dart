import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/screens/hire_request_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';

class WorkerJobDetailsScreen extends StatelessWidget {
  final Worker worker;

  const WorkerJobDetailsScreen({
    super.key,
    required this.worker,
  });

  @override
  Widget build(BuildContext context) {
    final ratingText = worker.rating.toStringAsFixed(1);

    // আপাতত ডিফল্ট টাইটেল/ডেস্ক্রিপশন – পরে EarnPost থেকে ডাটা দিয়ে আপডেট করতে পারবে
    final jobTitle = "${worker.role} service";
    final jobDescription =
        "This worker is offering ${worker.role.toLowerCase()} service near ${worker.location}.\n\n"
        "• You can discuss exact work details and timing in chat.\n"
        "• Price is ${worker.price} (negotiable).";

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Job Details",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProfileScreen(worker: worker),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // উপরের ডিটেইলস স্ক্রলেবল
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(ratingText),
                  const SizedBox(height: 16),
                  _buildJobInfoCard(jobTitle, jobDescription),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // নিচে FIXED CHAT + HIRE NOW
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: worker.id,     // বা যেভাবে convId বানিয়েছো
                            userName: worker.name,
                            userRole: worker.role,
                            userImage: worker.image,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side:
                      const BorderSide(color: AppColors.brandMain),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
    );
  }

  // ---------- হেডার কার্ড ----------
  Widget _buildHeaderCard(String ratingText) {
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
            backgroundImage: NetworkImage(worker.image),
            backgroundColor: AppColors.brandLight,
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
                  worker.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        worker.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
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
                worker.price,
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
                  const Icon(Icons.star,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    ratingText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // ---------- জব ইনফো কার্ড ----------
  Widget _buildJobInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
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
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/screens/supporter/support_post_screen.dart';

class JobPostGateScreen extends StatefulWidget {
  final Worker worker;

  const JobPostGateScreen({
    super.key,
    required this.worker,
  });

  @override
  State<JobPostGateScreen> createState() => _JobPostGateScreenState();
}

class _JobPostGateScreenState extends State<JobPostGateScreen> {
  // TODO: ভবিষ্যতে এখানে আসল subscription ডাটা থেকে মান আসবে
  bool _isSubscriber = false;
  bool _isWatchingAd = false;

  Future<void> _goToSupportPost() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupportPostScreen(),
      ),
    );
  }

  Future<void> _handleWatchAdAndPost() async {
    setState(() => _isWatchingAd = true);

    // TODO: এখানে real rewarded ad ইন্টিগ্রেট করবে
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isWatchingAd = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ad watched (demo). Now you can post a job."),
        backgroundColor: AppColors.brandMain,
      ),
    );

    await _goToSupportPost();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Job Request",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      body: Column(
        children: [
          // উপরের অংশ স্ক্রলেবল
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWorkerHeader(w),
                  const SizedBox(height: 16),
                  _buildInfoText(),
                  const SizedBox(height: 16),
                  _buildSubscriberSection(),
                  const SizedBox(height: 12),
                  _buildFreeUserSection(),
                ],
              ),
            ),
          ),

          // নিচের ফিক্সড CTA
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View full profile
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkerProfileScreen(worker: w),
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
                    child: const Text(
                      "VIEW FULL PROFILE",
                      style: TextStyle(
                        color: AppColors.brandMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Main CTA
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubscriber
                        ? _goToSupportPost
                        : _handleWatchAdAndPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isWatchingAd
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : Text(
                      _isSubscriber
                          ? "POST JOB NOW"
                          : "WATCH AD & POST JOB",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  // -------- Worker summary card ----------
  Widget _buildWorkerHeader(Worker w) {
    final String ratingText = w.rating.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            backgroundImage: NetworkImage(w.image),
            backgroundColor: AppColors.brandLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
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
                  w.role.toUpperCase(),
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
                        w.location,
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
                w.price,
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

  // -------- Info text ----------
  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Text(
        "You are about to post a job request for this worker.\n\n"
            "• Subscribers can post jobs instantly, without any ads.\n"
            "• Free users need to watch a short ad before posting a job.",
        style: TextStyle(fontSize: 12, height: 1.5),
      ),
    );
  }

  // -------- Subscriber section ----------
  Widget _buildSubscriberSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSubscriber
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
          _isSubscriber ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: _isSubscriber ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSubscriber
                  ? "You are a FINDUS Subscriber.\nYou can post jobs instantly without ads."
                  : "Subscribe to FINDUS Premium to post jobs instantly and remove ads.",
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // TODO: Subscription screen এ নেবে
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                  Text("Subscription flow coming soon (demo)."),
                ),
              );
            },
            child: const Text(
              "UPGRADE",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandMain),
            ),
          ),
        ],
      ),
    );
  }

  // -------- Free user (Ad) section ----------
  Widget _buildFreeUserSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.ondemand_video, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSubscriber
                  ? "As a subscriber, you don’t need to watch ads to post jobs."
                  : "Watch a 30 seconds rewarded ad to unlock this job post.",
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
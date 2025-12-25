import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';

class TeamMemberDashboardScreen extends StatelessWidget {
  final TeamMember member;

  const TeamMemberDashboardScreen({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${member.name.split(' ').first}'s Dashboard"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // উপরে প্রোফাইল কার্ড
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // Summary cards (jobs, earnings, rating)
            _buildSummaryCards(),

            const SizedBox(height: 16),

            // নিচে future সেকশন রাখার প্লেসহোল্ডার
            const Text(
              "Recent Activity (demo)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                "Here you can show this member's recent jobs, ratings, "
                    "and other detailed stats (later with real data).",
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brandDark,
            child: Text(
              member.name.isNotEmpty
                  ? member.name[0].toUpperCase()
                  : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  member.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Role: ${member.role.toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "Completed",
            value: member.jobsCompleted.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: "In Progress",
            value: member.jobsInProgress.toString(),
            icon: Icons.work_outline,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            title: "Rating",
            value: member.rating.toStringAsFixed(1),
            icon: Icons.star,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
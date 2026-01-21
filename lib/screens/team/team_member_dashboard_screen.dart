// lib/screens/team/team_member_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ফোন কলের জন্য (অপশনাল)
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';

class TeamMemberDashboardScreen extends StatelessWidget {
  final TeamMember member;

  const TeamMemberDashboardScreen({
    super.key,
    required this.member,
  });

  // নাম সেইফলি হ্যান্ডেল করার জন্য
  String get _displayName {
    if (member.name.isEmpty) return "Member";
    return member.name.split(' ').first;
  }

  // ফোন কল লঞ্চার (সহজ ইমপ্লিমেন্টেশন)
  void _makeCall(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: member.phone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch dialer")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("$_displayName's Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandDark,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. প্রোফাইল হেডার এবং অ্যাকশন বাটন
            _buildProfileHeader(context),

            const SizedBox(height: 20),

            // ২. আর্নিং কার্ড (মডেল আপডেটের পর এটি এখন গুরুত্বপূর্ণ)
            _buildEarningsCard(),

            const SizedBox(height: 12),

            // ৩. স্ট্যাটাস গ্রিড (Completed, Active, Rating)
            _buildStatsRow(),

            const SizedBox(height: 24),

            // ৪. রিসেন্ট অ্যাক্টিভিটি (মক লিস্ট)
            Text(
              "Recent Jobs",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'avatar_${member.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: member.role == 'manager'
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: member.role == 'manager'
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandMain.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.call,
                label: "Call",
                color: Colors.green,
                onTap: () => _makeCall(context),
              ),
              _buildActionButton(
                icon: Icons.message,
                label: "Message",
                color: Colors.blue,
                onTap: () {
                  // TODO: Implement Chat or SMS
                },
              ),
              _buildActionButton(
                icon: Icons.edit_note,
                label: "Edit Role",
                color: Colors.orange,
                onTap: () {
                  // TODO: Show Edit Dialog
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain, AppColors.brandMain.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Earnings",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "৳${member.totalEarnings.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (member.joinedAt != null)
            Text(
              "Since: ${_formatDate(member.joinedAt!)}",
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "Completed",
            value: member.jobsCompleted.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "Active Jobs",
            value: member.jobsInProgress.toString(),
            icon: Icons.timelapse,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: "Rating",
            value: member.rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    // Demo Activity Data (পরবর্তীতে Firestore থেকে আসবে)
    final activities = [
      {"title": "Fixing AC Unit", "status": "Completed", "amount": "৳1,200", "date": "Today, 10:00 AM"},
      {"title": "Plumbing Work", "status": "In Progress", "amount": "---", "date": "Yesterday, 4:30 PM"},
      {"title": "Wiring Check", "status": "Completed", "amount": "৳500", "date": "12 Oct, 11:00 AM"},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final item = activities[index];
        final isCompleted = item['status'] == "Completed";

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.timer,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              item['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              "${item['date']} • ${item['status']}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              item['amount']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted ? AppColors.brandMain : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  // Simple Date Formatter (No external package needed for simple case)
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';
import 'package:findus_app/widgets/floating_scaffold.dart'; // ✅ Added FloatingScaffold

class TeamMemberDashboardScreen extends StatelessWidget {
  final TeamMember member;

  const TeamMemberDashboardScreen({
    super.key,
    required this.member,
  });

  String get _displayName {
    if (member.name.isEmpty) return "Member";
    return member.name.split(' ').first;
  }

  void _makeCall(BuildContext context) async {
    final Uri launchUri = Uri(scheme: 'tel', path: member.phone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialer")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Theme & Color Constants (Consistent with TeamManagementScreen)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return FloatingScaffold(
      title: "${_displayName.toUpperCase()}'S DASHBOARD", // Uppercase style
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: true, // Body scrollable
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header
          _buildProfileHeader(context, isDark, cardColor, titleColor, subTextColor),

          const SizedBox(height: 20),

          // 2. Earnings Card
          _buildEarningsCard(isDark),

          const SizedBox(height: 16),

          // 3. Status Grid
          _buildStatsRow(isDark, cardColor, titleColor, subTextColor),

          const SizedBox(height: 24),

          // 4. Recent Activity Title
          Text(
            "Recent Jobs",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // 5. Activity List
          _buildRecentActivityList(isDark, cardColor, titleColor, subTextColor),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'avatar_${member.id}',
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: member.role == 'manager'
                      ? (isDark ? Colors.orange.shade900 : Colors.orange.shade100)
                      : (isDark ? Colors.blue.shade900 : Colors.blue.shade100),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: member.role == 'manager'
                          ? (isDark ? Colors.orange.shade100 : Colors.orange.shade800)
                          : (isDark ? Colors.blue.shade100 : Colors.blue.shade800),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandMain.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandMain,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.call_rounded,
                label: "Call",
                color: Colors.green,
                onTap: () => _makeCall(context),
                isDark: isDark,
              ),
              _buildActionButton(
                icon: Icons.message_rounded,
                label: "Message",
                color: Colors.blue,
                onTap: () {}, // TODO
                isDark: isDark,
              ),
              _buildActionButton(
                icon: Icons.edit_note_rounded,
                label: "Edit Role",
                color: Colors.orange,
                onTap: () {}, // TODO
                isDark: isDark,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEarningsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain,
            isDark ? const Color(0xFF005F99) : AppColors.brandMain.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Earnings",
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.currency_exchange, color: Colors.white, size: 16),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "৳${member.totalEarnings.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
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

  Widget _buildStatsRow(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "Completed",
            value: member.jobsCompleted.toString(),
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            isDark: isDark, cardColor: cardColor, titleColor: titleColor, subTextColor: subTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: "Active Jobs",
            value: member.jobsInProgress.toString(),
            icon: Icons.timelapse_rounded,
            color: Colors.orange,
            isDark: isDark, cardColor: cardColor, titleColor: titleColor, subTextColor: subTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: "Rating",
            value: member.rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: Colors.amber,
            isDark: isDark, cardColor: cardColor, titleColor: titleColor, subTextColor: subTextColor,
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
    required bool isDark,
    required Color cardColor,
    required Color titleColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 11,
                color: subTextColor,
                fontWeight: FontWeight.w600
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              item['title']!,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "${item['date']} • ${item['status']}",
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            ),
            trailing: Text(
              item['amount']!,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isCompleted ? AppColors.brandMain : Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
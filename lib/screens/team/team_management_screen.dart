import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';
import 'package:findus_app/screens/team/team_member_dashboard_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  // ডেমো ডাটা (পরে API দিয়ে আনবে)
  final List<TeamMember> _members = [
    TeamMember(
      id: "u_1",
      name: "Rahim",
      phone: "+8801XXXXXXXXX",
      role: "manager",
      isPending: false,
      jobsCompleted: 45,
      jobsInProgress: 3,
      totalEarnings: 120000,
      rating: 4.8,
    ),
    TeamMember(
      id: "u_2",
      name: "Karim",
      phone: "+8801YYYYYYYYY",
      role: "staff",
      isPending: true,
      jobsCompleted: 10,
      jobsInProgress: 1,
      totalEarnings: 30000,
      rating: 4.5,
    ),
  ];

  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = "staff";

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _inviteMember() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter phone number."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _members.add(
        TeamMember(
          id: "pending_${_members.length + 1}",
          name: phone, // ডেমো হিসেবে ফোনকে নাম রাখছি
          phone: phone,
          role: _selectedRole,
          isPending: true,
          jobsCompleted: 0,
          jobsInProgress: 0,
          totalEarnings: 0,
          rating: 0,
        ),
      );
      _phoneController.clear();
    });

    // TODO: Backend এ invite API কল করবে এখানে

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invite sent to $phone."),
        backgroundColor: AppColors.brandMain,
      ),
    );
  }

  void _removeMember(TeamMember member) {
    setState(() {
      _members.removeWhere((m) => m.id == member.id);
    });
    // TODO: Backend এ remove API কল করবে
  }

  // ---------- Team summary হিসাব ----------

  int get _totalCompleted => _members.fold<int>(0, (sum, m) {
    final int completed = (m.jobsCompleted ?? 0).toInt();
    return sum + completed;
  });

  int get _totalInProgress => _members.fold<int>(0, (sum, m) {
    final int running = (m.jobsInProgress ?? 0).toInt();
    return sum + running;
  });

  int get _pendingMembers =>
      _members.where((m) => m.isPending == true).length;

  int get _totalEarnings => _members.fold<int>(0, (sum, m) {
    final int earn = (m.totalEarnings ?? 0).toInt();
    return sum + earn;
  });

  double get _avgRating {
    final ratings = _members
        .where((m) => m.isPending != true) // pending বাদ দিয়ে
        .map((m) => (m.rating ?? 0).toDouble())
        .where((r) => r > 0);
    if (ratings.isEmpty) return 0;
    final double total = ratings.fold<double>(0.0, (s, r) => s + r);
    return total / ratings.length;
  }

  void _showTeamDashboard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Team dashboard",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statChip(
                    label: "Completed",
                    value: _totalCompleted.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    label: "Running work",
                    value: _totalInProgress.toString(),
                    icon: Icons.work_outline,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statChip(
                    label: "Total earn",
                    value: "৳$_totalEarnings",
                    icon: Icons.currency_exchange,
                    color: AppColors.brandMain,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    label: "Avg rating",
                    value: _avgRating.toStringAsFixed(1),
                    icon: Icons.star_rate_rounded,
                    color: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statChip(
                    label: "Pending members",
                    value: _pendingMembers.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    label: "Team size",
                    value: _members.length.toString(),
                    icon: Icons.group_outlined,
                    color: AppColors.brandDark,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.brandDark,
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue, // 🔹 body bg color
      appBar: AppBar(
        title: const Text(
          "Team Management",
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
          // Invite form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Invite a team member",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: "manager",
                          child: Text("Manager"),
                        ),
                        DropdownMenuItem(
                          value: "staff",
                          child: Text("Staff"),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedRole = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _inviteMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                    ),
                    child: const Text(
                      "SEND INVITE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // Team list
          Expanded(
            child: _members.isEmpty
                ? const Center(
              child: Text("No team members added yet."),
            )
                : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (ctx, i) {
                final m = _members[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.role == "manager"
                        ? Colors.orange
                        : Colors.blue,
                    child: Text(
                      m.name.isNotEmpty
                          ? m.name[0].toUpperCase()
                          : "?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(m.name),
                  subtitle: Text(
                    "${m.phone}\nRole: ${m.role.toUpperCase()}${m.isPending ? " (Pending)" : ""}",
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ছোট dashboard আইকন
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TeamMemberDashboardScreen(
                                    member: m,
                                  ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.dashboard,
                          color: AppColors.brandMain,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ছোট delete আইকন
                      GestureDetector(
                        onTap: () => _removeMember(m),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Floating dashboard button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTeamDashboard,
        backgroundColor: AppColors.brandMain,
        icon: const Icon(Icons.dashboard_customize),
        label: const Text(
          "Team stats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
    );
  }
}
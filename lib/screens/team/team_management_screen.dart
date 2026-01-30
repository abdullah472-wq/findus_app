import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';
import 'package:findus_app/screens/team/team_member_dashboard_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart'; // ✅ Added this import

class TeamManagementScreen extends StatefulWidget {
  final String userId; // Business Owner's UID

  const TeamManagementScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedRole = "staff";
  bool _isInviting = false;

  // Firestore reference helper
  CollectionReference get _teamCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('team_members');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _inviteMember() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isInviting = true);

    final phone = _phoneController.text.trim();

    try {
      // 1. Check duplicate
      final existingCheck = await _teamCollection.where('phone', isEqualTo: phone).get();
      if (existingCheck.docs.isNotEmpty) {
        throw "This member is already in your team.";
      }

      // 2. Check User Existence (Fetch Name)
      String memberName = "Invited User";
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        memberName = userData['name'] ?? "Invited User";
      }

      // 3. Add to Firestore
      final newMember = TeamMember(
        id: '',
        name: memberName,
        phone: phone,
        role: _selectedRole,
        isPending: true,
        joinedAt: DateTime.now(),
      );

      await _teamCollection.add(newMember.toMap());

      if (mounted) {
        _phoneController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invitation sent successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _confirmRemoveMember(TeamMember member) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Member?"),
        content: Text("Are you sure you want to remove ${member.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _teamCollection.doc(member.id).delete();
    }
  }

  // --- Calculations ---

  Map<String, dynamic> _calculateStats(List<TeamMember> members) {
    int totalCompleted = 0;
    int totalInProgress = 0;
    double totalEarnings = 0.0;
    double totalRating = 0.0;
    int ratedMembers = 0;
    int pendingCount = 0;

    for (var m in members) {
      if (m.isPending) {
        pendingCount++;
      } else {
        totalCompleted += m.jobsCompleted;
        totalInProgress += m.jobsInProgress;
        totalEarnings += m.totalEarnings;
        if (m.rating > 0) {
          totalRating += m.rating;
          ratedMembers++;
        }
      }
    }
    double avgRating = ratedMembers > 0 ? totalRating / ratedMembers : 0.0;

    return {
      'completed': totalCompleted,
      'inProgress': totalInProgress,
      'earnings': totalEarnings.toStringAsFixed(2),
      'avgRating': avgRating,
      'pending': pendingCount,
      'size': members.length,
    };
  }

  // --- UI Builders ---

  void _showTeamDashboard(List<TeamMember> members, bool isDark) {
    final stats = _calculateStats(members);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : AppColors.bgBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _DashboardBottomSheet(stats: stats, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme Constants
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.black54;

    // ✅ Using FloatingScaffold exactly like AdCenter
    return FloatingScaffold(
      title: "TEAM MANAGEMENT",
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      // 'scrollable: false' রাখা হয়েছে যাতে আমরা বডির ভেতর ListView ব্যবহার করতে পারি (Invite Section ফিক্সড থাকবে না, স্ক্রল করবে লিস্টের সাথে)
      scrollable: false,
      bodyPadding: EdgeInsets.zero, // আমরা কাস্টম প্যাডিং দেব
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Invite Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInviteSection(isDark, cardColor, titleColor, subTextColor),
          ),

          const SizedBox(height: 10),

          // Member List (Expanded to take remaining space)
          Expanded(
            child: _buildTeamList(isDark, cardColor, titleColor, subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteSection(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
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
          )
        ],
        border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandMain.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.brandMain, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  "Invite Member",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: titleColor),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (val.length < 11) return 'Invalid phone';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Phone (017...)",
                      hintStyle: TextStyle(color: subTextColor),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        dropdownColor: cardColor,
                        style: TextStyle(color: titleColor),
                        items: const [
                          DropdownMenuItem(value: "manager", child: Text("Manager")),
                          DropdownMenuItem(value: "staff", child: Text("Staff")),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isInviting ? null : _inviteMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isInviting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SEND INVITATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _teamCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: titleColor)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data?.docs ?? [];
        final List<TeamMember> members = data
            .map((doc) => TeamMember.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 60, color: subTextColor),
                const SizedBox(height: 10),
                Text("No team members yet.", style: TextStyle(color: subTextColor)),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Bottom padding for FAB
              itemCount: members.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                return _TeamMemberTile(
                  member: members[i],
                  isDark: isDark,
                  cardColor: cardColor,
                  titleColor: titleColor,
                  subTextColor: subTextColor,
                  onTapDashboard: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeamMemberDashboardScreen(member: members[i])),
                  ),
                  onTapRemove: () => _confirmRemoveMember(members[i]),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showTeamDashboard(members, isDark),
                backgroundColor: AppColors.brandMain,
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                label: const Text("TEAM STATS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                elevation: 4,
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Extracted Widgets ---

class _TeamMemberTile extends StatelessWidget {
  final TeamMember member;
  final bool isDark;
  final Color cardColor;
  final Color titleColor;
  final Color subTextColor;
  final VoidCallback onTapDashboard;
  final VoidCallback onTapRemove;

  const _TeamMemberTile({
    required this.member,
    required this.isDark,
    required this.cardColor,
    required this.titleColor,
    required this.subTextColor,
    required this.onTapDashboard,
    required this.onTapRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isManager = member.role == "manager";
    final Color roleColor = isManager ? Colors.orange : Colors.blue;

    return Container(
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
        border: Border.all(color: roleColor.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          foregroundColor: roleColor,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          member.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.phone, style: TextStyle(color: subTextColor, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatusBadge(text: member.role.toUpperCase(), color: roleColor),
                const SizedBox(width: 8),
                if (member.isPending)
                  const _StatusBadge(text: "PENDING", color: Colors.amber),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.dashboard_rounded, color: AppColors.brandMain),
              onPressed: onTapDashboard,
              tooltip: "View Stats",
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              onPressed: onTapRemove,
              tooltip: "Remove",
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

class _DashboardBottomSheet extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isDark;

  const _DashboardBottomSheet({
    required this.stats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Team Performance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _StatChip(
                label: "Completed",
                value: stats['completed'].toString(),
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: "Running",
                value: stats['inProgress'].toString(),
                icon: Icons.timelapse_rounded,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: "Earnings",
                value: "৳${stats['earnings']}",
                icon: Icons.monetization_on_rounded,
                color: AppColors.brandMain,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: "Avg Rating",
                value: stats['avgRating'].toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: Colors.amber,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: "Pending",
                value: stats['pending'].toString(),
                icon: Icons.pending_rounded,
                color: Colors.redAccent,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: "Total Staff",
                value: stats['size'].toString(),
                icon: Icons.people_alt_rounded,
                color: textColor,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF383838) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.brandDark,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
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
}
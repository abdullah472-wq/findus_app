import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/team_member.dart';
import 'package:findus_app/models/team_invitation.dart';
import 'package:findus_app/services/team_service.dart';
import 'package:findus_app/screens/team/team_member_dashboard_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class TeamManagementScreen extends StatefulWidget {
  final String userId;

  const TeamManagementScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  late TabController _tabController;

  String _selectedRole = "staff";
  bool _isInviting = false;

  CollectionReference get _teamCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('team_members');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📨 SEND INVITATION (NEW - Request Based)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isInviting = true);

    final phone = _phoneController.text.trim();

    try {
      final result = await TeamService.sendInvitation(
        toPhone: phone,
        role: _selectedRole,
      );

      if (mounted) {
        if (result['success'] == true) {
          _phoneController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invitation sent!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send invitation'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _cancelInvitation(TeamInvitation invitation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Invitation?"),
        content: Text("Cancel invitation to ${invitation.toUserName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Cancel Invitation"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await TeamService.cancelInvitation(invitation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Invitation cancelled" : "Failed to cancel"),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Member?"),
        content: Text("Remove ${member.name} from your team?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
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

      // Also remove from member's my_teams
      if (member.userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(member.userId)
            .collection('my_teams')
            .doc(widget.userId)
            .delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return FloatingScaffold(
      title: "TEAM MANAGEMENT",
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Invite Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInviteSection(isDark, cardColor, titleColor, subTextColor),
          ),

          const SizedBox(height: 16),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.brandMain,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: subTextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "MEMBERS"),
                Tab(text: "PENDING"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Team Members
                _buildTeamMembersList(isDark, cardColor, titleColor, subTextColor),

                // Tab 2: Pending Invitations
                _buildPendingInvitations(isDark, cardColor, titleColor, subTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📝 INVITE SECTION
  // ════════════════════════════════════════════════════════════════════════════

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
                  "Send Invitation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "User will receive an invitation request. They must accept to join.",
              style: TextStyle(fontSize: 12, color: subTextColor),
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
              child: ElevatedButton.icon(
                onPressed: _isInviting ? null : _sendInvitation,
                icon: _isInviting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isInviting ? "SENDING..." : "SEND INVITATION",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 👥 TEAM MEMBERS LIST
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTeamMembersList(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _teamCollection.orderBy('joinedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final members = docs
            .map((doc) => TeamMember.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 60, color: subTextColor),
                const SizedBox(height: 10),
                Text("No team members yet", style: TextStyle(color: subTextColor)),
                const SizedBox(height: 8),
                Text(
                  "Send invitations to add members",
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            return _TeamMemberTile(
              member: members[i],
              isDark: isDark,
              cardColor: cardColor,
              titleColor: titleColor,
              subTextColor: subTextColor,
              onTapDashboard: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamMemberDashboardScreen(member: members[i]),
                ),
              ),
              onTapRemove: () => _confirmRemoveMember(members[i]),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⏳ PENDING INVITATIONS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPendingInvitations(bool isDark, Color cardColor, Color titleColor, Color subTextColor) {
    return StreamBuilder<List<TeamInvitation>>(
      stream: TeamService.getMySentInvitations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final invitations = snapshot.data ?? [];
        final pending = invitations.where((i) => i.isPending).toList();

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 60, color: subTextColor),
                const SizedBox(height: 10),
                Text("No pending invitations", style: TextStyle(color: subTextColor)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final inv = pending[i];
            return _PendingInvitationTile(
              invitation: inv,
              isDark: isDark,
              cardColor: cardColor,
              titleColor: titleColor,
              subTextColor: subTextColor,
              onCancel: () => _cancelInvitation(inv),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 📦 WIDGETS
// ════════════════════════════════════════════════════════════════════════════

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
    final isManager = member.role == "manager";
    final roleColor = isManager ? Colors.orange : Colors.blue;

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
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.phone, style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatusBadge(text: member.role.toUpperCase(), color: roleColor),
                const SizedBox(width: 8),
                _StatusBadge(
                  text: "${member.jobsCompleted} JOBS",
                  color: Colors.green,
                ),
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

class _PendingInvitationTile extends StatelessWidget {
  final TeamInvitation invitation;
  final bool isDark;
  final Color cardColor;
  final Color titleColor;
  final Color subTextColor;
  final VoidCallback onCancel;

  const _PendingInvitationTile({
    required this.invitation,
    required this.isDark,
    required this.cardColor,
    required this.titleColor,
    required this.subTextColor,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.1),
          child: const Icon(Icons.hourglass_empty, color: Colors.amber),
        ),
        title: Text(
          invitation.toUserName.isNotEmpty ? invitation.toUserName : invitation.toUserPhone,
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(invitation.toUserPhone, style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatusBadge(text: invitation.role.toUpperCase(), color: Colors.blue),
                const SizedBox(width: 8),
                const _StatusBadge(text: "PENDING", color: Colors.amber),
              ],
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("CANCEL"),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
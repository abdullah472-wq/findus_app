// lib/screens/tabs/save_screen.dart
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  List<Map<String, dynamic>> _getSavedWorkersByRole(List<String> roles) {
    return SavedService.savedWorkers.where((worker) {
      final workerRole = (worker['role'] ?? '').toString().toUpperCase();
      return roles.any((role) => workerRole.contains(role.toUpperCase()));
    }).toList();
  }

  String _getUserId(Map<String, dynamic> data) {
    // Robust ID extraction
    return (data['userId'] ?? data['id'] ?? '').toString().trim();
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: 'SAVED PROFILES',
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: SavedService.savedWorkers.isEmpty
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(15),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCategory(
            title: "FARMER & GARDENER",
            color: isDark ? const Color(0xFF2C2C2C) : Colors.cyan.shade50,
            icon: Icons.agriculture,
            roles: ['FARMER', 'GARDEN', 'কৃষক'],
            isDark: isDark,
          ),
          _buildCategory(
            title: "PAINTERS",
            color: isDark ? const Color(0xFF2C2C2C) : Colors.orange.shade50,
            icon: Icons.format_paint,
            roles: ['PAINTER', 'COLOR', 'রং'],
            isDark: isDark,
          ),
          _buildCategory(
            title: "SHOPPERS",
            color: isDark ? const Color(0xFF2C2C2C) : Colors.green.shade50,
            icon: Icons.shopping_cart,
            roles: ['SHOPPER', 'BAZAR', 'বাজার', 'DELIVERY'],
            isDark: isDark,
          ),
          _buildCategory(
            title: "RIKSHAW & DRIVERS",
            color: isDark ? const Color(0xFF2C2C2C) : Colors.purple.shade50,
            icon: Icons.directions_bike,
            roles: ['RICKSHAW', 'DRIVER', 'রিকশা', 'গাড়ি'],
            isDark: isDark,
          ),
          _buildCategory(
            title: "OTHERS",
            color: isDark ? const Color(0xFF2C2C2C) : Colors.blueGrey.shade50,
            icon: Icons.more_horiz,
            roles: const [],
            isOther: true,
            isDark: isDark,
          ),
          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildCategory({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> roles,
    required bool isDark,
    bool isOther = false,
  }) {
    List<Map<String, dynamic>> workers;

    if (isOther) {
      final usedRoles = ['FARMER', 'GARDEN', 'PAINTER', 'COLOR', 'SHOPPER', 'BAZAR', 'RICKSHAW', 'DRIVER'];
      workers = SavedService.savedWorkers.where((w) {
        final r = (w['role'] ?? '').toString().toUpperCase();
        return !usedRoles.any((ur) => r.contains(ur));
      }).toList();
    } else {
      workers = _getSavedWorkersByRole(roles);
    }

    if (workers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandMain, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.brandDark,
              letterSpacing: 0.5,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandMain,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              workers.length.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          children: workers.map((data) => _buildWorkerCard(data)).toList(),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> data) {
    final workerId = _getUserId(data);
    final name = (data['name'] ?? 'User').toString();
    final role = (data['role'] ?? 'Worker').toString();
    final image = (data['image'] ?? '').toString();

    return UniversalWorkerCard(
      id: workerId,
      name: name,
      role: role,
      imageUrl: image,
      address: (data['location'] ?? 'Bangladesh').toString(),
      rating: _asDouble(data['rating'], fallback: 4.8).toStringAsFixed(1),
      completed: _asInt(data['completed']).toString(),
      reviews: _asInt(data['reviews']).toString(),
      price: (data['price'] ?? 'Negotiable').toString(),
      isVerifiedWorker: data['isVerified'] == true,
      followersCount: _asInt(data['followersCount']),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      // ✅ Card Tap -> Open Profile
      onTap: () {
        if (workerId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: workerId, isOwner: false)),
        );
      },

      // ✅ View Profile Button -> Open Profile
      onViewProfileTap: () {
        if (workerId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: workerId, isOwner: false)),
        );
      },

      // ✅ Chat Button -> Open Chat
      onChatTap: () async {
        if (workerId.isEmpty) return;
        _showLoading();
        try {
          final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: workerId);
          if (!mounted) return;
          Navigator.pop(context); // Close loading
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: convId,
                userName: name,
                userRole: role,
                userImage: image,
              ),
            ),
          );
        } catch (_) {
          if (mounted) Navigator.pop(context); // Close loading on error
        }
      },

      // ✅ Save Button -> Remove from Save
      isSaved: true,
      onSaveTap: () async {
        await SavedService.toggleSave(data);
        setState(() {}); // Refresh UI
      },
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 15),
          Text(
            "No saved profiles yet",
            style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
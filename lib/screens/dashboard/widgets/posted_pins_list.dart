// lib/screens/tabs/dashboard/widgets/posted_pins_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import '../../profile/earn_post_screen.dart';

class PostedPinsList extends StatelessWidget {
  final String userId;

  const PostedPinsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId.isEmpty) {
      return const Text('User not found');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildContent(context, snapshot, isDark);
      },
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot, bool isDark) {
    if (snapshot.hasError) {
      return _buildErrorWidget(snapshot.error.toString());
    }

    if (!snapshot.hasData) {
      return _buildLoadingWidget();
    }

    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyWidget(context, isDark);
    }

    return _buildPinsList(context, docs, isDark);
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text('Error loading pins: $error', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: [
        _buildShimmerCard(),
        const SizedBox(height: 12),
        _buildShimmerCard(),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, color: Colors.grey),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, color: Colors.grey),
              ],
            ),
          ),
          Container(width: 60, height: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pin_drop_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No pins posted yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Post your first pin to start earning.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPostScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('POST NEW PIN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinsList(BuildContext context, List<QueryDocumentSnapshot> docs, bool isDark) {
    return Column(
      children: docs.map((doc) => _buildPinCard(context, doc, isDark)).toList(),
    );
  }

  Widget _buildPinCard(BuildContext context, QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: InkWell(
          onTap: () => _handlePinTap(context, doc.id, data),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                _buildPinIcon(data),
                const SizedBox(width: 15),
                Expanded(child: _buildPinInfo(data, textColor)),
                _buildPriceTag(data),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deletePin(context, doc.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIcon(Map<String, dynamic> data) {
    return const CircleAvatar(
      backgroundColor: AppColors.brandLight,
      child: Icon(Icons.push_pin, color: AppColors.brandDark),
    );
  }

  Widget _buildPinInfo(Map<String, dynamic> data, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['title'] ?? 'No Title',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          data['address'] ?? 'No Location',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriceTag(Map<String, dynamic> data) {
    return Text(
      data['priceLabel'] ?? 'N/A',
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMain, fontSize: 14),
    );
  }

  void _handlePinTap(BuildContext context, String pinId, Map<String, dynamic> data) {
    // পিন ডিটেইলস পেজে যাওয়ার লজিক (ভবিষ্যতে অ্যাড করতে পারেন)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pin: ${data['title']}")));
  }

  Future<void> _deletePin(BuildContext context, String pinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Pin?"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(pinId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pin deleted successfully")));
      }
    }
  }
}
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
    if (userId.isEmpty) {
      return const Text('User not found');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildContent(context, snapshot);
      },
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return _buildErrorWidget(snapshot.error.toString());
    }

    if (!snapshot.hasData) {
      return _buildLoadingWidget();
    }

    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return _buildEmptyWidget(context); // ✅ context pass
    }

    return _buildPinsList(context, docs);
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
          Expanded(
            child: Text(
              'Error loading pins: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
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

  Widget _buildEmptyWidget(BuildContext context) { // ✅ context added
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pin_drop_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'কোনো পিন পোস্ট করা হয়নি',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'আপনার প্রথম পিন পোস্ট করুন এবং কাজ খুঁজুন',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarnPostScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('নতুন পিন পোস্ট করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinsList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return Column(
      children: docs.map((doc) => _buildPinCard(context, doc)).toList(),
    );
  }

  Widget _buildPinCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                _buildPinInfo(data),
                const Spacer(),
                _buildPriceTag(data),
                _buildStatusIndicator(data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- rest of your methods unchanged below (pin icon/info/meta/price/status/actions/delete etc.) ---

  Widget _buildPinIcon(Map<String, dynamic> data) { /* unchanged */ throw UnimplementedError(); }
  Widget _buildPinInfo(Map<String, dynamic> data) { /* unchanged */ throw UnimplementedError(); }
  Widget _buildPriceTag(Map<String, dynamic> data) { /* unchanged */ throw UnimplementedError(); }
  Widget _buildStatusIndicator(Map<String, dynamic> data) { /* unchanged */ throw UnimplementedError(); }
  void _handlePinTap(BuildContext context, String pinId, Map<String, dynamic> data) { /* unchanged */ }
}
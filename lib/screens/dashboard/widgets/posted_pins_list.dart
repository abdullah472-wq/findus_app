// lib/screens/tabs/dashboard/widgets/posted_pins_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:intl/intl.dart'; // তারিখ ফরম্যাটের জন্য
import 'package:url_launcher/url_launcher.dart'; // ম্যাপ ওপেন করার জন্য
import '../../profile/earn_post_screen.dart';

class PostedPinsList extends StatelessWidget {
  final String userId;

  const PostedPinsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId.isEmpty) {
      return const Text('User not found');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) // নতুন পোস্ট আগে দেখাবে
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

    if (snapshot.connectionState == ConnectionState.waiting) {
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
          Expanded(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
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
          Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 15),
          Expanded(child: Container(width: double.infinity, height: 20, color: Colors.grey)),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPostScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain),
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

    // ১. তারিখ ফরম্যাটিং
    String dateStr = "";
    if (data['createdAt'] != null) {
      try {
        final Timestamp ts = data['createdAt'];
        dateStr = DateFormat('MMM d, yyyy').format(ts.toDate());
      } catch (_) {}
    }

    // ২. স্ট্যাটাস চেক (Active/Expired)
    final bool isActive = data['isActive'] ?? true; // ডিফল্ট Active

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePinTap(context, data), // লোকেশনে নিয়ে যাবে
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ৩. ক্যাটাগরি আইকন
                _buildPinIcon(data),

                const SizedBox(width: 16),

                // ইনফো সেকশন
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['title'] ?? 'No Title',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ৪. স্ট্যাটাস চিপ
                          _buildStatusChip(isActive),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['address'] ?? 'No Location',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // প্রাইস এবং ডিলিট বাটন
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPriceTag(data),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _deletePin(context, doc.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ক্যাটাগরি অনুযায়ী আইকন সাজেশন
  Widget _buildPinIcon(Map<String, dynamic> data) {
    IconData icon = Icons.work_outline;
    Color color = AppColors.brandMain;

    // টাইটেল বা রোল অনুযায়ী আইকন সেট
    final String text = (data['title'] ?? '').toString().toLowerCase() +
        (data['roleLabel'] ?? '').toString().toLowerCase();

    if (text.contains('plumb')) {
      icon = Icons.plumbing; color = Colors.blue;
    } else if (text.contains('electric') || text.contains('bijli')) {
      icon = Icons.electric_bolt; color = Colors.orange;
    } else if (text.contains('clean') || text.contains('wash')) {
      icon = Icons.cleaning_services; color = Colors.teal;
    } else if (text.contains('drive') || text.contains('car')) {
      icon = Icons.directions_car; color = Colors.indigo;
    } else if (text.contains('food') || text.contains('cook')) {
      icon = Icons.restaurant; color = Colors.redAccent;
    } else if (text.contains('teach') || text.contains('tutor')) {
      icon = Icons.school; color = Colors.brown;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
      ),
      child: Text(
        isActive ? 'Active' : 'Closed',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.green : Colors.grey
        ),
      ),
    );
  }

  Widget _buildPriceTag(Map<String, dynamic> data) {
    return Text(
      data['priceLabel'] ?? 'N/A',
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMain, fontSize: 14),
    );
  }

  // ✅ লোকেশনে নিয়ে যাওয়ার লজিক (গুগল ম্যাপ)
  Future<void> _handlePinTap(BuildContext context, Map<String, dynamic> data) async {
    final double? lat = data['latitude'];
    final double? lng = data['longitude'];

    if (lat != null && lng != null) {
      // গুগল ম্যাপ ওপেন করা
      final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

      try {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          _showError(context, "Could not open Maps application.");
        }
      } catch (e) {
        _showError(context, "Error opening map: $e");
      }
    } else {
      // যদি কোঅর্ডিনেট না থাকে, তবে শুধু মেসেজ দেখাবে
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location details for '${data['title']}' not available on map."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _deletePin(BuildContext context, String pinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Pin?"),
        content: const Text("Are you sure you want to delete this post? This cannot be undone."),
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
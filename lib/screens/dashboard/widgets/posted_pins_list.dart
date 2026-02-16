// lib/screens/dashboard/widgets/posted_pins_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // ✅ NEW

import '../../profile/earn_post_screen.dart';
import '../../dashboard/my_post_applications_screen.dart'; // ✅ NEW

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
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        return _buildContent(context, snapshot, isDark);
      },
    );
  }

  Widget _buildContent(
      BuildContext context,
      AsyncSnapshot<QuerySnapshot> snapshot,
      bool isDark,
      ) {
    if (snapshot.hasError) {
      final err = snapshot.error.toString();
      final needsIndex = err.contains('FAILED_PRECONDITION') ||
          err.toLowerCase().contains('index');

      return _buildErrorWidget(needsIndex ? 'Index required' : err, needsIndex);
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWidget(isDark);
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
      return _buildEmptyWidget(context, isDark);
    }

    return _buildPinsList(context, docs, isDark);
  }

  Widget _buildErrorWidget(String error, bool isIndexError) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIndexError ? Colors.orange.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIndexError ? Colors.orange.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIndexError ? Icons.build_rounded : Icons.error_outline,
            color: isIndexError ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: isIndexError ? Colors.orange.shade900 : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Column(
      children: [
        _buildShimmerCard(isDark),
        const SizedBox(height: 12),
        _buildShimmerCard(isDark),
      ],
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              width: double.infinity,
              height: 20,
              color: isDark ? Colors.grey[700] : Colors.grey,
            ),
          ),
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
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pin_drop_outlined,
            size: 60,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No pins posted yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by posting your first job',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarnPostScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('POST NEW PIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinsList(
      BuildContext context,
      List<QueryDocumentSnapshot> docs,
      bool isDark,
      ) {
    return Column(
      children: docs.map((doc) {
        return _buildPinCard(context, doc, isDark);
      }).toList(),
    );
  }

  Widget _buildPinCard(
      BuildContext context,
      QueryDocumentSnapshot doc,
      bool isDark,
      ) {
    final data = doc.data() as Map<String, dynamic>;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.grey.shade600;

    // Date formatting
    String dateStr = "";
    if (data['createdAt'] != null) {
      try {
        final Timestamp ts = data['createdAt'];
        dateStr = DateFormat('MMM d, yyyy').format(ts.toDate());
      } catch (_) {}
    }

    // Status
    final bool isActive = data['isActive'] ?? true;
    final int viewCount = data['viewCount'] ?? 0;
    final int applicationsCount = data['applicationsCount'] ?? 0;

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
          onTap: () {
            // ✅ Navigate to applications screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyPostApplicationsScreen(postId: doc.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon
                    _buildPinIcon(data),

                    const SizedBox(width: 16),

                    // Info Section
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(isActive),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: subColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['address'] ?? 'No Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // ✅ Analytics Row
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 12, color: subColor),
                              const SizedBox(width: 4),
                              Text(
                                '$viewCount views',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),

                              const SizedBox(width: 12),

                              Icon(Icons.person, size: 12, color: subColor),
                              const SizedBox(width: 4),
                              Text(
                                '$applicationsCount applied',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),

                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.calendar_today, size: 11, color: subColor),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 10, color: subColor),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Price
                    _buildPriceTag(data, textColor),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // View on Map
                    _ActionButton(
                      icon: Icons.map_outlined,
                      label: 'Map',
                      color: Colors.blue,
                      onTap: () => _handlePinTap(context, data),
                    ),

                    const SizedBox(width: 8),

                    // Share
                    _ActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.green,
                      onTap: () => _sharePin(context, data),
                    ),

                    const SizedBox(width: 8),

                    // Edit
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: Colors.orange,
                      onTap: () => _editPin(context, doc.id, data),
                    ),

                    const SizedBox(width: 8),

                    // Delete
                    _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () => _deletePin(context, doc.id),
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

  Widget _buildPinIcon(Map<String, dynamic> data) {
    IconData icon = Icons.work_outline;
    Color color = AppColors.brandMain;

    final String text = (data['title'] ?? '').toString().toLowerCase() +
        (data['roleLabel'] ?? '').toString().toLowerCase();

    if (text.contains('plumb')) {
      icon = Icons.plumbing;
      color = Colors.blue;
    } else if (text.contains('electric') || text.contains('bijli')) {
      icon = Icons.electric_bolt;
      color = Colors.orange;
    } else if (text.contains('clean') || text.contains('wash')) {
      icon = Icons.cleaning_services;
      color = Colors.teal;
    } else if (text.contains('drive') || text.contains('car')) {
      icon = Icons.directions_car;
      color = Colors.indigo;
    } else if (text.contains('food') || text.contains('cook')) {
      icon = Icons.restaurant;
      color = Colors.redAccent;
    } else if (text.contains('teach') || text.contains('tutor')) {
      icon = Icons.school;
      color = Colors.brown;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Closed',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPriceTag(Map<String, dynamic> data, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          data['priceLabel'] ?? 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.brandMain,
            fontSize: 16,
          ),
        ),
        if (data['priceType'] != null)
          Text(
            data['priceType'].toString(),
            style: TextStyle(
              fontSize: 9,
              color: textColor.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  // ✅ Open location in Google Maps
  Future<void> _handlePinTap(
      BuildContext context,
      Map<String, dynamic> data,
      ) async {
    final double? lat = data['latitude'];
    final double? lng = data['longitude'];

    if (lat != null && lng != null) {
      final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Location for '${data['title']}' not available.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ✅ Share pin
  Future<void> _sharePin(BuildContext context, Map<String, dynamic> data) async {
    final title = data['title'] ?? 'Job Post';
    final address = data['address'] ?? 'Location not set';
    final price = data['priceLabel'] ?? 'N/A';

    final shareText = '''
🔧 $title

📍 Location: $address
💰 Price: $price

Apply now on FindUs App!
''';

    try {
      await Share.share(shareText, subject: title);
    } catch (e) {
      _showError(context, "Failed to share: $e");
    }
  }

  // ✅ Edit pin
  Future<void> _editPin(
      BuildContext context,
      String pinId,
      Map<String, dynamic> data,
      ) async {
    // Option 1: Show coming soon message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Edit feature coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // Option 2: Open existing screen for viewing only
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => const EarnPostScreen(),
    //   ),
    // );
  }

  // ✅ Delete pin
  Future<void> _deletePin(BuildContext context, String pinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Pin?"),
        content: const Text(
          "Are you sure you want to delete this post?\nThis cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(pinId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Pin deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showError(context, "Failed to delete: $e");
        }
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ✅ Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
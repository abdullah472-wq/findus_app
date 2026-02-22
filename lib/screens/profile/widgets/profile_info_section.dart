import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'profile_shimmer_loading.dart';


class ProfileInfoSection extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isWorker;
  final bool isDark;

  const ProfileInfoSection({
    super.key,
    required this.userData,
    required this.isWorker,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Loading check
    final bool isLoading = userData.isEmpty;

    return _buildSection(
      title: isWorker ? 'Work Information' : 'Company Information',
      content: isLoading
          ? _buildLoadingInfo()
          : (isWorker ? _buildWorkerInfo() : _buildSupporterInfo()),
    );
  }

  // ✅ Loading placeholder
  Widget _buildLoadingInfo() {
    return Column(
      children: List.generate(
        3,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Icon placeholder
              MiniShimmerLoading(
                width: 20,
                height: 20,
                isDark: isDark,
              ),

              const SizedBox(width: 16),

              // Label
              MiniShimmerLoading(
                width: 80,
                height: 14,
                isDark: isDark,
              ),

              const Spacer(),

              // Value
              MiniShimmerLoading(
                width: 60,
                height: 14,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWorkerInfo() {
    final expYears = userData['experienceYears'];
    final expLabel = (expYears == null) ? 'New' : '$expYears Years';
    final priceLabel = _safeString(userData['priceText'], 'Negotiable');
    final timeLabel = _safeString(userData['availability'], 'Not Set');

    return Column(
      children: [
        _infoTile(Icons.work, 'Experience', expLabel),
        _infoTile(Icons.payments, 'Rate', priceLabel),
        _infoTile(Icons.access_time, 'Hours', timeLabel),
      ],
    );
  }

  Widget _buildSupporterInfo() {
    return Column(
      children: [
        _infoTile(Icons.business, 'Company', _safeString(userData['companyName'], 'Individual')),
        _infoTile(Icons.phone, 'Contact', _safeString(userData['companyContact'], 'Not Set')),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.brandMain,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppColors.brandMain),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String && value.isEmpty) return defaultValue;
    return value.toString();
  }
}
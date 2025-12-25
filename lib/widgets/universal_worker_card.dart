import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/constants/badge_theme.dart';
import 'package:findus_app/constants/status_theme.dart';
import 'package:findus_app/models/badge_model.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';

class UniversalWorkerCard extends StatelessWidget {
  final String? id; // অন্য ইউজারের আইডি (চ্যাটের জন্য প্রয়োজন)
  final String name;
  final String role;
  final String imageUrl;
  final String address;
  final String rating;
  final String completed;
  final String reviews;
  final String price;
  final String time;
  final String? phoneNumber;
  final EdgeInsetsGeometry margin;
  final int? followersCount;

  final String? facebookUrl;
  final String? emailAddress;

  final int? colorIndex;
  final bool isVerifiedWorker;
  final bool isTopRated;
  final bool isTrusted;
  final bool isEditable;

  final VoidCallback? onTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onViewProfileTap;
  final BadgeLevel? badgeLevel;
  final bool isSaved;
  final VoidCallback? onSaveTap;

  const UniversalWorkerCard({
    super.key,
    this.id, // চ্যাটের জন্য এটি দরকার
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.completed,
    required this.reviews,
    this.price = "Negotiable",
    this.time = "Available Now",
    this.phoneNumber,
    this.facebookUrl,
    this.emailAddress,
    this.isVerifiedWorker = false,
    this.isTopRated = false,
    this.isTrusted = false,
    this.isEditable = false,
    this.onTap,
    this.onChatTap,
    this.onViewProfileTap,
    this.badgeLevel,
    this.colorIndex,
    this.isSaved = false,
    this.onSaveTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    this.followersCount,
  });

  // চ্যাট ওপেন করার হ্যান্ডলার (উইথ লোডিং আইকন)
  Future<void> _handleChatOpen(BuildContext context) async {
    if (id == null || id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found!")),
      );
      return;
    }

    // ১. লোডিং ডায়ালগ দেখানো
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.brandMain),
      ),
    );

    try {
      // ২. কনভারসেশন আইডি জেনারেট করা
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: id!);

      // ৩. লোডিং ডায়ালগ বন্ধ করা
      if (context.mounted) Navigator.pop(context);

      // ৪. চ্যাট স্ক্রিনে পাঠানো
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              userName: name,
              userImage: imageUrl,
              userRole: role,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // এরর হলে লোডিং বন্ধ
      debugPrint("Chat error: $e");
    }
  }

  // ল্যাঞ্চার হেল্পার
  Future<void> _launchUri(BuildContext context, Uri uri, {String errorMessage = 'Could not open.'}) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEmail = emailAddress?.trim().isNotEmpty ?? false;
    final bool hasFacebook = facebookUrl?.trim().isNotEmpty ?? false;
    final bool hasPhone = phoneNumber?.trim().isNotEmpty ?? false;

    final viewProfileCallback = onViewProfileTap ?? onTap;

    final gradients = [
      const [Color(0xFFB2EBF2), Color(0xFFE0F7FA)],
      const [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
      const [Color(0xFFC5CAE9), Color(0xFFE8EAF6)],
      const [Color(0xFFF8BBD0), Color(0xFFFCE4EC)],
    ];
    final cardColors = gradients[(colorIndex ?? 0).clamp(0, 3)];

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cardColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 35, backgroundImage: NetworkImage(imageUrl), backgroundColor: AppColors.brandLight),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadgeRow(),
                    const SizedBox(height: 5),
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                    Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(role, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(price, style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
                      if (onSaveTap != null)
                        IconButton(icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.amber), onPressed: onSaveTap),
                    ],
                  ),
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCol(completed, "COMPLETED", Icons.verified_user_outlined),
              _statCol(rating, "RATING", Icons.star_outline),
              _statCol(reviews, "REVIEWS", Icons.reviews_outlined),
              Row(
                children: [
                  // চ্যাট বাটন
                  IconButton(
                    onPressed: onChatTap ?? () => _handleChatOpen(context),
                    icon: const Icon(Icons.chat, size: 24, color: Colors.blueGrey),
                  ),
                  if (hasPhone)
                    IconButton(onPressed: () => _launchUri(context, Uri.parse("tel:$phoneNumber")), icon: const Icon(Icons.phone, color: Colors.teal)),
                  if (hasFacebook)
                    IconButton(onPressed: () => _launchUri(context, Uri.parse(facebookUrl!)), icon: const Icon(Icons.facebook, color: Colors.blue)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isEditable)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: viewProfileCallback,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandMain), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("View Full Profile", style: TextStyle(color: AppColors.brandMain, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    final List<Widget> icons = [];
    if (badgeLevel != null) {
      if (badgeLevel == BadgeLevel.bronze || badgeLevel == BadgeLevel.silver || badgeLevel == BadgeLevel.gold) {
        icons.add(Icon(AppBadgeTheme.baseIcon, color: AppBadgeTheme.bronze, size: 16));
      }
    }
    if (isVerifiedWorker) icons.add(const Icon(Icons.verified, color: StatusTheme.verifiedColor, size: 16));
    return Row(children: icons);
  }

  Widget _statCol(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.brandMain),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }
}
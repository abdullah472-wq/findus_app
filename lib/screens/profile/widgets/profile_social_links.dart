import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSocialLinks extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileSocialLinks({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final fb = userData['facebookUrl']?.toString() ?? "";
    final ig = userData['instagramUrl']?.toString() ?? "";
    final linkedin = userData['linkedInUrl']?.toString() ?? "";

    final List<Widget> buttons = [];
    if (fb.isNotEmpty) buttons.add(_socialBtn(Icons.facebook, Colors.blue, fb));
    if (ig.isNotEmpty) buttons.add(_socialBtn(Icons.camera_alt, Colors.pink, ig));
    if (linkedin.isNotEmpty) buttons.add(_socialBtn(Icons.work, const Color(0xFF0077B5), linkedin));

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  Widget _socialBtn(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';

import 'unified_profile_utils.dart';

mixin UnifiedProfileActions<T extends StatefulWidget> on State<T> {
  Map<String, dynamic> get userData;
  String get profileUid;

  Future<void> launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('লিংক খোলা যায়নি')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('লিংক খোলা যায়নি: $e')),
        );
      }
    }
  }

  Future<void> openChat(String roleLabel) async {
    final cid = await FirestoreChatService.getOrCreateConversation(
      otherUserId: profileUid,
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: cid,
          userName: UnifiedProfileUtils.safeString(userData['name']),
          userRole: roleLabel,
          userImage: UnifiedProfileUtils.safeString(userData['image'], defaultValue: ''),
        ),
      ),
    );
  }

  Future<void> makePhoneCall() async {
    final phone = userData['phone']?.toString().trim();
    if (phone == null || phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone call not supported')),
      );
    }
  }

  Future<void> sendEmail() async {
    final email = userData['email']?.toString().trim();
    if (email == null || email.isEmpty) return;

    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not supported')),
      );
    }
  }

  Future<void> reportUser() async {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
  }

  Future<void> shareProfile() async {
    try {
      final userName = UnifiedProfileUtils.safeString(userData['name'], defaultValue: 'FindUs User');
      // TODO: তোমার real deep link/domain বসাও
      final profileLink = 'https://yourapp.com/profile/$profileUid';
      final message = 'FindUs Profile: $userName\n$profileLink';

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.share(message, sharePositionOrigin: origin);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('শেয়ার করতে সমস্যা হয়েছে: $e')),
        );
      }
    }
  }
}
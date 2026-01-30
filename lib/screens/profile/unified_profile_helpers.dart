// lib/screens/profile/unified_profile_helpers.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';

mixin UnifiedProfileHelpers {
  BuildContext get context;
  Map<String, dynamic> get userData;
  String get uid;

  String _getSafeString(dynamic value, {String defaultValue = 'N/A'}) {
    if (value == null) return defaultValue;
    if (value is String && value.isEmpty) return defaultValue;
    return value.toString();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      // সরাসরি লঞ্চ করার চেষ্টা করুন
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link')));
      }
    }
  }

  Future<void> _openChat(String roleLabel) async {
    final cid = await FirestoreChatService.getOrCreateConversation(
      otherUserId: uid,
    );
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: cid,
            userName: _getSafeString(userData['name']),
            userRole: roleLabel,
            userImage: _getSafeString(userData['image']),
          ),
        ),
      );
    }
  }

  void _makePhoneCall() async {
    final phone = userData['phone']?.toString();
    if (phone != null && phone.isNotEmpty) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone call not supported')),
        );
      }
    }
  }

  void _sendEmail() async {
    final email = userData['email']?.toString();
    if (email != null && email.isNotEmpty) {
      final url = 'mailto:$email';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not supported')),
        );
      }
    }
  }

  void _reportUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }

  void _shareProfile() {
    final String profileLink = 'https://yourapp.com/profile/$uid';
    final String userName = _getSafeString(userData['name']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing profile of $userName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isWorkerRole() {
    final roleKey = (userData['userRole'] ?? 'worker').toString().toLowerCase();
    return roleKey == 'worker' || roleKey == 'finder';
  }
}
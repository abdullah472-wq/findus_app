// lib/screens/profile/unified_profile_screen.dart

import 'package:flutter/material.dart';
import 'unified_profile_state.dart';

class UnifiedProfileScreen extends StatefulWidget {
  final String uid;
  final bool isOwner;
  final bool? showBack; // ✅ এই প্যারামিটারটি যোগ করুন

  const UnifiedProfileScreen({
    super.key,
    required this.uid,
    this.isOwner = false,
    this.showBack, // ✅ কনস্ট্রাক্টরে যোগ করুন
  });

  @override
  State<UnifiedProfileScreen> createState() => UnifiedProfileScreenState();
}
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart'; // AppColors ইমপোর্ট
import 'unified_profile_state.dart';

class UnifiedProfileScreen extends StatefulWidget {
  final String uid;
  final bool isOwner;
  final bool? showBack;

  const UnifiedProfileScreen({
    super.key,
    required this.uid,
    this.isOwner = false,
    this.showBack,
  });

  @override
  State<UnifiedProfileScreen> createState() => UnifiedProfileScreenState();
}

// এই ফাইলের State ক্লাস (unified_profile_state.dart) এর build মেথডে 
// Scaffold-এর backgroundColor পরিবর্তন করতে হবে:
// backgroundColor: Theme.of(context).brightness == Brightness.dark 
//     ? const Color(0xFF121212) 
//     : AppColors.bgBlue,
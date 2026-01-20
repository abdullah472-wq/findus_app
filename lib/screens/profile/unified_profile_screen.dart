import 'package:flutter/material.dart';
import 'unified_profile_state.dart';

class UnifiedProfileScreen extends StatefulWidget {
  final String uid;
  final bool isOwner;

  const UnifiedProfileScreen({
    super.key,
    required this.uid,
    this.isOwner = false,
    required bool showBack,
  });

  @override
  State<UnifiedProfileScreen> createState() => UnifiedProfileScreenState();
}
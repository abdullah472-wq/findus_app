// lib/screens/tabs/conversation_tab.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/screens/supporter/supporter_profile_screen.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/services/conversation_storage.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class ConversationTab extends StatefulWidget {
  const ConversationTab({super.key});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
  List<Map<String, dynamic>> _conversations = [];
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final data = await ConversationStorage.load();
    if (!mounted) return;
    setState(() {
      _conversations = data;
    });
  }

  // ফিল্টার লজিক
  List<Map<String, dynamic>> get _filteredConversations {
    List<Map<String, dynamic>> base;
    if (_tabIndex == 1) {
      base = _conversations.where((c) => c['userType'] == 'supporter').toList();
    } else if (_tabIndex == 2) {
      base = _conversations.where((c) => c['userType'] == 'earner').toList();
    } else {
      base = List<Map<String, dynamic>>.from(_conversations);
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;

    return base.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final role = (c['role'] ?? '').toString().toLowerCase();
      return name.contains(q) || role.contains(q);
    }).toList();
  }

  // নিজের প্রোফাইল ওপেন করা
  Future<void> _openCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('user_role') ?? '').toLowerCase();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (role == 'maker' || role == 'supporter') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SupporterProfileScreen(
        isOwner: true,
        name: prefs.getString('user_name') ?? 'User',
        role: 'supporter',
        location: prefs.getString('user_location') ?? '',
        phone: prefs.getString('user_phone') ?? '',
        ratingText: (prefs.getDouble('user_rating') ?? 4.8).toStringAsFixed(1),
      )));
    } else {
      final worker = Worker(
        id: uid,
        name: prefs.getString('user_name') ?? 'User',
        role: 'earner',
        image: prefs.getString('user_image') ?? '',
        location: prefs.getString('user_location') ?? '',
        price: prefs.getString('worker_price') ?? 'Negotiable',
        rating: prefs.getDouble('user_rating') ?? 4.8,
        isVerified: prefs.getBool('user_verified') ?? false,
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker, isOwner: true)));
    }
  }

  // অন্যের প্রোফাইল ওপেন করা
  void _openOtherUserProfile(Map<String, dynamic> chat) {
    final bool isEarner = chat['userType'] == 'earner';
    if (isEarner) {
      final worker = Worker(
        id: chat['userId'] ?? '',
        name: chat['name'] ?? '',
        role: chat['role'] ?? 'earner',
        image: chat['image'] ?? '',
        location: chat['location'] ?? '',
        price: 'Negotiable',
        rating: (chat['rating'] ?? 0.0).toDouble(),
        isVerified: chat['isVerified'] == true,
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker, isOwner: false)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SupporterProfileScreen(
        isOwner: false,
        name: chat['name'] ?? '',
        role: chat['role'] ?? 'supporter',
        location: chat['location'] ?? '',
        phone: chat['phone'] ?? '',
        ratingText: (chat['rating'] ?? 0.0).toString(),
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0.5,
          title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          actions: [
            IconButton(icon: const Icon(Icons.person_outline), onPressed: _openCurrentUserProfile),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            indicatorColor: AppColors.brandMain,
            labelColor: AppColors.brandMain,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: "All"), Tab(text: "Supporter"), Tab(text: "Earner")],
          ),
        ),
        body: Column(
          children: [
            // সার্চ বার
            Container(
              padding: const EdgeInsets.all(15),
              color: Theme.of(context).cardColor,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: "Search messages...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // চ্যাট লিস্ট (কার্ড হিসেবে)
            Expanded(
              child: _filteredConversations.isEmpty
                  ? const Center(child: Text("No conversations found", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _filteredConversations.length,
                itemBuilder: (context, index) {
                  final chat = _filteredConversations[index];
                  return _buildChatItem(chat, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark) {
    return UniversalWorkerCard(
      id: chat['id'], // চ্যাট ওপেন করার জন্য আইডি পাস করা হয়েছে
      name: chat['name'] ?? 'User',
      role: chat['role'] ?? 'User',
      imageUrl: chat['image'] ?? 'https://i.pravatar.cc/150',
      address: chat['location'] ?? 'Bangladesh',
      rating: (chat['rating'] ?? 0.0).toStringAsFixed(1),
      completed: (chat['completed'] ?? 0).toString(),
      reviews: (chat['reviews'] ?? 0).toString(),
      price: chat['price'] ?? 'Negotiable',
      isVerifiedWorker: chat['isVerified'] == true,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      // কার্ডে ক্লিক করলে সরাসরি চ্যাটে যাবে
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
          conversationId: chat['id'],
          userName: chat['name'],
          userImage: chat['image'],
          userRole: chat['role'],
        )));
      },

      // প্রোফাইল ওপেন করার জন্য কলব্যাক
      onViewProfileTap: () => _openOtherUserProfile(chat),
    );
  }
}
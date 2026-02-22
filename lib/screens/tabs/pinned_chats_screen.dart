import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';

class PinnedChatsScreen extends StatelessWidget {
  const PinnedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pinned Chats"),
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: uid)
            .where('isPinned', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.push_pin_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No pinned chats", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: chat['image'] != null && chat['image'].toString().isNotEmpty
                      ? NetworkImage(chat['image'])
                      : null,
                  child: chat['image'] == null || chat['image'].toString().isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(chat['name'] ?? 'User'),
                subtitle: Text(chat['lastMsg'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.push_pin, color: AppColors.brandMain),
                  onPressed: () async {
                    await snapshot.data!.docs[index].reference.update({
                      'isPinned': false,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat unpinned")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
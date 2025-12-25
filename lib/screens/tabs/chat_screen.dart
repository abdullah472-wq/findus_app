import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart'; // এখন আর এরর দেখাবে না
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String userName;
  final String userImage;
  final String userRole;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.userImage,
    required this.userRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  late ChatUser _me;
  late ChatUser _otherUser;

  @override
  void initState() {
    super.initState();
    // নিজের তথ্য
    _me = ChatUser(
      id: currentUser.uid,
      firstName: currentUser.displayName ?? "Me",
      profileImage: currentUser.photoURL,
    );
    // অন্য ইউজারের তথ্য
    _otherUser = ChatUser(
      id: "other_user_id", // এখানে আইডি না থাকলে widget.userName ইউজ করতে পারেন
      firstName: widget.userName,
      profileImage: widget.userImage,
    );
  }

  // মেসেজ পাঠানোর ফাংশন
  void _sendMessage(ChatMessage message) {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'text': message.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // শেষ মেসেজ আপডেট করা (চ্যাট লিস্টের জন্য)
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .set({
      'lastMsg': message.text,
      'time': "Just now", // আপনি চাইলেDateFormat ইউজ করতে পারেন
      'unread': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.userImage.isNotEmpty
                  ? widget.userImage
                  : 'https://i.pravatar.cc/150'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.userRole, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ChatMessage> messages = [];
          if (snapshot.hasData) {
            messages = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ChatMessage(
                user: data['senderId'] == currentUser.uid ? _me : _otherUser,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                text: data['text'] ?? '',
              );
            }).toList();
          }

          return DashChat(
            currentUser: _me,
            onSend: _sendMessage,
            messages: messages,
            messageOptions: MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              containerColor: isDark ? const Color(0xFF2C2C2C) : Colors.blueGrey[50]!,
              currentUserContainerColor: AppColors.brandMain,
              currentUserTextColor: Colors.white,
              textColor: isDark ? Colors.white : Colors.black87,
            ),
            inputOptions: InputOptions(
              inputDecoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Colors.grey),
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          );
        },
      ),
    );
  }
}
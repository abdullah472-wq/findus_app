import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
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
    _me = ChatUser(
      id: currentUser.uid,
      firstName: currentUser.displayName ?? "Me",
      profileImage: currentUser.photoURL,
    );
    _otherUser = ChatUser(
      id: "other", // আইডি এখানে গুরুত্বপূর্ণ নয়, শুধু ডিসপ্লের জন্য
      firstName: widget.userName,
      profileImage: widget.userImage,
    );
  }

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

    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .set({
      'lastMsg': message.text,
      'time': "Just now",
      'unread': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final appBarColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandLight,
              backgroundImage: NetworkImage(widget.userImage.isNotEmpty
                  ? widget.userImage
                  : 'https://i.pravatar.cc/150'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                Text(widget.userRole.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
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
              containerColor: isDark ? const Color(0xFF2C2C2C) : AppColors.brandMain.withOpacity(0.1),
              currentUserContainerColor: AppColors.brandMain,
              currentUserTextColor: Colors.white,
              textColor: textColor,
              timeFontSize: 10,
            ),
            inputOptions: InputOptions(
              inputTextStyle: TextStyle(color: textColor),
              cursorStyle: const CursorStyle(color: AppColors.brandMain),
              inputDecoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              sendButtonBuilder: (onSend) {
                return IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.brandMain),
                  onPressed: onSend,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
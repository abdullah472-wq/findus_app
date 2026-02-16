import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/cloudinary_service.dart'; // ✅ আপনার CloudinaryService পাথ চেক করুন

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
  late final User _currentUser;
  late ChatUser _me;
  late ChatUser _otherUser;

  bool _isFirstMessage = true;
  bool _checkingFirstMessage = true;
  bool _isUploading = false;
  String? _loadError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loadError = 'You are not logged in.';
    } else {
      _currentUser = user;
      _me = ChatUser(
        id: _currentUser.uid,
        firstName: _currentUser.displayName ?? "You",
        profileImage: _currentUser.photoURL,
      );
    }

    _otherUser = ChatUser(
      id: 'other',
      firstName: widget.userName,
      profileImage: widget.userImage.isNotEmpty ? widget.userImage : 'https://i.pravatar.cc/150',
    );

    if (_loadError == null) {
      _checkIfFirstMessage();
    }
  }

  Future<void> _checkIfFirstMessage() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() {
        _isFirstMessage = snap.docs.isEmpty;
        _checkingFirstMessage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingFirstMessage = false;
        _loadError = 'Unable to load conversation.';
      });
    }
  }

  // ✅ Cloudinary Image Selection & Upload
  Future<void> _handleImageSelection() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // সাইজ কমানোর জন্য
      );

      if (image != null) {
        setState(() => _isUploading = true);
        await _uploadImageToCloudinary(image);
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image selection failed: $e")));
    }
  }

  Future<void> _uploadImageToCloudinary(XFile file) async {
    try {
      // ✅ CloudinaryService ব্যবহার করে আপলোড
      final response = await CloudinaryService.uploadXFile(
        file,
        folder: 'chat_images',
        resourceType: 'image',
      );

      final String downloadUrl = response['secure_url']; // URL পাওয়া গেল

      // ইমেজ মেসেজ হিসেবে সেন্ড করা
      final message = ChatMessage(
        user: _me,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: downloadUrl,
            fileName: 'image',
            type: MediaType.image,
          ),
        ],
      );

      await _sendMessage(message);

    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  // ✅ Send Message Logic
  Future<void> _sendMessage(ChatMessage message) async {
    if (message.text.trim().isEmpty && (message.medias == null || message.medias!.isEmpty)) return;

    try {
      final msgRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages');

      Map<String, dynamic> msgData = {
        'senderId': _currentUser.uid,
        'text': message.text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (message.medias != null && message.medias!.isNotEmpty) {
        msgData['image'] = message.medias!.first.url;
        msgData['type'] = 'image';
      } else {
        msgData['type'] = 'text';
      }

      await msgRef.add(msgData);

      String previewText = message.text.isNotEmpty ? message.text : '📷 Sent an image';

      final convRef = FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);
      await convRef.set(
        {
          'lastMsg': previewText,
          'unread': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
          'participants': FieldValue.arrayUnion([_currentUser.uid]),
        },
        SetOptions(merge: true),
      );

      await AchievementService.incrementProgress('daily_message');
      await AchievementService.syncWeeklyChestFromServer();

      if (_isFirstMessage) {
        await AchievementService.incrementProgress('lt_chat_s1');
        _isFirstMessage = false;
      }
    } catch (e) {
      debugPrint("Message failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, appBarColor, textColor),
      body: Stack(
        children: [
          _buildBody(isDark, textColor),

          if (_isUploading)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text("Uploading to Cloudinary...", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color bgColor, Color textColor) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandLight,
            backgroundImage: NetworkImage(_otherUser.profileImage!),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              Text(
                widget.userRole.toUpperCase(),
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textColor) {
    if (_loadError != null) return Center(child: Text(_loadError!, style: TextStyle(color: textColor)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _checkingFirstMessage) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
        }

        List<ChatMessage> messages = [];
        if (snapshot.hasData) {
          messages = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final senderId = data['senderId'] as String? ?? '';
            final createdAt = data['createdAt'];
            final DateTime createdTime = (createdAt is Timestamp) ? createdAt.toDate() : DateTime.now();

            List<ChatMedia>? medias;
            if (data['image'] != null && data['image'].toString().isNotEmpty) {
              medias = [
                ChatMedia(
                  url: data['image'],
                  fileName: 'image.jpg',
                  type: MediaType.image,
                )
              ];
            }

            return ChatMessage(
              user: senderId == _currentUser.uid ? _me : _otherUser,
              createdAt: createdTime,
              text: (data['text'] ?? '').toString(),
              medias: medias,
            );
          }).toList();
        }

        return DashChat(
            currentUser: _me,
            messages: messages,
            onSend: _sendMessage,

            messageOptions: MessageOptions(
              showOtherUsersAvatar: true,
              showTime: true,
              containerColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              currentUserContainerColor: AppColors.brandMain,
              textColor: isDark ? Colors.white : Colors.black87,
              currentUserTextColor: Colors.white,
              timeFormat: DateFormat('hh:mm a'),

              // ✅ FIXED: imageBuilder এর বদলে messageMediaBuilder ব্যবহার করুন
              messageMediaBuilder: (message, previousMessage, nextMessage) {
                if (message.medias != null && message.medias!.isNotEmpty) {
                  final media = message.medias!.first;
                  if (media.type == MediaType.image) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          media.url,
                          fit: BoxFit.cover,
                          // লোডিং ইফেক্ট (অপশনাল)
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              width: 200,
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox(); // অন্য টাইপ হলে খালি দেখাবে
              },
            ),
        );
      },
    );
  }
}
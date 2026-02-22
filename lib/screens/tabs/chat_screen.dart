// lib/screens/tabs/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/screens/report/report_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String userName;
  final String userImage;
  final String userRole;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.userImage,
    required this.userRole,
    this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final User _currentUser;
  late ChatUser _me;
  late ChatUser _otherUser;

  bool _isFirstMessage = true;
  bool _checkingFirstMessage = true;
  bool _isUploading = false;
  bool _isOtherUserTyping = false;
  bool _isBlocked = false;
  bool _isMuted = false;
  String? _loadError;
  String _onlineStatus = 'offline';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final BlockedUserService _blockedService = BlockedUserService();

  // ✅ For typing indicator debounce
  DateTime? _lastTypingUpdate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
      id: widget.otherUserId ?? 'other',
      firstName: widget.userName,
      profileImage: widget.userImage.isNotEmpty ? widget.userImage : 'https://i.pravatar.cc/150',
    );

    if (_loadError == null) {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    await _checkBlockStatus();
    await _checkMuteStatus();
    _checkIfFirstMessage();
    _markAsRead();
    _listenToOnlineStatus();
    _listenToTypingStatus();
    _updateMyOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _updateMyOnlineStatus(false);
    _updateTypingStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateMyOnlineStatus(true);
    } else {
      _updateMyOnlineStatus(false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCK STATUS CHECK
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _checkBlockStatus() async {
    if (widget.otherUserId == null) return;

    final blocked = _blockedService.isBlocked(widget.otherUserId!);

    // Also check if other user blocked me
    bool blockedByOther = false;
    try {
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      final blockedUsers = List<String>.from(otherUserDoc.data()?['blockedUsers'] ?? []);
      blockedByOther = blockedUsers.contains(_currentUser.uid);
    } catch (e) {
      debugPrint("Error checking if blocked by other: $e");
    }

    if (mounted) {
      setState(() {
        _isBlocked = blocked || blockedByOther;
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔇 MUTE STATUS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _checkMuteStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (mounted) {
        setState(() {
          _isMuted = doc.data()?['isMuted'] == true;
        });
      }
    } catch (e) {
      debugPrint("Error checking mute status: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🟢 ONLINE STATUS
  // ════════════════════════════════════════════════════════════════════════════

  void _listenToOnlineStatus() {
    if (widget.otherUserId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final data = snapshot.data();
      if (data != null) {
        final isOnline = data['isOnline'] == true;
        final lastSeen = data['lastSeen'] as Timestamp?;

        setState(() {
          if (isOnline) {
            _onlineStatus = 'Online';
          } else if (lastSeen != null) {
            _onlineStatus = _formatLastSeen(lastSeen.toDate());
          } else {
            _onlineStatus = 'Offline';
          }
        });
      }
    });
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return 'Active ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Active ${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return 'Active ${diff.inDays}d ago';
    } else {
      return 'Offline';
    }
  }

  Future<void> _updateMyOnlineStatus(bool isOnline) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating online status: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⌨️ TYPING INDICATOR
  // ════════════════════════════════════════════════════════════════════════════

  void _listenToTypingStatus() {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final data = snapshot.data();
      if (data != null) {
        final typingUsers = Map<String, dynamic>.from(data['typing'] ?? {});
        final otherTyping = typingUsers[widget.otherUserId] == true;

        setState(() {
          _isOtherUserTyping = otherTyping;
        });
      }
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    // Debounce typing updates
    final now = DateTime.now();
    if (_lastTypingUpdate != null &&
        now.difference(_lastTypingUpdate!).inSeconds < 2 &&
        isTyping) {
      return;
    }
    _lastTypingUpdate = now;

    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'typing.${_currentUser.uid}': isTyping,
      });
    } catch (e) {
      debugPrint("Error updating typing status: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ EXISTING METHODS (with minor updates)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'unread': 0});
    } catch (e) {
      debugPrint("Mark as read failed: $e");
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Send Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Camera",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImageSelection(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImageSelection(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        await _uploadImageToCloudinary(image);
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Image selection failed: $e", isError: true);
    }
  }

  Future<void> _uploadImageToCloudinary(XFile file) async {
    try {
      final response = await CloudinaryService.uploadXFile(
        file,
        folder: 'chat_images',
        resourceType: 'image',
      );

      final String downloadUrl = response['secure_url'];

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
      _showSnackBar("Upload failed: $e", isError: true);
    }
  }

  Future<void> _sendMessage(ChatMessage message) async {
    if (_isBlocked) {
      _showSnackBar("You can't send messages to this user", isError: true);
      return;
    }

    if (message.text.trim().isEmpty && (message.medias == null || message.medias!.isEmpty)) return;

    // Stop typing indicator
    _updateTypingStatus(false);

    try {
      final msgRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages');

      Map<String, dynamic> msgData = {
        'senderId': _currentUser.uid,
        'text': message.text,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'reactions': {},
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
      _showSnackBar("Failed to send message", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.brandMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD UI
  // ════════════════════════════════════════════════════════════════════════════

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
          // ✅ Blocked State
          if (_isBlocked)
            _buildBlockedState(isDark)
          else
            _buildBody(isDark, textColor),

          // ✅ Uploading Indicator
          if (_isUploading)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text("Uploading image...", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCKED STATE UI
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBlockedState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Can't send messages",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You can't message this user because one of you has blocked the other.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_blockedService.isBlocked(widget.otherUserId ?? ''))
              ElevatedButton.icon(
                onPressed: _unblockUser,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Unblock User"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _unblockUser() async {
    if (widget.otherUserId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unblock User?"),
        content: Text("${widget.userName} will be able to message you again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Unblock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _blockedService.unblockUser(widget.otherUserId!);
      setState(() => _isBlocked = false);
      _showSnackBar("${widget.userName} unblocked");
    } catch (e) {
      _showSnackBar("Failed to unblock", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📱 APP BAR
  // ════════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(bool isDark, Color bgColor, Color textColor) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          if (widget.otherUserId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnifiedProfileScreen(
                  uid: widget.otherUserId!,
                  isOwner: false,
                  showBack: true,
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            // ✅ Avatar with Online Indicator
            Stack(
              children: [
                Hero(
                  tag: 'avatar_${widget.conversationId}',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandLight,
                    backgroundImage: NetworkImage(_otherUser.profileImage ?? ''),
                  ),
                ),
                // Online dot
                if (_onlineStatus == 'Online')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.userName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Muted icon
                      if (_isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.notifications_off, size: 14, color: Colors.grey[500]),
                      ],
                    ],
                  ),
                  // ✅ Typing indicator or online status
                  if (_isOtherUserTyping)
                    Text(
                      "typing...",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brandMain,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      _onlineStatus,
                      style: TextStyle(
                        fontSize: 11,
                        color: _onlineStatus == 'Online'
                            ? Colors.green
                            : (isDark ? Colors.white54 : Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // ✅ Call Button
        IconButton(
          icon: Icon(Icons.call_outlined, color: textColor),
          onPressed: () {
            _showSnackBar("Voice call coming soon!");
          },
        ),
        // ✅ More Options Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            // View Profile
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Text("View Profile"),
                ],
              ),
            ),

            // Mute/Unmute
            PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(
                    _isMuted ? Icons.notifications_active : Icons.notifications_off_outlined,
                    size: 20,
                    color: _isMuted ? Colors.green : Colors.blueGrey,
                  ),
                  const SizedBox(width: 12),
                  Text(_isMuted ? "Unmute" : "Mute Notifications"),
                ],
              ),
            ),

            // Search in Chat
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Text("Search in Chat"),
                ],
              ),
            ),

            // Shared Media
            const PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 20, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Text("Shared Media"),
                ],
              ),
            ),

            const PopupMenuDivider(),

            // Block User
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    _blockedService.isBlocked(widget.otherUserId ?? '')
                        ? Icons.check_circle_outline
                        : Icons.block,
                    size: 20,
                    color: _blockedService.isBlocked(widget.otherUserId ?? '')
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _blockedService.isBlocked(widget.otherUserId ?? '')
                        ? "Unblock User"
                        : "Block User",
                    style: TextStyle(
                      color: _blockedService.isBlocked(widget.otherUserId ?? '')
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Clear Chat
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text("Clear Chat", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),

            // Report User
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text("Report User", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        if (widget.otherUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnifiedProfileScreen(
                uid: widget.otherUserId!,
                isOwner: false,
                showBack: true,
              ),
            ),
          );
        }
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'search':
        _showSearchInChat();
        break;
      case 'media':
        _showSharedMedia();
        break;
      case 'block':
        if (_blockedService.isBlocked(widget.otherUserId ?? '')) {
          _unblockUser();
        } else {
          _showBlockDialog();
        }
        break;
      case 'clear':
        _showClearChatDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔇 MUTE TOGGLE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _toggleMute() async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'isMuted': !_isMuted});

      setState(() => _isMuted = !_isMuted);
      _showSnackBar(_isMuted ? "Notifications muted 🔕" : "Notifications enabled 🔔");
    } catch (e) {
      _showSnackBar("Failed to update", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 SEARCH IN CHAT
  // ════════════════════════════════════════════════════════════════════════════

  void _showSearchInChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search messages...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                  onChanged: (query) {
                    // TODO: Implement search
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "Search results will appear here",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🖼️ SHARED MEDIA
  // ════════════════════════════════════════════════════════════════════════════

  void _showSharedMedia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SharedMediaScreen(conversationId: widget.conversationId),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCK DIALOG
  // ════════════════════════════════════════════════════════════════════════════

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 10),
            Text("Block User"),
          ],
        ),
        content: Text(
          "Block ${widget.userName}?\n\n"
              "• They won't be able to message you\n"
              "• They won't know they're blocked\n"
              "• You can unblock them anytime",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser();
            },
            child: const Text("Block", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    if (widget.otherUserId == null) return;

    try {
      await _blockedService.blockUser(
        widget.otherUserId!,
        targetName: widget.userName,
        targetImage: widget.userImage,
      );

      setState(() => _isBlocked = true);
      _showSnackBar("${widget.userName} blocked 🚫");
    } catch (e) {
      _showSnackBar("Failed to block user", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ CLEAR CHAT
  // ════════════════════════════════════════════════════════════════════════════

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Chat"),
        content: const Text("Are you sure you want to clear all messages?\nThis cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _clearChat();
            },
            child: const Text("Clear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final messages = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'lastMsg': '', 'unread': 0});

      _showSnackBar("Chat cleared 🗑️");
    } catch (e) {
      _showSnackBar("Failed to clear chat", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⚠️ REPORT DIALOG
  // ════════════════════════════════════════════════════════════════════════════

  void _showReportDialog() {
    if (widget.otherUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          // If your ReportScreen accepts userId and userName
          // reportedUserId: widget.otherUserId!,
          // reportedUserName: widget.userName,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💬 MESSAGE BODY
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBody(bool isDark, Color textColor) {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_loadError!, style: TextStyle(color: textColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        ),
      );
    }

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

          inputOptions: InputOptions(
            alwaysShowSend: true,
            sendOnEnter: true,
            onTextChange: (text) {
              // ✅ Update typing status
              if (text.isNotEmpty) {
                _updateTypingStatus(true);
              } else {
                _updateTypingStatus(false);
              }
            },
            inputDecoration: InputDecoration(
              hintText: "Type a message...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
            // ✅ Plus button (includes camera & gallery)
            leading: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.brandMain, size: 28),
                onPressed: _showImageSourceDialog,
              ),
            ],
            // ❌ REMOVED: trailing camera button
            // trailing: [
            //   IconButton(
            //     icon: Icon(Icons.camera_alt_outlined, color: Colors.grey[600], size: 24),
            //     onPressed: () => _handleImageSelection(ImageSource.camera),
            //   ),
            // ],
          ),

          messageOptions: MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
            containerColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            currentUserContainerColor: AppColors.brandMain,
            textColor: isDark ? Colors.white : Colors.black87,
            currentUserTextColor: Colors.white,
            timeFormat: DateFormat('hh:mm a'),
            borderRadius: 16,
            marginDifferentAuthor: const EdgeInsets.only(top: 12),
            marginSameAuthor: const EdgeInsets.only(top: 4),

            // ✅ Long Press for Message Options
            onLongPressMessage: (message) {
              _showMessageOptions(message);
            },

            messageMediaBuilder: (message, previousMessage, nextMessage) {
              if (message.medias != null && message.medias!.isNotEmpty) {
                final media = message.medias!.first;
                if (media.type == MediaType.image) {
                  return GestureDetector(
                    onTap: () => _showFullImage(media.url),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 250,
                            maxHeight: 300,
                          ),
                          child: Image.network(
                            media.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 150,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.brandMain),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
          ),

          messageListOptions: MessageListOptions(
            dateSeparatorBuilder: (date) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateSeparator(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💬 MESSAGE OPTIONS (Long Press)
  // ════════════════════════════════════════════════════════════════════════════

  void _showMessageOptions(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMyMessage = message.user.id == _currentUser.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    // TODO: Add reaction to message
                    _showSnackBar("Reactions coming soon!");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),

            const Divider(height: 24),

            // Copy
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text("Copy"),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Copy to clipboard
                  _showSnackBar("Copied to clipboard coming soon!");
                },
              ),

            // Reply
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text("Reply"),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Reply feature
                _showSnackBar("Reply coming soon!");
              },
            ),

            // Forward
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: const Text("Forward"),
              onTap: () {
                Navigator.pop(ctx);
                _showSnackBar("Forward coming soon!");
              },
            ),

            // Delete (only for my messages)
            if (isMyMessage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Delete message
                  _showSnackBar("Delete coming soon!");
                },
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  _showSnackBar("Download coming soon!");
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  _showSnackBar("Share coming soon!");
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 🖼️ SHARED MEDIA SCREEN
// ════════════════════════════════════════════════════════════════════════════

class _SharedMediaScreen extends StatelessWidget {
  final String conversationId;

  const _SharedMediaScreen({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Media"),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('type', isEqualTo: 'image')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No shared media",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final images = snapshot.data!.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['image'] as String?)
              .where((url) => url != null && url.isNotEmpty)
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            child: Image.network(images[index]!),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Image.network(
                  images[index]!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
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
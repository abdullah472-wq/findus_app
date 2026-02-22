// lib/screens/settings/help_center_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/theme_service.dart';
import 'faq_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _HelpColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return FloatingScaffold(
          title: 'HELP CENTER',
          backgroundColor: colors.bgColor,
          titleColor: colors.textColor,
          iconColor: colors.textColor,
          showBack: true,
          scrollable: true,
          bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(colors),

              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(context, colors),

              const SizedBox(height: 25),

              // Help Options
              Text(
                "Support Options",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ
              _buildHelpTile(
                context,
                icon: Icons.help_outline_rounded,
                title: "FAQ",
                subtitle: "Common questions and answers",
                iconColor: Colors.blue,
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),

              // Chat Support
              _buildHelpTile(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: "Live Chat",
                subtitle: "Chat with our support team",
                iconColor: Colors.green,
                badge: "Online",
                badgeColor: Colors.green,
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                ),
              ),

              // Email Support
              _buildHelpTile(
                context,
                icon: Icons.email_outlined,
                title: "Email Support",
                subtitle: "support@findus.app",
                iconColor: Colors.orange,
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailSupportScreen()),
                ),
              ),

              // Phone Support
              _buildHelpTile(
                context,
                icon: Icons.phone_outlined,
                title: "Phone Support",
                subtitle: "+880 1581818368",
                iconColor: Colors.purple,
                colors: colors,
                onTap: () => _makePhoneCall(context),
              ),

              const SizedBox(height: 25),

              // Resources Section
              Text(
                "Resources",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Community
              _buildHelpTile(
                context,
                icon: Icons.people_outline,
                title: "Community Forum",
                subtitle: "Connect with other users",
                iconColor: Colors.teal,
                colors: colors,
                onTap: () => _openUrl('https://community.findus.app'),
              ),

              // Video Tutorials
              _buildHelpTile(
                context,
                icon: Icons.play_circle_outline,
                title: "Video Tutorials",
                subtitle: "Learn how to use FINDUS",
                iconColor: Colors.red,
                colors: colors,
                onTap: () => _openUrl('https://youtube.com/@findusapp'),
              ),

              const SizedBox(height: 30),

              // Feedback Button
              _buildFeedbackButton(context, colors),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(_HelpColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain,
            AppColors.brandMain.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Need Help?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We're here 24/7 to assist you",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, _HelpColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.chat,
            label: "Chat",
            color: Colors.green,
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportChatScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.email,
            label: "Email",
            color: Colors.orange,
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailSupportScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.phone,
            label: "Call",
            color: Colors.purple,
            colors: colors,
            onTap: () => _makePhoneCall(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required _HelpColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor,
        required _HelpColors colors,
        required VoidCallback onTap,
        String? badge,
        Color? badgeColor,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: colors.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    badge,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.subTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.subTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, _HelpColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.feedback_outlined,
            color: colors.subTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Give us feedback",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Help us improve FINDUS",
                  style: TextStyle(
                    color: colors.subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showFeedbackDialog(context, colors),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context) async {
    const phoneNumber = 'tel:+8801581818368';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(width: 10),
            Text("Call Support"),
          ],
        ),
        content: const Text(
          "Would you like to call our support line?\n\n+880 1581818368\n\nAvailable: 9 AM - 9 PM",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(phoneNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.call),
            label: const Text("Call Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFeedbackDialog(BuildContext context, _HelpColors colors) {
    final controller = TextEditingController();
    int selectedRating = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colors.cardColor,
          title: Text(
            "Rate Your Experience",
            style: TextStyle(color: colors.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = index + 1),
                    child: Icon(
                      index < selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Feedback text
              TextField(
                controller: controller,
                maxLines: 3,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  hintText: "Tell us more (optional)",
                  hintStyle: TextStyle(color: colors.subTextColor),
                  filled: true,
                  fillColor: colors.isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.subTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text("Thank you for your feedback!"),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUPPORT CHAT SCREEN
// ════════════════════════════════════════════════════════════════════════════

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _isSending = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      isMe: false,
      text: "👋 Hi! Welcome to FINDUS Support.\n\nHow can we help you today?",
      time: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  // Quick replies
  final List<String> _quickReplies = [
    "Account Issue",
    "Payment Problem",
    "Report a Bug",
    "Feature Request",
    "Other",
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickReply]) async {
    final text = quickReply ?? _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(
        isMe: true,
        text: text,
        time: DateTime.now(),
      ));
      _msgController.clear();
    });

    _scrollToBottom();

    // Simulate typing indicator
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Simulate bot response
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _isSending = false;
      _messages.add(_ChatMessage(
        isMe: false,
        text: _getBotResponse(text),
        time: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  String _getBotResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('account') || msg.contains('login') || msg.contains('password')) {
      return "For account-related issues:\n\n"
          "1. Go to Settings > Account\n"
          "2. Try 'Forgot Password' if you can't login\n"
          "3. Contact us if the problem persists\n\n"
          "Would you like to speak with a human agent?";
    } else if (msg.contains('payment') || msg.contains('money') || msg.contains('wallet')) {
      return "For payment issues:\n\n"
          "1. Check your wallet balance in the app\n"
          "2. Verify your payment method\n"
          "3. Allow 24-48 hours for transactions\n\n"
          "If the issue persists, please provide your transaction ID.";
    } else if (msg.contains('bug') || msg.contains('error') || msg.contains('crash')) {
      return "We're sorry you're experiencing issues!\n\n"
          "Please provide:\n"
          "• Your device model\n"
          "• App version\n"
          "• Steps to reproduce\n\n"
          "This helps us fix the problem faster.";
    } else if (msg.contains('feature') || msg.contains('request') || msg.contains('suggest')) {
      return "We love hearing your ideas! 💡\n\n"
          "Please describe the feature you'd like to see, and our team will review it.\n\n"
          "Many features come from user suggestions!";
    } else {
      return "Thanks for your message! 🙏\n\n"
          "Our support team has received your query and will respond within 2-4 hours.\n\n"
          "Is there anything else I can help you with?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _HelpColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return Scaffold(
          backgroundColor: colors.bgColor,
          appBar: _buildAppBar(colors),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator(colors);
                    }
                    return _buildChatBubble(_messages[index], colors);
                  },
                ),
              ),

              // Quick Replies
              if (_messages.length <= 2)
                _buildQuickReplies(colors),

              // Input Area
              _buildInputArea(colors),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(_HelpColors colors) {
    return AppBar(
      backgroundColor: colors.cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandLight,
                child: const Icon(
                  Icons.support_agent,
                  color: AppColors.brandDark,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.cardColor, width: 2),
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
                Text(
                  "FINDUS Support",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isTyping ? "Typing..." : "Online",
                  style: TextStyle(
                    color: _isTyping ? AppColors.brandMain : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.textColor),
          onPressed: () => _showChatOptions(context, colors),
        ),
      ],
    );
  }

  Widget _buildChatBubble(_ChatMessage message, _HelpColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandLight,
              child: Icon(
                Icons.support_agent,
                size: 18,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isMe
                    ? AppColors.brandMain
                    : colors.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(message.isMe ? 18 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : colors.textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white70
                          : colors.subTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(_HelpColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brandLight,
            child: Icon(
              Icons.support_agent,
              size: 18,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.subTextColor
                            .withOpacity(0.3 + (0.7 * value)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(_HelpColors colors) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_quickReplies[index]),
              backgroundColor: colors.cardColor,
              labelStyle: TextStyle(
                color: AppColors.brandMain,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(color: AppColors.brandMain.withOpacity(0.3)),
              onPressed: () => _sendMessage(_quickReplies[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(_HelpColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(Icons.attach_file, color: colors.subTextColor),
            onPressed: () {
              // TODO: Implement attachment
              HapticFeedback.lightImpact();
            },
          ),

          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _msgController,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: colors.subTextColor),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          CircleAvatar(
            backgroundColor: AppColors.brandMain,
            radius: 22,
            child: IconButton(
              icon: Icon(
                _isSending ? Icons.hourglass_empty : Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
              onPressed: _isSending ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return "$displayHour:$minute $period";
    }
    return "${time.day}/${time.month}/${time.year}";
  }

  void _showChatOptions(BuildContext context, _HelpColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.subTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text("Clear Chat", style: TextStyle(color: colors.textColor)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _messages.clear();
                  _messages.add(_ChatMessage(
                    isMe: false,
                    text: "👋 Hi! Welcome to FINDUS Support.\n\nHow can we help you today?",
                    time: DateTime.now(),
                  ));
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.email_outlined, color: colors.textColor),
              title: Text("Email Transcript", style: TextStyle(color: colors.textColor)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chat transcript sent to your email")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMAIL SUPPORT SCREEN
// ════════════════════════════════════════════════════════════════════════════

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() => _EmailSupportScreenState();
}

class _EmailSupportScreenState extends State<EmailSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Account Issue',
    'Payment Problem',
    'Bug Report',
    'Feature Request',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _HelpColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return Scaffold(
          backgroundColor: colors.bgColor,
          appBar: AppBar(
            backgroundColor: colors.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colors.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Email Support",
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Card
                _buildInfoCard(colors),

                const SizedBox(height: 24),

                // Category Dropdown
                _buildCategoryDropdown(colors),

                const SizedBox(height: 16),

                // Subject Field
                _buildTextField(
                  label: "Subject",
                  hint: "Brief description of your issue",
                  controller: _subjectController,
                  icon: Icons.subject,
                  colors: colors,
                ),

                const SizedBox(height: 16),

                // Message Field
                _buildTextField(
                  label: "Message",
                  hint: "Describe your issue in detail...",
                  controller: _messageController,
                  icon: Icons.message,
                  colors: colors,
                  maxLines: 6,
                ),

                const SizedBox(height: 16),

                // Attachment Button
                _buildAttachmentButton(colors),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 10),
                      Text(
                        "SEND EMAIL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(_HelpColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.1),
            AppColors.brandMain.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_rounded,
              color: AppColors.brandMain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "support@findus.app",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We typically respond within 24 hours",
                  style: TextStyle(
                    color: colors.subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(_HelpColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.subTextColor),
              dropdownColor: colors.cardColor,
              style: TextStyle(color: colors.textColor),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required _HelpColors colors,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: colors.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.subTextColor),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppColors.brandMain)
                : null,
            filled: true,
            fillColor: colors.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandMain,
                width: 2,
              ),
            ),
          ),
          validator: (val) =>
          (val == null || val.isEmpty) ? "$label is required" : null,
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(_HelpColors colors) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement file picker
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attachment feature coming soon!")),
        );
      },
      icon: const Icon(Icons.attach_file),
      label: const Text("Add Attachment"),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textColor,
        side: BorderSide(
          color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Email sent successfully!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.pop(context);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _HelpColors {
  final bool isDark;
  final bool useAmoled;

  _HelpColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
}

class _ChatMessage {
  final bool isMe;
  final String text;
  final DateTime time;

  _ChatMessage({
    required this.isMe,
    required this.text,
    required this.time,
  });
}
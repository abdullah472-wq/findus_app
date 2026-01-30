import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'faq_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return FloatingScaffold(
      title: 'HELP CENTER',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),

          // FAQ
          _buildHelpTile(
            context,
            icon: Icons.question_answer_outlined,
            title: "FAQ",
            subtitle: "Common questions and answers",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),

          // Chat with Support
          _buildHelpTile(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            title: "Chat with Support",
            subtitle: "Get help from our team",
            iconColor: AppColors.brandMain,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),

          // Email Support
          _buildHelpTile(
            context,
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "support@findus.app",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailSupportScreen())),
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required Color cardColor,
        required Color textColor,
        required Color subTextColor,
        Color? iconColor,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? textColor).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? textColor, size: 22),
        ),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: subTextColor),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ============================================================
// Support Chat Screen (Fixed Padding)
// ============================================================

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"isMe": false, "text": "Hi! How can we help you today?", "time": "10:30 AM"},
  ];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"isMe": true, "text": text, "time": "Now"});
      _msgController.clear();
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "isMe": false,
          "text": "Thanks for your message. Our team will get back to you shortly.",
          "time": "Just now",
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // ✅ Top Padding Calculation
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  // ✅ Fixed Padding: Content won't go under AppBar
                  padding: EdgeInsets.only(top: topPadding, bottom: 80),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg["isMe"] as bool, msg["text"] as String, msg["time"] as String, isDark);
                  },
                ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: AppColors.brandMain,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _FloatingTopBar(
            title: "Support Chat",
            onBack: () => Navigator.pop(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(bool isMe, String text, String time, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandLight,
              child: Icon(Icons.support_agent, size: 18, color: AppColors.brandDark),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isMe ? AppColors.brandMain : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ]
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Email Support Screen (Fixed Padding)
// ============================================================

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() => _EmailSupportScreenState();
}

class _EmailSupportScreenState extends State<EmailSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // ✅ Top Padding Calculation
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 20;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              // ✅ Fixed Padding
              padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 100),
              children: [
                _buildInfoCard(isDark),
                const SizedBox(height: 25),
                _buildTextField("Subject", Icons.subject, _subjectController, isDark, cardColor, textColor),
                const SizedBox(height: 20),
                _buildTextField("Message", Icons.message, _messageController, isDark, cardColor, textColor, maxLines: 8),
              ],
            ),
          ),
          _FloatingTopBar(title: "Email Support", onBack: () => Navigator.pop(context), isDark: isDark),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: cardColor,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email sent successfully"), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SEND EMAIL", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.brandLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.brandMain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your email will be sent to support@findus.app. We respond within 24 hours.",
              style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController ctrl, bool isDark, Color cardColor, Color textColor, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700),
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}

// ✅ _FloatingTopBar Fixed (SafeArea + Height)
class _FloatingTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final bool isDark;

  const _FloatingTopBar({required this.title, required this.onBack, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // ✅ SafeArea-র উচ্চতা ক্যালকুলেট করা হয়েছে
    final double topPadding = MediaQuery.of(context).padding.top;
    final double barHeight = kToolbarHeight;

    return Positioned(
      top: topPadding + 10, // Status bar থেকে একটু নিচে
      left: 10,
      right: 10,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8), // Inner padding
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : AppColors.brandDark),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.brandDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class CommunityStandardsScreen extends StatelessWidget {
  const CommunityStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0F7FA);
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade500 : Colors.grey;

    return FloatingScaffold(
      title: 'Community Standards',
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: false, // ভেতরে SingleChildScrollView আছে তাই false
      bodyPadding: const EdgeInsets.all(20),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to FINDUS Community",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "These Community Standards apply to all workers (earners) and supporters (job makers) using FINDUS. "
                  "By using the app, you agree to follow these rules so that everyone can work, earn and hire safely.",
              style: TextStyle(
                color: textColor,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Last updated: January 2025",
              style: TextStyle(
                color: subTextColor,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 20),

            // ১. Respect & Safe Behaviour
            _SectionTitle("1. Respect & Safe Behaviour", titleColor),
            _Bullet(
                "Respect all users – no abuse, bullying, harassment, or threats in chat, calls or in-person.",
                textColor
            ),
            _Bullet(
                "Do not use hate speech or slurs based on religion, race, gender, caste, disability, or any personal identity.",
                textColor
            ),
            _Bullet(
                "Do not ask for or share sexually explicit content. Any sexual harassment, abuse or exploitation is strictly prohibited.",
                textColor
            ),
            _Bullet(
                "Always behave politely during jobs – both workers and supporters must follow basic respect and professionalism.",
                textColor
            ),

            const SizedBox(height: 18),

            // ২. Honest Profile & Identity
            _SectionTitle("2. Honest Profile & Identity", titleColor),
            _Bullet(
                "Use your real name, clear photo and correct information in your profile.",
                textColor
            ),
            _Bullet(
                "Do not create fake accounts, duplicate profiles, or pretend to be someone else.",
                textColor
            ),
            _Bullet(
                "Do not share or sell accounts – each account is for one real person only.",
                textColor
            ),
            _Bullet(
                "If you are using a team, agency or company, be honest and clear in your profile and job description.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৩. Jobs, Work & Content Guidelines
            _SectionTitle("3. Jobs, Work & Content Guidelines", titleColor),
            _Bullet(
                "Only post legal jobs and services. Any job related to drugs, weapons, human trafficking or other illegal work is not allowed.",
                textColor
            ),
            _Bullet(
                "Job descriptions must be clear, honest and not misleading. Mention real location, schedule and payment range.",
                textColor
            ),
            _Bullet(
                "Do not post spam jobs, fake jobs, or jobs just to collect personal data.",
                textColor
            ),
            _Bullet(
                "Do not share pirated software, cracked apps or any content that violates copyright or law.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৪. Payment & Wallet Safety
            _SectionTitle("4. Payment & Wallet Safety", titleColor),
            _Bullet(
                "Never ask or force someone to pay outside of agreed payment methods (e.g. wallet/bKash/Nagad/bank) if job was created in app.",
                textColor
            ),
            _Bullet(
                "Do not offer or accept bribes, fake discounts, or schemes that look like fraud.",
                textColor
            ),
            _Bullet(
                "Supporters should pay fairly for completed work as agreed. Workers should not demand unfair extra money.",
                textColor
            ),
            _Bullet(
                "FINDUS never asks for your wallet PIN, OTP or password in chat. Do not share these with anyone.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৫. Reviews & Ratings
            _SectionTitle("5. Reviews & Ratings", titleColor),
            _Bullet(
                "Give honest, fair reviews based on real experience – do not post fake reviews to promote or attack someone.",
                textColor
            ),
            _Bullet(
                "Do not threaten others with bad ratings to get discounts, free work or personal benefits.",
                textColor
            ),
            _Bullet(
                "Do not offer or accept money, gifts or favours in exchange for positive reviews.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৬. Communication & Chat Rules
            _SectionTitle("6. Communication & Chat Rules", titleColor),
            _Bullet(
                "Keep chat focused on work – details, timing, location, payment, safety. Avoid unnecessary personal questions.",
                textColor
            ),
            _Bullet(
                "Do not send spam messages, advertisements, chain messages or unrelated promotional links.",
                textColor
            ),
            _Bullet(
                "Do not share harmful links, malware, or suspicious files through chat.",
                textColor
            ),
            _Bullet(
                "If someone behaves badly, threatens you or makes you uncomfortable, block/report them using app options.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৭. In‑Person Safety
            _SectionTitle("7. In‑Person Safety", titleColor),
            _Bullet(
                "Always meet in safe, public or well-known locations when possible.",
                textColor
            ),
            _Bullet(
                "Share job details with a trusted friend/family if you are going to a new location.",
                textColor
            ),
            _Bullet(
                "Do not carry large amounts of cash; use safe digital payments where possible.",
                textColor
            ),
            _Bullet(
                "If you ever feel unsafe, leave the place and contact local authorities immediately.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৮. Prohibited Activities
            _SectionTitle("8. Prohibited Activities", titleColor),
            _Bullet(
                "Fraud, scam, phishing, or trying to steal money/personal data.",
                textColor
            ),
            _Bullet(
                "Selling fake services, fake documents, ID cards or certificates.",
                textColor
            ),
            _Bullet(
                "Using FINDUS to promote other illegal platforms or activities.",
                textColor
            ),
            _Bullet(
                "Harassment, stalking, blackmail, or sharing someone’s private information without consent.",
                textColor
            ),

            const SizedBox(height: 18),

            // ৯. Reporting & Enforcement
            _SectionTitle("9. Reporting & Enforcement", titleColor),
            _Bullet(
                "If you see any harmful, illegal or abusive behaviour, please report it from profile, chat or report section.",
                textColor
            ),
            _Bullet(
                "Our team may temporarily suspend, permanently ban or limit features of accounts that violate these standards.",
                textColor
            ),
            _Bullet(
                "Repeated or serious violations (fraud, abuse, harassment) may lead to legal action and sharing information with law enforcement.",
                textColor
            ),

            const SizedBox(height: 18),

            // ১০. Your Responsibilities
            _SectionTitle("10. Your Responsibilities", titleColor),
            _Bullet(
                "Read these standards carefully and follow them in all your activities on FINDUS.",
                textColor
            ),
            _Bullet(
                "Keep your account secure. Do not share your OTP, password or device access with others.",
                textColor
            ),
            _Bullet(
                "Update your profile information if something changes (phone number, location, skills, etc.).",
                textColor
            ),
            _Bullet(
                "Use common sense and caution – online and offline safety starts with you.",
                textColor
            ),

            const SizedBox(height: 20),

            Text(
              "We may update these Community Standards from time to time to keep everyone safe. "
                  "By continuing to use FINDUS, you agree to the latest version of these rules.",
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ---------- Reusable small widgets ----------

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  const _Bullet(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "•  ",
            style: TextStyle(fontSize: 13, height: 1.4, color: color),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
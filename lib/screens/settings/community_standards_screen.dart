import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class CommunityStandardsScreen extends StatelessWidget {
  const CommunityStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Community Standards",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to FINDUS Community",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "These Community Standards apply to all workers (earners) and supporters (job makers) using FINDUS. "
                  "By using the app, you agree to follow these rules so that everyone can work, earn and hire safely.",
              style: TextStyle(
                color: Colors.black87,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Last updated: January 2025",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 20),

            // ১. Respect & Safe Behaviour
            const _SectionTitle("1. Respect & Safe Behaviour"),
            const _Bullet(
              "Respect all users – no abuse, bullying, harassment, or threats in chat, calls or in-person.",
            ),
            const _Bullet(
              "Do not use hate speech or slurs based on religion, race, gender, caste, disability, or any personal identity.",
            ),
            const _Bullet(
              "Do not ask for or share sexually explicit content. Any sexual harassment, abuse or exploitation is strictly prohibited.",
            ),
            const _Bullet(
              "Always behave politely during jobs – both workers and supporters must follow basic respect and professionalism.",
            ),

            const SizedBox(height: 18),

            // ২. Honest Profile & Identity
            const _SectionTitle("2. Honest Profile & Identity"),
            const _Bullet(
              "Use your real name, clear photo and correct information in your profile.",
            ),
            const _Bullet(
              "Do not create fake accounts, duplicate profiles, or pretend to be someone else.",
            ),
            const _Bullet(
              "Do not share or sell accounts – each account is for one real person only.",
            ),
            const _Bullet(
              "If you are using a team, agency or company, be honest and clear in your profile and job description.",
            ),

            const SizedBox(height: 18),

            // ৩. Jobs, Work & Content Guidelines
            const _SectionTitle("3. Jobs, Work & Content Guidelines"),
            const _Bullet(
              "Only post legal jobs and services. Any job related to drugs, weapons, human trafficking or other illegal work is not allowed.",
            ),
            const _Bullet(
              "Job descriptions must be clear, honest and not misleading. Mention real location, schedule and payment range.",
            ),
            const _Bullet(
              "Do not post spam jobs, fake jobs, or jobs just to collect personal data.",
            ),
            const _Bullet(
              "Do not share pirated software, cracked apps or any content that violates copyright or law.",
            ),

            const SizedBox(height: 18),

            // ৪. Payment & Wallet Safety
            const _SectionTitle("4. Payment & Wallet Safety"),
            const _Bullet(
              "Never ask or force someone to pay outside of agreed payment methods (e.g. wallet/bKash/Nagad/bank) if job was created in app.",
            ),
            const _Bullet(
              "Do not offer or accept bribes, fake discounts, or schemes that look like fraud.",
            ),
            const _Bullet(
              "Supporters should pay fairly for completed work as agreed. Workers should not demand unfair extra money.",
            ),
            const _Bullet(
              "FINDUS never asks for your wallet PIN, OTP or password in chat. Do not share these with anyone.",
            ),

            const SizedBox(height: 18),

            // ৫. Reviews & Ratings
            const _SectionTitle("5. Reviews & Ratings"),
            const _Bullet(
              "Give honest, fair reviews based on real experience – do not post fake reviews to promote or attack someone.",
            ),
            const _Bullet(
              "Do not threaten others with bad ratings to get discounts, free work or personal benefits.",
            ),
            const _Bullet(
              "Do not offer or accept money, gifts or favours in exchange for positive reviews.",
            ),

            const SizedBox(height: 18),

            // ৬. Communication & Chat Rules
            const _SectionTitle("6. Communication & Chat Rules"),
            const _Bullet(
              "Keep chat focused on work – details, timing, location, payment, safety. Avoid unnecessary personal questions.",
            ),
            const _Bullet(
              "Do not send spam messages, advertisements, chain messages or unrelated promotional links.",
            ),
            const _Bullet(
              "Do not share harmful links, malware, or suspicious files through chat.",
            ),
            const _Bullet(
              "If someone behaves badly, threatens you or makes you uncomfortable, block/report them using app options.",
            ),

            const SizedBox(height: 18),

            // ৭. In‑Person Safety
            const _SectionTitle("7. In‑Person Safety"),
            const _Bullet(
              "Always meet in safe, public or well-known locations when possible.",
            ),
            const _Bullet(
              "Share job details with a trusted friend/family if you are going to a new location.",
            ),
            const _Bullet(
              "Do not carry large amounts of cash; use safe digital payments where possible.",
            ),
            const _Bullet(
              "If you ever feel unsafe, leave the place and contact local authorities immediately.",
            ),

            const SizedBox(height: 18),

            // ৮. Prohibited Activities
            const _SectionTitle("8. Prohibited Activities"),
            const _Bullet(
              "Fraud, scam, phishing, or trying to steal money/personal data.",
            ),
            const _Bullet(
              "Selling fake services, fake documents, ID cards or certificates.",
            ),
            const _Bullet(
              "Using FINDUS to promote other illegal platforms or activities.",
            ),
            const _Bullet(
              "Harassment, stalking, blackmail, or sharing someone’s private information without consent.",
            ),

            const SizedBox(height: 18),

            // ৯. Reporting & Enforcement
            const _SectionTitle("9. Reporting & Enforcement"),
            const _Bullet(
              "If you see any harmful, illegal or abusive behaviour, please report it from profile, chat or report section.",
            ),
            const _Bullet(
              "Our team may temporarily suspend, permanently ban or limit features of accounts that violate these standards.",
            ),
            const _Bullet(
              "Repeated or serious violations (fraud, abuse, harassment) may lead to legal action and sharing information with law enforcement.",
            ),

            const SizedBox(height: 18),

            // ১০. Your Responsibilities
            const _SectionTitle("10. Your Responsibilities"),
            const _Bullet(
              "Read these standards carefully and follow them in all your activities on FINDUS.",
            ),
            const _Bullet(
              "Keep your account secure. Do not share your OTP, password or device access with others.",
            ),
            const _Bullet(
              "Update your profile information if something changes (phone number, location, skills, etc.).",
            ),
            const _Bullet(
              "Use common sense and caution – online and offline safety starts with you.",
            ),

            const SizedBox(height: 20),

            const Text(
              "We may update these Community Standards from time to time to keep everyone safe. "
                  "By continuing to use FINDUS, you agree to the latest version of these rules.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------- Reusable small widgets ----------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "•  ",
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
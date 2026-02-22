import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'Terms & Conditions',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: _TermsContent(isDark: isDark),
    );
  }
}

class _TermsContent extends StatelessWidget {
  final bool isDark;
  const _TermsContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white.withOpacity(0.85) : Colors.black87;
    final headingColor = isDark ? Colors.white : AppColors.brandDark;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final accentColor = isDark ? AppColors.brandMain.withOpacity(0.8) : AppColors.brandMain;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Header Section
          _buildHeaderCard(
            headingColor: headingColor,
            subtitleColor: subtitleColor,
            cardBg: cardBg,
          ),

          const SizedBox(height: 20),

          // 📝 Introduction
          _buildIntroText(textColor),

          const SizedBox(height: 24),

          // 📌 Terms Sections
          _buildSection(
            number: "1",
            title: "Eligibility",
            content: [
              "You must be at least 18 years old to create an account or use FINDUS as a Job Maker (supporter) or Job Finder (worker/earner).",
              "You agree to provide accurate and up-to-date information about yourself and your work.",
              "You are responsible for maintaining the security of your device and account credentials.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "2",
            title: "Account & Profile",
            content: [
              "You are responsible for all activity that occurs under your FINDUS account.",
              "You agree not to share your login OTP or any verification code with others.",
              "You must not create fake profiles, impersonate another person, or provide misleading information about your skills, prices or work history.",
              "FINDUS may, at its sole discretion, suspend or terminate accounts that violate these Terms or create risk for other users.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "3",
            title: "Use of the Service",
            subtitle: "You agree that you will:",
            content: [
              "Use FINDUS only for lawful purposes.",
              "Respect other users, avoid harassment, threats, hate speech or abusive behaviour.",
              "Not use FINDUS to advertise illegal services, scams or harmful products.",
              "Not attempt to hack, reverse engineer or disrupt the app, servers or network.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "4",
            title: "Jobs, Payments & Responsibilities",
            subtitle:
            "FINDUS is a platform that connects Job Makers and Job Finders. FINDUS itself is not a party to any contract between users.",
            content: [
              "Job Makers (supporters) are solely responsible for clearly describing the work, time, place, payment amount and terms.",
              "Job Finders (workers/earners) are responsible for performing the agreed work honestly, safely and with due care.",
              "Payment terms must be agreed directly between parties. If FINDUS wallet or payment features are used, those transactions are still between users; FINDUS is not an employer or guarantor.",
              "FINDUS is not responsible for any loss, damage, injury or dispute that occurs during or after a job. Users must use their own judgement and take appropriate safety precautions.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "5",
            title: "Ratings, Reviews & Badges",
            content: [
              "Ratings and reviews should be honest and based on actual experience.",
              "You agree not to post fake, defamatory or abusive reviews.",
              "FINDUS may remove ratings or reviews that violate our community standards.",
              "Badges (Bronze/Silver/Gold/Platinum/Diamond) and 'Verified' or 'Trusted' labels are based on internal criteria (e.g. completed jobs, KYC, ratings) and may change over time.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "6",
            title: "KYC & Verification",
            content: [
              "For additional trust and safety, FINDUS may ask you to submit KYC documents (e.g. NID, driving license, photo).",
              "KYC verification is optional for basic use but may be required for certain features or higher trust levels.",
              "Providing fake or forged documents is strictly prohibited and may lead to account suspension or legal action.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "7",
            title: "Prohibited Content & Activities",
            subtitle: "You must NOT use FINDUS to:",
            content: [
              "Offer or request illegal work or services.",
              "Promote violence, self‑harm, hate, pornography or any content not suitable for a public marketplace.",
              "Spam, scam, or trick users into sharing money, passwords, OTPs or sensitive data.",
              "Upload viruses, malicious code or attempt to disrupt the app or other users.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
            isWarning: true,
          ),

          _buildSection(
            number: "8",
            title: "Suspension & Termination",
            subtitle: "FINDUS reserves the right to suspend, limit or terminate your access if:",
            content: [
              "You violate these Terms or our Privacy Policy.",
              "We detect fraudulent, abusive or dangerous behaviour.",
              "You repeatedly receive serious complaints from other users.",
              "We are required to do so by law or authority.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
            isWarning: true,
          ),

          _buildSection(
            number: "9",
            title: "Intellectual Property",
            content: [
              "The FINDUS app, logo, design, texts and code are protected by copyright and intellectual property laws.",
              "You may not copy, distribute or modify any part of the app without written permission.",
              "User‑generated content (e.g. profile text, photos, reviews) remains owned by the user, but you grant FINDUS a license to display and use it within the app.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "10",
            title: "Limitation of Liability",
            content: [
              "To the maximum extent permitted by law, FINDUS and its team shall not be liable for any indirect, incidental, special, consequential or punitive damages, including loss of money, data, reputation or other intangible losses resulting from your use of the app or any jobs arranged through it.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "11",
            title: "Changes to These Terms",
            content: [
              "We may update these Terms from time to time to reflect changes in law, features or policies. We will update the 'Last updated' date at the top and may notify you inside the app.",
              "By continuing to use FINDUS after changes, you agree to the updated Terms.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "12",
            title: "Governing Law",
            content: [
              "These Terms are governed by the laws of Bangladesh. Any dispute arising from or relating to the use of FINDUS may be subject to the jurisdiction of courts in Bangladesh.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildContactSection(
            textColor: textColor,
            headingColor: headingColor,
            cardBg: cardBg,
            accentColor: accentColor,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 🎯 Header Card
  Widget _buildHeaderCard({
    required Color headingColor,
    required Color subtitleColor,
    required Color cardBg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: AppColors.brandMain,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "FINDUS Terms & Conditions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 14,
                color: subtitleColor,
              ),
              const SizedBox(width: 6),
              Text(
                "Last updated: January 2025",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📝 Introduction Text
  Widget _buildIntroText(Color textColor) {
    return Text(
      "These Terms & Conditions ('Terms') govern your use of the FINDUS mobile application and related services. "
          "By creating an account or using FINDUS, you agree to these Terms, our Privacy Policy and all applicable laws of Bangladesh.",
      style: TextStyle(
        height: 1.6,
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // 📌 Section Builder
  Widget _buildSection({
    required String number,
    required String title,
    String? subtitle,
    required List<String> content,
    required Color textColor,
    required Color headingColor,
    required Color accentColor,
    required Color cardBg,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? Colors.orange.withOpacity(0.3)
              : accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isWarning
                      ? Colors.orange.withOpacity(0.15)
                      : accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isWarning ? Colors.orange : accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Content Points
          ...content.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // 📞 Contact Section
  Widget _buildContactSection({
    required Color textColor,
    required Color headingColor,
    required Color cardBg,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.1),
            accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_support_rounded,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "If you have any questions or concerns about these Terms & Conditions, you can contact us at:",
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email_rounded,
            label: "Email",
            value: "admin@findus.odditybd.shop",
            textColor: textColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            icon: Icons.subject_rounded,
            label: "Subject",
            value: "Terms & Conditions – FINDUS",
            textColor: textColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content (সাদা কার্ড ছাড়া)
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: const _TermsContent(), // সরাসরি _TermsContent ব্যবহার
          ),

          // Floating AppBar (KYC-style)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Title
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      height: 1.5,
      color: Colors.black87,
      fontSize: 13,
    );
    const headingStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: AppColors.brandDark,
      height: 2,
    );

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FINDUS Terms & Conditions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Last updated: January 2025",
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        SizedBox(height: 16),

        // Intro
        Text(
          "These Terms & Conditions ('Terms') govern your use of the FINDUS mobile application and related services. "
              "By creating an account or using FINDUS, you agree to these Terms, our Privacy Policy and all applicable laws of Bangladesh.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("1. Eligibility", style: headingStyle),
        Text(
          "• You must be at least 18 years old to create an account or use FINDUS as a Job Maker (supporter) or Job Finder (worker/earner).\n"
              "• You agree to provide accurate and up-to-date information about yourself and your work.\n"
              "• You are responsible for maintaining the security of your device and account credentials.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("2. Account & Profile", style: headingStyle),
        Text(
          "• You are responsible for all activity that occurs under your FINDUS account.\n"
              "• You agree not to share your login OTP or any verification code with others.\n"
              "• You must not create fake profiles, impersonate another person, or provide misleading information about your skills, prices or work history.\n"
              "• FINDUS may, at its sole discretion, suspend or terminate accounts that violate these Terms or create risk for other users.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("3. Use of the Service", style: headingStyle),
        Text(
          "You agree that you will:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Use FINDUS only for lawful purposes.\n"
              "• Respect other users, avoid harassment, threats, hate speech or abusive behaviour.\n"
              "• Not use FINDUS to advertise illegal services, scams or harmful products.\n"
              "• Not attempt to hack, reverse engineer or disrupt the app, servers or network.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("4. Jobs, Payments & Responsibilities", style: headingStyle),
        Text(
          "FINDUS is a platform that connects Job Makers and Job Finders. FINDUS itself is not a party to any contract between users.",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Job Makers (supporters) are solely responsible for clearly describing the work, time, place, payment amount and terms.\n"
              "• Job Finders (workers/earners) are responsible for performing the agreed work honestly, safely and with due care.\n"
              "• Payment terms must be agreed directly between parties. If FINDUS wallet or payment features are used, those transactions are still between users; FINDUS is not an employer or guarantor.\n"
              "• FINDUS is not responsible for any loss, damage, injury or dispute that occurs during or after a job. Users must use their own judgement and take appropriate safety precautions.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("5. Ratings, Reviews & Badges", style: headingStyle),
        Text(
          "• Ratings and reviews should be honest and based on actual experience.\n"
              "• You agree not to post fake, defamatory or abusive reviews.\n"
              "• FINDUS may remove ratings or reviews that violate our community standards.\n"
              "• Badges (Bronze/Silver/Gold/Platinum/Diamond) and 'Verified' or 'Trusted' labels are based on internal criteria (e.g. completed jobs, KYC, ratings) and may change over time.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("6. KYC & Verification", style: headingStyle),
        Text(
          "• For additional trust and safety, FINDUS may ask you to submit KYC documents (e.g. NID, driving license, photo).\n"
              "• KYC verification is optional for basic use but may be required for certain features or higher trust levels.\n"
              "• Providing fake or forged documents is strictly prohibited and may lead to account suspension or legal action.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("7. Prohibited Content & Activities", style: headingStyle),
        Text(
          "You must NOT use FINDUS to:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Offer or request illegal work or services.\n"
              "• Promote violence, self‑harm, hate, pornography or any content not suitable for a public marketplace.\n"
              "• Spam, scam, or trick users into sharing money, passwords, OTPs or sensitive data.\n"
              "• Upload viruses, malicious code or attempt to disrupt the app or other users.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("8. Suspension & Termination", style: headingStyle),
        Text(
          "FINDUS reserves the right to suspend, limit or terminate your access if:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• You violate these Terms or our Privacy Policy.\n"
              "• We detect fraudulent, abusive or dangerous behaviour.\n"
              "• You repeatedly receive serious complaints from other users.\n"
              "• We are required to do so by law or authority.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("9. Intellectual Property", style: headingStyle),
        Text(
          "• The FINDUS app, logo, design, texts and code are protected by copyright and intellectual property laws.\n"
              "• You may not copy, distribute or modify any part of the app without written permission.\n"
              "• User‑generated content (e.g. profile text, photos, reviews) remains owned by the user, but you grant FINDUS a license to display and use it within the app.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("10. Limitation of Liability", style: headingStyle),
        Text(
          "To the maximum extent permitted by law, FINDUS and its team shall not be liable for any indirect, incidental, special, consequential or punitive damages, "
              "including loss of money, data, reputation or other intangible losses resulting from your use of the app or any jobs arranged through it.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("11. Changes to These Terms", style: headingStyle),
        Text(
          "We may update these Terms from time to time to reflect changes in law, features or policies. We will update the 'Last updated' date at the top and may notify you inside the app. "
              "By continuing to use FINDUS after changes, you agree to the updated Terms.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("12. Governing Law", style: headingStyle),
        Text(
          "These Terms are governed by the laws of Bangladesh. Any dispute arising from or relating to the use of FINDUS may be subject to the jurisdiction of courts in Bangladesh.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("13. Contact Us", style: headingStyle),
        Text(
          "If you have any questions or concerns about these Terms & Conditions, you can contact us at:",
          style: textStyle,
        ),
        SizedBox(height: 4),
        Text(
          "Email: admin@findus.odditybd.shop\n"
              "Subject: Terms & Conditions – FINDUS",
          style: textStyle,
        ),

        SizedBox(height: 24),
      ],
    );
  }
}
// lib/screens/settings/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: const _PrivacyContent(),
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
                                  "Privacy Policy",
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

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

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
          "FINDUS Privacy Policy",
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
          "This Privacy Policy explains how FINDUS collects, uses, stores and protects your information when you use our mobile application and related services. "
              "By using FINDUS you agree to the collection and use of information in accordance with this Privacy Policy and applicable laws of Bangladesh and Google Play policies.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("1. Information We Collect", style: headingStyle),
        Text(
          "We collect the following types of information to operate and improve our service:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Account Information: Name, phone number, email (optional), profile photo, role (Job Maker / Job Finder), language preference.\n"
              "• Profile & Work Information: Skills, experience, price rate, location area, short bio, ratings, reviews and badges.\n"
              "• Location Data: Approximate or precise location (with your permission) to show nearby jobs and workers.\n"
              "• Usage Data: App pages visited, actions taken (search, chat, hire, wallet usage), device information (model, OS version), IP address and anonymized analytics.\n"
              "• Communication Data: Messages and call details (only meta information such as time and participant, not call recording) between workers and supporters inside the app.\n"
              "• Wallet & Payment Data: Transaction history, amounts, linked payment method type (e.g. bKash, Nagad, card). We do not store your wallet PIN, OTP or full card number.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("2. How We Use Your Information", style: headingStyle),
        Text(
          "We use your information to:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Create and manage your FINDUS account and profile.\n"
              "• Match and suggest nearby jobs and workers using location and profile data.\n"
              "• Show accurate profile details, badges, ratings and reviews so that others can make informed decisions.\n"
              "• Process wallet transactions, show balance and maintain transaction history.\n"
              "• Improve app performance, measure analytics and prevent fraud or abuse.\n"
              "• Send important notifications about jobs, payments, security alerts or app updates.\n"
              "• Provide customer support and respond to your queries or reports.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("3. Sharing of Information", style: headingStyle),
        Text(
          "We do not sell your personal information to third parties. We may share limited information in the following cases:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• With Other Users: When you apply for or post a job, basic profile information (name, photo, rating, location area, work details) is visible to relevant workers or supporters.\n"
              "• Service Providers: With secure third‑party services (e.g. payment gateways, analytics providers, cloud hosting) who help us run the app. They are required to protect your data and only use it for the agreed purpose.\n"
              "• Legal and Safety Reasons: If required by law, court order, or to protect the rights, property and safety of FINDUS users or the public, we may share necessary information with law enforcement or authorities.\n"
              "• Business Transfers: If we merge, acquire or sell part of our business, user data may be transferred as part of that transaction subject to this Privacy Policy.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("4. Location Data", style: headingStyle),
        Text(
          "Location services are used to show nearby jobs and workers, and to improve search relevance.",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• You can control location access from your device settings.\n"
              "• If you turn off location, some features (e.g. map view, nearby search) may not work correctly.\n"
              "• We do not continuously track your background location without your permission.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("5. Cookies & Analytics", style: headingStyle),
        Text(
          "We may use in‑app analytics and similar technologies to understand how users interact with the app. This helps us improve features, fix bugs and optimize performance. "
              "We do not use these tools to personally identify you without your consent.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("6. Data Retention", style: headingStyle),
        Text(
          "• We keep your account and profile data as long as your account is active.\n"
              "• Transaction and legal records may be kept for a longer period as required by law or for dispute resolution.\n"
              "• If you request to delete your account, we will remove or anonymize your personal data within a reasonable time, except where retention is legally required.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("7. Security", style: headingStyle),
        Text(
          "We use reasonable technical and organizational measures to protect your information (encryption where possible, secure storage, access controls, etc.). "
              "However, no system is 100% secure, and we cannot guarantee absolute security of data transmitted over the internet.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("8. Children's Privacy", style: headingStyle),
        Text(
          "FINDUS is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. "
              "If you believe a child has provided us data, please contact us so we can remove it.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("9. Your Rights & Controls", style: headingStyle),
        Text(
          "Depending on local law, you may have the right to:",
          style: textStyle,
        ),
        SizedBox(height: 6),
        Text(
          "• Access the personal data we hold about you.\n"
              "• Correct or update incorrect or incomplete information.\n"
              "• Request deletion of your account and associated data (subject to legal retention).\n"
              "• Change permissions like location, notifications or camera from device/app settings.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("10. Third‑Party Links & Services", style: headingStyle),
        Text(
          "Our app may contain links or integrations to third‑party websites or services (e.g. payment providers, map services). "
              "We are not responsible for the privacy practices of those third parties. Please review their privacy policies separately.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("11. Changes to This Policy", style: headingStyle),
        Text(
          "We may update this Privacy Policy from time to time. We will update the 'Last updated' date at the top and may notify you inside the app for major changes. "
              "By continuing to use FINDUS after changes, you agree to the updated Policy.",
          style: textStyle,
        ),

        SizedBox(height: 16),
        Text("12. Contact Us", style: headingStyle),
        Text(
          "If you have any questions or concerns about this Privacy Policy or how we handle your data, you can contact us at:",
          style: textStyle,
        ),
        SizedBox(height: 4),
        Text(
          "Email: admin@findus.odditybd.shop\n"
              "Subject: Privacy Policy – FINDUS",
          style: textStyle,
        ),

        SizedBox(height: 24),
      ],
    );
  }
}
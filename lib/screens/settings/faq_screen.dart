import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final textColor = isDark ? Colors.grey.shade300 : Colors.black87;

    final faqs = [
      {
        "q": "How does FINDUS work?",
        "a": "FINDUS connects Job Makers (supporters) and Job Finders (workers) in a hyper-local way. You can post a request or offer your service and chat directly.",
      },
      {
        "q": "How do I get a verified badge?",
        "a": "You need to complete KYC verification from the Settings > Verification section. Once approved, a blue verified badge will appear on your profile.",
      },
      {
        "q": "How is payment handled?",
        "a": "Currently payment is managed offline between worker and supporter. In future, in-app wallet and secure payment will be available.",
      },
      {
        "q": "How do I report a problem?",
        "a": "You can report from Help Center > Email Support, or contact our support team via chat with details of your issue.",
      },
      {
        "q": "FINDUS‑এ ব্যাজ (Badge) আর স্ট্যাটাস (Status) কী?",
        "a": "FINDUS‑এ ব্যাজ ও স্ট্যাটাস হলো আপনার প্রোফাইলের বিশ্বাসযোগ্যতা (trust), গুণগত মান (quality) এবং অ্যাক্টিভিটি (activity) দেখানোর ভিজ্যুয়াল প্রমাণ।",
      },
      {
        "q": "‘Top Rated’ স্ট্যাটাস কী? এটা কীভাবে পাবো?",
        "a": "Top Rated স্ট্যাটাস পাচ্ছেন সেই সব ইউজার, যাদের প্রোফাইলে ৫‑স্টার রেটিং থাকে। যখন আপনার গড় বা সাম্প্রতিক রেটিং ৫ স্টার থাকবে, তখনই Top Rated আইকন হাইলাইটেড হবে।",
      },
      {
        "q": "‘Trusted’ ব্যাজ কারা পায়?",
        "a": "Trusted ব্যাজ দেয়া হয় সেই ইউজারদের, যারা নিয়মিত সময়মতো পেমেন্ট করেন এবং অ্যাপের ভেতর অন‑টাইম পেমেন্ট হিস্ট্রি ভালো রাখেন।",
      },
      {
        "q": "‘Verified’ ব্যাজ কীভাবে পাবো?",
        "a": "Verified ব্যাজ পাওয়ার জন্য আপনাকে Settings > Verification থেকে KYC ভেরিফিকেশন সম্পূর্ণ করতে হবে। NID/Passport ও প্রয়োজন হলে সেলফি/লাইভ ফেস ভেরিফিকেশন জমা দিলে এবং আমাদের টিম অ্যাপ্রুভ করলে আপনার প্রোফাইলে Verified ব্যাজ দেখা যাবে।",
      },
      {
        "q": "Bronze / Silver / Gold / Platinum / Diamond ব্যাজগুলো কীভাবে কাজ করে?",
        "a": "এই ব্যাজগুলো আপনার লং‑টার্ম প্রগ্রেস দেখায়। বিভিন্ন টাস্ক ও অ্যাক্টিভিটি (জব কমপ্লিট করা, রিভিউ দেওয়া, ট্রানজ্যাকশন ইত্যাদি) করলে আপনি পয়েন্ট আর্ন করবেন। জমা হওয়া পয়েন্ট অনুযায়ী আপনার ব্যাজ আপগ্রেড হবে।",
      },
      {
        "q": "অন্য সব ব্যাজ কীভাবে আনলক হবে?",
        "a": "Top Rated / Trusted / Verified ছাড়া অন্য ব্যাজগুলো মূলত টাস্ক ও পয়েন্ট সিস্টেমের মাধ্যমে আনলক হবে। নির্দিষ্ট টাস্ক পূর্ণ করলে নতুন অ্যাচিভমেন্ট ও ব্যাজ আনলক হবে।",
      },
      {
        "q": "আমার ব্যাজ/স্ট্যাটাস কি অটো আপডেট হবে?",
        "a": "হ্যাঁ। আপনার নতুন রেটিং, পেমেন্ট হিস্ট্রি, KYC স্ট্যাটাস বা টাস্ক/পয়েন্ট আপডেট হওয়ার সাথে সাথে FINDUS স্বয়ংক্রিয়ভাবে ব্যাজ ও স্ট্যাটাস আপডেট করে।",
      },
    ];

    return FloatingScaffold(
      title: 'FAQ',
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.all(16),
      body: Column(
        children: faqs.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.withOpacity(0.1) : Colors.transparent,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  item['q']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    fontSize: 15,
                  ),
                ),
                iconColor: AppColors.brandMain,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      item['a']!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
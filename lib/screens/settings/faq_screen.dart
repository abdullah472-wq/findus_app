import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "q": "How does FINDUS work?",
        "a":
        "FINDUS connects Job Makers (supporters) and Job Finders (workers) in a hyper-local way. You can post a request or offer your service and chat directly.",
      },
      {
        "q": "How do I get a verified badge?",
        "a":
        "You need to complete KYC verification from the Settings > Verification section. Once approved, a blue verified badge will appear on your profile.",
      },
      {
        "q": "How is payment handled?",
        "a":
        "Currently payment is managed offline between worker and supporter. In future, in-app wallet and secure payment will be available.",
      },
      {
        "q": "How do I report a problem?",
        "a":
        "You can report from Help Center > Email Support, or contact our support team via chat with details of your issue.",
      },

      // ---- Badge & Status FAQ গুলো ----
      {
        "q": "FINDUS‑এ ব্যাজ (Badge) আর স্ট্যাটাস (Status) কী?",
        "a":
        "FINDUS‑এ ব্যাজ ও স্ট্যাটাস হলো আপনার প্রোফাইলের বিশ্বাসযোগ্যতা (trust), গুণগত মান (quality) এবং অ্যাক্টিভিটি (activity) দেখানোর ভিজ্যুয়াল প্রমাণ। এগুলো দেখে অন্য ইউজার বুঝতে পারে আপনি কতটা ভালো সার্ভিস দেন, সময়মতো পেমেন্ট করেন, ভেরিফাইড কিনা এবং কতটা অ্যাক্টিভ ইউজার।",
      },
      {
        "q": "‘Top Rated’ স্ট্যাটাস কী? এটা কীভাবে পাবো?",
        "a":
        "Top Rated স্ট্যাটাস পাচ্ছেন সেই সব ইউজার, যাদের প্রোফাইলে ৫‑স্টার রেটিং থাকে। যখন আপনার গড় বা সাম্প্রতিক রেটিং ৫ স্টার থাকবে, তখনই Top Rated আইকন হাইলাইটেড (রঙিন) হবে। ৫‑স্টারের কম থাকলে আইকন সাদা/ডিম কালারে (inactive) দেখা যাবে।",
      },
      {
        "q": "‘Trusted’ ব্যাজ কারা পায়?",
        "a":
        "Trusted ব্যাজ দেয়া হয় সেই ইউজারদের, যারা নিয়মিত সময়মতো পেমেন্ট করেন। অ্যাপের ভেতর অন‑টাইম পেমেন্ট হিস্ট্রি ভালো থাকলে (কাজ শেষ হওয়ার পর ঠিক সময়ে পেমেন্ট করলে) আপনি Trusted ব্যাজ পাবেন।",
      },
      {
        "q": "‘Verified’ ব্যাজ কীভাবে পাবো?",
        "a":
        "Verified ব্যাজ পাওয়ার জন্য আপনাকে Settings > Verification থেকে KYC ভেরিফিকেশন সম্পূর্ণ করতে হবে। NID/Passport ও প্রয়োজন হলে সেলফি/লাইভ ফেস ভেরিফিকেশন জমা দিলে এবং আমাদের টিম অ্যাপ্রুভ করলে আপনার প্রোফাইলে Verified ব্যাজ দেখা যাবে।",
      },
      {
        "q":
        "Bronze / Silver / Gold / Platinum / Diamond ব্যাজগুলো কীভাবে কাজ করে?",
        "a":
        "এই ব্যাজগুলো আপনার লং‑টার্ম প্রগ্রেস দেখায়। বিভিন্ন টাস্ক ও অ্যাক্টিভিটি (জব কমপ্লিট করা, রিভিউ দেওয়া, ট্রানজ্যাকশন ইত্যাদি) করলে আপনি পয়েন্ট আর্ন করবেন। জমা হওয়া পয়েন্ট অনুযায়ী আপনার ব্যাজ Bronze → Silver → Gold → Platinum → Diamond লেভেলে আপগ্রেড হবে।",
      },
      {
        "q": "অন্য সব ব্যাজ কীভাবে আনলক হবে?",
        "a":
        "Top Rated / Trusted / Verified ছাড়া অন্য ব্যাজগুলো মূলত টাস্ক ও পয়েন্ট সিস্টেমের মাধ্যমে আনলক হবে। যেমন নির্দিষ্ট সংখ্যক রিভিউ, কাজ, পেমেন্ট, ধারাবাহিক এক্টিভ ডে ইত্যাদি পূর্ণ করলে নতুন অ্যাচিভমেন্ট ও ব্যাজ আনলক হবে।",
      },
      {
        "q": "আমার ব্যাজ/স্ট্যাটাস কি অটো আপডেট হবে?",
        "a":
        "হ্যাঁ। আপনার নতুন রেটিং, পেমেন্ট হিস্ট্রি, KYC স্ট্যাটাস বা টাস্ক/পয়েন্ট আপডেট হওয়ার সাথে সাথে FINDUS স্বয়ংক্রিয়ভাবে ব্যাজ ও স্ট্যাটাস আপডেট করে। আলাদা করে কিছু করতে হয় না।",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          ListView.builder(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final item = faqs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    item['q']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandDark,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        item['a']!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
                                  "FAQ",
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
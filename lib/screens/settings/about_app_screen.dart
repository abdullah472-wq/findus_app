import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About App"),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: Container(
        color: const Color(0xFFE3F2FD), // 🔹 হালকা bg blue
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "FINDUS",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 20),
              Text(
                "FINDUS is a hyper-local service marketplace that connects Job Makers (supporters) and Job Finders (workers/earners) with trust, transparency and speed in Bangladesh.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                "Core Idea",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Text(
                "FINDUS helps people quickly find nearby workers like farmers, rickshaw pullers, cleaners, electricians, painters or computer experts, and helps workers get more jobs digitally instead of waiting on streets or corners.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                "Key Features",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Text(
                "• Dual Role: The same user can switch between “Job Maker / Supporter” and “Job Finder / Earner” in one account.\n"
                    "• Map Based Search: Like ride-sharing apps, users can see nearby workers on a live map and hire faster.\n"
                    "• Clear Profiles: Each worker profile shows photo, skills, fixed or negotiable price (e.g. 800৳ / day), completed jobs, ratings and badges.\n"
                    "• Emergency Directory: The app can also provide quick access to local emergency contacts like hospital, police, or fire service.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                "Trust & Quality",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Text(
                "• Badge System (Bronze → Diamond) based on activity, completed jobs and reviews.\n"
                    "• Verified profiles (KYC), transparent ratings and review history.\n"
                    "• Smart suggestion: FINDUS first suggests the closest workers, then prioritises those with better badges and ratings.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                "Technology",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Text(
                "FINDUS is built with Flutter so that the same codebase can run smoothly on both Android and iOS, with a fast and modern user experience.",
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                "In short, FINDUS aims to digitalize the local informal job market of Bangladesh and create a safe, fast and transparent bridge between people who want to work and people who need work done.",
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
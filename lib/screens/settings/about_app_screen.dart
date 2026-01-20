import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
                  "• Dual Role: The same user can switch between \"Job Maker / Supporter\" and \"Job Finder / Earner\" in one account.\n"
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
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "About App",
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
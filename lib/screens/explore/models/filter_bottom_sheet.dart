import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

/// Filter এর রেজাল্ট ধরে রাখার জন্য data class
class FilterOptions {
  final RangeValues priceRange;
  final bool verifiedOnly;
  final bool liveOnly;
  final String selectedGender;
  final double minExperience;

  /// নতুন ফিল্টার
  final bool topRatedOnly;
  final bool trustedOnly;

  const FilterOptions({
    required this.priceRange,
    required this.verifiedOnly,
    required this.liveOnly,
    required this.selectedGender,
    required this.minExperience,
    required this.topRatedOnly,
    required this.trustedOnly,
  });
}

/// ExploreScreen থেকে কল করার জন্য helper bottom sheet
Future<FilterOptions?> showFilterBottomSheet({
  required BuildContext context,
  required TextEditingController locationController,
  required RangeValues initialPriceRange,
  required bool initialVerifiedOnly,
  required bool initialLiveOnly,
  required String initialGender,
  required double initialMinExperience,

  /// নতুন প্যারামিটার
  required bool initialTopRatedOnly,
  required bool initialTrustedOnly,

  /// 🔹 ইউজার Pro / Business কিনা
  required bool isProUser,
}) {
  // লোকাল স্টেট ভেরিয়েবল
  RangeValues priceRange = initialPriceRange;
  bool verifiedOnly = initialVerifiedOnly;
  bool liveOnly = initialLiveOnly;
  String selectedGender = initialGender;
  double minExperience = initialMinExperience;

  bool topRatedOnly = initialTopRatedOnly;
  bool trustedOnly = initialTrustedOnly;

  // 🔹 Pro আপগ্রেড prompt
  void showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Upgrade your plan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "এই সব ফিল্টার ব্যবহার করতে Pro বা Business প্ল্যানে আপগ্রেড করুন।",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("LATER"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: সাবস্ক্রিপশন স্ক্রিনে নেয়া যাবে
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
            ),
            child: const Text("UPGRADE"),
          ),
        ],
      ),
    );
  }

  Widget proLabel(String text) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 6),
        const Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurple),
      ],
    );
  }

  return showModalBottomSheet<FilterOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.bgBlue,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(25),
                  children: [
                    // drag bar
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "Filter Search",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const Divider(height: 30),

                    // Location (Pro)
                    proLabel("Location"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      readOnly: !isProUser,
                      onTap: () {
                        if (!isProUser) showUpgradeDialog();
                      },
                      decoration: InputDecoration(
                        hintText: "Thana/District...",
                        prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        suffixIcon: const Icon(Icons.workspace_premium, color: Colors.deepPurple, size: 18),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Gender (Pro)
                    proLabel("Gender"),
                    const SizedBox(height: 12),
                    Row(
                      children: ["Any", "Male", "Female"].map((gender) {
                        final bool isSelected = selectedGender == gender;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(gender),
                            selected: isSelected,
                            selectedColor: AppColors.brandMain.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.brandDark : Colors.black,
                            ),
                            onSelected: (selected) {
                              if (!isProUser) {
                                showUpgradeDialog();
                                return;
                              }
                              if (selected) {
                                setModalState(() => selectedGender = gender);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // Experience (Pro)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        proLabel("Minimum Experience"),
                        Text(
                          minExperience == 0 ? 'New' : '${minExperience.toInt()}+ Years',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Slider(
                      value: minExperience,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: AppColors.brandMain,
                      label: minExperience == 0 ? 'New' : '${minExperience.toInt()} Yrs',
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => minExperience = v);
                      },
                    ),

                    const SizedBox(height: 15),

                    // Price Range (Pro)
                    proLabel("Price Range"),
                    RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      activeColor: AppColors.brandMain,
                      labels: RangeLabels(
                        "${priceRange.start.round()}",
                        "${priceRange.end.round()}",
                      ),
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => priceRange = v);
                      },
                    ),

                    const SizedBox(height: 15),

                    // Verified Only (Pro)
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Text("Verified Only", style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurple),
                        ],
                      ),
                      secondary: const Icon(Icons.verified, color: Colors.blue),
                      value: verifiedOnly,
                      activeColor: AppColors.brandMain,
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => verifiedOnly = v ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Top Rated Only (Pro)
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Text("Top Rated Only (5★)", style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurple),
                        ],
                      ),
                      secondary: const Icon(Icons.star, color: Colors.orange),
                      value: topRatedOnly,
                      activeColor: AppColors.brandMain,
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => topRatedOnly = v ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Trusted Only (Pro)
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Text("Trusted Only", style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurple),
                        ],
                      ),
                      secondary: const Icon(Icons.handshake, color: Colors.green),
                      value: trustedOnly,
                      activeColor: AppColors.brandMain,
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => trustedOnly = v ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Live Only (Pro)
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Text("Live Only", style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurple),
                        ],
                      ),
                      secondary: const Icon(Icons.podcasts, color: Colors.redAccent),
                      value: liveOnly,
                      activeColor: AppColors.brandMain,
                      onChanged: (v) {
                        if (!isProUser) {
                          showUpgradeDialog();
                          return;
                        }
                        setModalState(() => liveOnly = v ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 30),

                    // APPLY FILTERS button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            FilterOptions(
                              priceRange: priceRange,
                              verifiedOnly: verifiedOnly,
                              liveOnly: liveOnly,
                              selectedGender: selectedGender,
                              minExperience: minExperience,
                              topRatedOnly: topRatedOnly,
                              trustedOnly: trustedOnly,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "APPLY FILTERS",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
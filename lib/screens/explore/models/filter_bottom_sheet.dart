import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

/// Filter data class
class FilterOptions {
  final RangeValues priceRange;
  final bool verifiedOnly;
  final bool liveOnly;
  final String selectedGender;
  final double minExperience;
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

/// Helper bottom sheet function
Future<FilterOptions?> showFilterBottomSheet({
  required BuildContext context,
  required TextEditingController locationController,
  required RangeValues initialPriceRange,
  required bool initialVerifiedOnly,
  required bool initialLiveOnly,
  required String initialGender,
  required double initialMinExperience,
  required bool initialTopRatedOnly,
  required bool initialTrustedOnly,
  required bool isProUser,
}) {
  RangeValues priceRange = initialPriceRange;
  bool verifiedOnly = initialVerifiedOnly;
  bool liveOnly = initialLiveOnly;
  String selectedGender = initialGender;
  double minExperience = initialMinExperience;
  bool topRatedOnly = initialTopRatedOnly;
  bool trustedOnly = initialTrustedOnly;

  // ✅ ডার্ক মোড চেক
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetColor = isDark ? const Color(0xFF1E1E1E) : AppColors.bgBlue;
  final textColor = isDark ? Colors.white : AppColors.brandDark;
  final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
  final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

  void showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text("Upgrade your plan", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Text("Upgrade to Pro or Business plan to unlock advanced filters.", style: TextStyle(color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("LATER")),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white),
            child: const Text("UPGRADE"),
          ),
        ],
      ),
    );
  }

  Widget proLabel(String text) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(width: 6),
        const Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurpleAccent),
      ],
    );
  }

  return showModalBottomSheet<FilterOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(25),
                  children: [
                    Center(
                      child: Container(
                        width: 50, height: 5,
                        decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Text("Filter Search", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    Divider(height: 30, color: isDark ? Colors.grey[800] : Colors.grey[300]),

                    // Location
                    proLabel("Location"),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      readOnly: !isProUser,
                      style: TextStyle(color: textColor),
                      onTap: () { if (!isProUser) showUpgradeDialog(); },
                      decoration: InputDecoration(
                        hintText: "Thana/District...",
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.location_city, color: hintColor),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        suffixIcon: const Icon(Icons.workspace_premium, color: Colors.deepPurpleAccent, size: 18),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Gender
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
                            backgroundColor: inputFillColor,
                            labelStyle: TextStyle(color: isSelected ? AppColors.brandMain : textColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? AppColors.brandMain : Colors.transparent),
                            ),
                            onSelected: (selected) {
                              if (!isProUser) { showUpgradeDialog(); return; }
                              if (selected) setModalState(() => selectedGender = gender);
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // Experience
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        proLabel("Min Experience"),
                        Text(minExperience == 0 ? 'New' : '${minExperience.toInt()}+ Years', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      ],
                    ),
                    Slider(
                      value: minExperience, min: 0, max: 10, divisions: 10,
                      activeColor: AppColors.brandMain,
                      inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
                      label: minExperience == 0 ? 'New' : '${minExperience.toInt()} Yrs',
                      onChanged: (v) {
                        if (!isProUser) { showUpgradeDialog(); return; }
                        setModalState(() => minExperience = v);
                      },
                    ),

                    const SizedBox(height: 15),

                    // Price Range
                    proLabel("Price Range"),
                    RangeSlider(
                      values: priceRange, min: 0, max: 10000, divisions: 100,
                      activeColor: AppColors.brandMain,
                      inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
                      labels: RangeLabels("${priceRange.start.round()}", "${priceRange.end.round()}"),
                      onChanged: (v) {
                        if (!isProUser) { showUpgradeDialog(); return; }
                        setModalState(() => priceRange = v);
                      },
                    ),

                    const SizedBox(height: 15),

                    // Toggles
                    _buildSwitchTile("Verified Only", Icons.verified, Colors.blue, verifiedOnly, (v) {
                      if (!isProUser) { showUpgradeDialog(); return; }
                      setModalState(() => verifiedOnly = v ?? false);
                    }, textColor),

                    _buildSwitchTile("Top Rated Only (5★)", Icons.star, Colors.orange, topRatedOnly, (v) {
                      if (!isProUser) { showUpgradeDialog(); return; }
                      setModalState(() => topRatedOnly = v ?? false);
                    }, textColor),

                    _buildSwitchTile("Trusted Only", Icons.handshake, Colors.green, trustedOnly, (v) {
                      if (!isProUser) { showUpgradeDialog(); return; }
                      setModalState(() => trustedOnly = v ?? false);
                    }, textColor),

                    _buildSwitchTile("Live Only", Icons.podcasts, Colors.redAccent, liveOnly, (v) {
                      if (!isProUser) { showUpgradeDialog(); return; }
                      setModalState(() => liveOnly = v ?? false);
                    }, textColor),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, FilterOptions(
                            priceRange: priceRange,
                            verifiedOnly: verifiedOnly,
                            liveOnly: liveOnly,
                            selectedGender: selectedGender,
                            minExperience: minExperience,
                            topRatedOnly: topRatedOnly,
                            trustedOnly: trustedOnly,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("APPLY FILTERS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
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

Widget _buildSwitchTile(String title, IconData icon, Color iconColor, bool value, ValueChanged<bool?> onChanged, Color textColor) {
  return CheckboxListTile(
    title: Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(width: 6),
        const Icon(Icons.workspace_premium, size: 16, color: Colors.deepPurpleAccent),
      ],
    ),
    secondary: Icon(icon, color: iconColor),
    value: value,
    activeColor: AppColors.brandMain,
    checkColor: Colors.white,
    onChanged: onChanged,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.trailing,
  );
}
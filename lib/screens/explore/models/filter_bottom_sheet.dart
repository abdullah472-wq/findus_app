// lib/screens/explore/models/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

/// ═══════════════════════════════════════════════════════════
/// FILTER OPTIONS DATA CLASS
/// ═══════════════════════════════════════════════════════════
class FilterOptions {
  final RangeValues priceRange;
  final bool verifiedOnly;
  final bool liveOnly;
  final String selectedGender;
  final double minExperience;
  final bool topRatedOnly;
  final bool trustedOnly;
  final String? selectedCategory;
  final double? maxDistance;
  final String sortBy;

  const FilterOptions({
    required this.priceRange,
    required this.verifiedOnly,
    required this.liveOnly,
    required this.selectedGender,
    required this.minExperience,
    required this.topRatedOnly,
    required this.trustedOnly,
    this.selectedCategory,
    this.maxDistance,
    this.sortBy = 'nearest',
  });

  /// ✅ Default factory
  factory FilterOptions.defaults() {
    return const FilterOptions(
      priceRange: RangeValues(0, 10000),
      verifiedOnly: false,
      liveOnly: false,
      selectedGender: 'Any',
      minExperience: 0,
      topRatedOnly: false,
      trustedOnly: false,
      selectedCategory: null,
      maxDistance: null,
      sortBy: 'nearest',
    );
  }

  /// ✅ Copy with method
  FilterOptions copyWith({
    RangeValues? priceRange,
    bool? verifiedOnly,
    bool? liveOnly,
    String? selectedGender,
    double? minExperience,
    bool? topRatedOnly,
    bool? trustedOnly,
    String? selectedCategory,
    double? maxDistance,
    String? sortBy,
  }) {
    return FilterOptions(
      priceRange: priceRange ?? this.priceRange,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      liveOnly: liveOnly ?? this.liveOnly,
      selectedGender: selectedGender ?? this.selectedGender,
      minExperience: minExperience ?? this.minExperience,
      topRatedOnly: topRatedOnly ?? this.topRatedOnly,
      trustedOnly: trustedOnly ?? this.trustedOnly,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// ✅ Check if any filter is active
  bool get hasActiveFilters {
    return verifiedOnly ||
        liveOnly ||
        topRatedOnly ||
        trustedOnly ||
        selectedGender != 'Any' ||
        minExperience > 0 ||
        priceRange.start > 0 ||
        priceRange.end < 10000 ||
        selectedCategory != null ||
        maxDistance != null;
  }

  /// ✅ Count active filters
  int get activeFilterCount {
    int count = 0;
    if (verifiedOnly) count++;
    if (liveOnly) count++;
    if (topRatedOnly) count++;
    if (trustedOnly) count++;
    if (selectedGender != 'Any') count++;
    if (minExperience > 0) count++;
    if (priceRange.start > 0 || priceRange.end < 10000) count++;
    if (selectedCategory != null) count++;
    if (maxDistance != null) count++;
    return count;
  }
}

/// ═══════════════════════════════════════════════════════════
/// FILTER BOTTOM SHEET FUNCTION
/// ═══════════════════════════════════════════════════════════
Future<FilterOptions?> showFilterBottomSheet({
  required BuildContext context,
  required TextEditingController locationController,
  FilterOptions? currentFilters,  // ✅ এটাই সঠিক parameter
  required bool isProUser,
}) {
  // Use current filters or defaults
  final initial = currentFilters ?? FilterOptions.defaults();

  return showModalBottomSheet<FilterOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FilterBottomSheetContent(
      locationController: locationController,
      initialFilters: initial,
      isProUser: isProUser,
    ),
  );
}

/// ═══════════════════════════════════════════════════════════
/// FILTER BOTTOM SHEET WIDGET
/// ═══════════════════════════════════════════════════════════
class _FilterBottomSheetContent extends StatefulWidget {
  final TextEditingController locationController;
  final FilterOptions initialFilters;
  final bool isProUser;

  const _FilterBottomSheetContent({
    required this.locationController,
    required this.initialFilters,
    required this.isProUser,
  });

  @override
  State<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  // Filter States
  late RangeValues _priceRange;
  late bool _verifiedOnly;
  late bool _liveOnly;
  late String _selectedGender;
  late double _minExperience;
  late bool _topRatedOnly;
  late bool _trustedOnly;
  late String? _selectedCategory;
  late double? _maxDistance;
  late String _sortBy;

  // UI States
  bool _showAdvanced = false;

  // Categories
  static const List<String> _categories = [
    'All',
    'Electrician',
    'Plumber',
    'Driver',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Helper',
    'Other',
  ];

  // Sort Options
  static const List<Map<String, String>> _sortOptions = [
    {'value': 'nearest', 'label': 'Nearest First'},
    {'value': 'rating', 'label': 'Highest Rated'},
    {'value': 'price_low', 'label': 'Price: Low to High'},
    {'value': 'price_high', 'label': 'Price: High to Low'},
    {'value': 'experience', 'label': 'Most Experienced'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    _priceRange = widget.initialFilters.priceRange;
    _verifiedOnly = widget.initialFilters.verifiedOnly;
    _liveOnly = widget.initialFilters.liveOnly;
    _selectedGender = widget.initialFilters.selectedGender;
    _minExperience = widget.initialFilters.minExperience;
    _topRatedOnly = widget.initialFilters.topRatedOnly;
    _trustedOnly = widget.initialFilters.trustedOnly;
    _selectedCategory = widget.initialFilters.selectedCategory;
    _maxDistance = widget.initialFilters.maxDistance;
    _sortBy = widget.initialFilters.sortBy;
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _verifiedOnly = false;
      _liveOnly = false;
      _selectedGender = 'Any';
      _minExperience = 0;
      _topRatedOnly = false;
      _trustedOnly = false;
      _selectedCategory = null;
      _maxDistance = null;
      _sortBy = 'nearest';
      widget.locationController.clear();
    });
  }

  void _showUpgradeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.deepPurpleAccent),
            const SizedBox(width: 10),
            Text(
              "Pro Feature",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        content: Text(
          "Upgrade to Pro or Business plan to unlock advanced filters like location, gender, experience, and more!",
          style: TextStyle(color: textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("LATER", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to subscription screen
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("UPGRADE NOW"),
          ),
        ],
      ),
    );
  }

  FilterOptions _buildFilterOptions() {
    return FilterOptions(
      priceRange: _priceRange,
      verifiedOnly: _verifiedOnly,
      liveOnly: _liveOnly,
      selectedGender: _selectedGender,
      minExperience: _minExperience,
      topRatedOnly: _topRatedOnly,
      trustedOnly: _trustedOnly,
      selectedCategory: _selectedCategory == 'All' ? null : _selectedCategory,
      maxDistance: _maxDistance,
      sortBy: _sortBy,
    );
  }

  int get _activeFilterCount {
    return _buildFilterOptions().activeFilterCount;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(textColor, dividerColor),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Sort By (Free)
                    _buildSortSection(textColor, inputFillColor, isDark),
                    const SizedBox(height: 20),

                    // Category Filter (Free)
                    _buildCategorySection(textColor, inputFillColor, isDark),
                    const SizedBox(height: 20),

                    // Quick Toggles (Free basic, Pro advanced)
                    _buildQuickToggles(textColor),
                    const SizedBox(height: 20),

                    // Advanced Filters (Expandable)
                    _buildAdvancedSection(textColor, inputFillColor, isDark, dividerColor),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Bottom Actions
              _buildBottomActions(isDark),
            ],
          ),
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// HEADER
  /// ═══════════════════════════════════════════════════════════
  Widget _buildHeader(Color textColor, Color dividerColor) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Filter & Sort",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandMain,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Reset"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 20, color: dividerColor),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// SORT SECTION
  /// ═══════════════════════════════════════════════════════════
  Widget _buildSortSection(Color textColor, Color inputFillColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sort By",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              dropdownColor: inputFillColor,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: textColor.withOpacity(0.6),
              ),
              items: _sortOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(
                    option['label']!,
                    style: TextStyle(color: textColor),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _sortBy = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// CATEGORY SECTION
  /// ═══════════════════════════════════════════════════════════
  Widget _buildCategorySection(Color textColor, Color inputFillColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = (_selectedCategory ?? 'All') == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: AppColors.brandMain.withOpacity(0.2),
              backgroundColor: inputFillColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.brandMain : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.brandMain : Colors.transparent,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category == 'All' ? null : category;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// QUICK TOGGLES
  /// ═══════════════════════════════════════════════════════════
  Widget _buildQuickToggles(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Filters",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: "Verified",
              icon: Icons.verified,
              iconColor: Colors.blue,
              isSelected: _verifiedOnly,
              onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
              textColor: textColor,
            ),
            _buildFilterChip(
              label: "Top Rated",
              icon: Icons.star,
              iconColor: Colors.orange,
              isSelected: _topRatedOnly,
              onTap: () => setState(() => _topRatedOnly = !_topRatedOnly),
              textColor: textColor,
            ),
            _buildFilterChip(
              label: "Trusted",
              icon: Icons.shield,
              iconColor: Colors.green,
              isSelected: _trustedOnly,
              onTap: () => setState(() => _trustedOnly = !_trustedOnly),
              textColor: textColor,
            ),
            _buildFilterChip(
              label: "Online Now",
              icon: Icons.circle,
              iconColor: Colors.greenAccent,
              isSelected: _liveOnly,
              onTap: () => setState(() => _liveOnly = !_liveOnly),
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandMain.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandMain : textColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.brandMain : iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.brandMain : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// ADVANCED FILTERS SECTION
  /// ═══════════════════════════════════════════════════════════
  Widget _buildAdvancedSection(
      Color textColor,
      Color inputFillColor,
      bool isDark,
      Color dividerColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Header
        InkWell(
          onTap: () {
            if (!widget.isProUser) {
              _showUpgradeDialog();
              return;
            }
            setState(() => _showAdvanced = !_showAdvanced);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: inputFillColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Advanced Filters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.workspace_premium,
                      size: 18,
                      color: Colors.deepPurpleAccent,
                    ),
                  ],
                ),
                Icon(
                  _showAdvanced
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),

        // Expandable Content
        if (_showAdvanced && widget.isProUser) ...[
          const SizedBox(height: 20),

          // Location
          _buildProLabel("Location", textColor),
          const SizedBox(height: 8),
          TextField(
            controller: widget.locationController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Enter thana, district...",
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              prefixIcon: Icon(Icons.location_city, color: textColor.withOpacity(0.5)),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gender
          _buildProLabel("Gender", textColor),
          const SizedBox(height: 8),
          Row(
            children: ["Any", "Male", "Female"].map((gender) {
              final isSelected = _selectedGender == gender;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(gender),
                  selected: isSelected,
                  selectedColor: AppColors.brandMain.withOpacity(0.2),
                  backgroundColor: inputFillColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.brandMain : textColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.brandMain : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedGender = gender);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Experience
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProLabel("Min Experience", textColor),
              Text(
                _minExperience == 0 ? 'New' : '${_minExperience.toInt()}+ Years',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          Slider(
            value: _minExperience,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: AppColors.brandMain,
            inactiveColor: dividerColor,
            label: _minExperience == 0 ? 'New' : '${_minExperience.toInt()} Yrs',
            onChanged: (v) => setState(() => _minExperience = v),
          ),
          const SizedBox(height: 10),

          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProLabel("Price Range", textColor),
              Text(
                "৳${_priceRange.start.toInt()} - ৳${_priceRange.end.toInt()}",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.brandMain,
            inactiveColor: dividerColor,
            labels: RangeLabels(
              "৳${_priceRange.start.toInt()}",
              "৳${_priceRange.end.toInt()}",
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
        ],
      ],
    );
  }

  Widget _buildProLabel(String text, Color textColor) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: textColor,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.workspace_premium,
          size: 14,
          color: Colors.deepPurpleAccent,
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// BOTTOM ACTIONS
  /// ═══════════════════════════════════════════════════════════
  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel Button
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Apply Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _buildFilterOptions()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "APPLY FILTERS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
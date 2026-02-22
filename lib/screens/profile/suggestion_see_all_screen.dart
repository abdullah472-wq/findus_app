import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

// ✅ Import your existing filter
import 'package:findus_app/screens/explore/models/filter_bottom_sheet.dart';

// Screens
import 'unified_profile_screen.dart';
import 'unified_profile_constants.dart';

class SuggestionSeeAllScreen extends StatefulWidget {
  final SuggestionType type;
  final String targetRole;
  final String? excludeUid;

  const SuggestionSeeAllScreen({
    super.key,
    required this.type,
    required this.targetRole,
    this.excludeUid,
  });

  @override
  State<SuggestionSeeAllScreen> createState() => _SuggestionSeeAllScreenState();
}

class _SuggestionSeeAllScreenState extends State<SuggestionSeeAllScreen> {
  // Pagination
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;

  // ✅ Filter States
  FilterOptions _currentFilters = FilterOptions.defaults();
  final TextEditingController _locationController = TextEditingController();
  bool _isProUser = false; // TODO: Get from user data

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreData();
    }
  }

  // ✅ Check if user is Pro
  Future<void> _checkProStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final subscriptionType = doc.data()?['subscription_type']?.toString() ?? 'free';
      setState(() {
        _isProUser = subscriptionType != 'free';
      });
    } catch (e) {
      debugPrint("❌ Error checking pro status: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER HANDLING
  // ═══════════════════════════════════════════════════════════════

  void _openFilterSheet() async {
    final result = await showFilterBottomSheet(
      context: context,
      locationController: _locationController,
      currentFilters: _currentFilters,
      isProUser: _isProUser,
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
      });
      _refreshData();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    setState(() => _isInitialLoading = true);

    try {
      final query = _buildQuery().limit(_pageSize);
      final snapshot = await query.get();

      final filteredDocs = _filterDocs(snapshot.docs);

      setState(() {
        _users = filteredDocs;
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading data: $e");
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoading = true);

    try {
      final query = _buildQuery()
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize);

      final snapshot = await query.get();
      final filteredDocs = _filterDocs(snapshot.docs);

      setState(() {
        _users.addAll(filteredDocs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading more: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    _lastDoc = null;
    _hasMore = true;
    await _loadInitialData();
  }

  // ✅ Filter docs based on FilterOptions
  List<DocumentSnapshot> _filterDocs(List<DocumentSnapshot> docs) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return docs.where((d) {
      if (d.id == currentUid) return false;
      if (widget.excludeUid != null && d.id == widget.excludeUid) return false;

      final data = d.data() as Map<String, dynamic>;

      // ✅ Apply local filters
      if (_currentFilters.verifiedOnly && data['kyc_completed'] != true) {
        return false;
      }

      if (_currentFilters.liveOnly && data['isOnline'] != true) {
        return false;
      }

      if (_currentFilters.topRatedOnly) {
        final rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
        if (rating < 4.5) return false;
      }

      if (_currentFilters.trustedOnly) {
        final rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
        final completed = int.tryParse(data['completedCount']?.toString() ?? '0') ?? 0;
        if (completed < 50 || rating < 4.5) return false;
      }

      if (_currentFilters.selectedGender != 'Any') {
        final gender = data['gender']?.toString().toLowerCase() ?? '';
        if (gender != _currentFilters.selectedGender.toLowerCase()) {
          return false;
        }
      }

      if (_currentFilters.minExperience > 0) {
        final exp = double.tryParse(data['experienceYears']?.toString() ?? '0') ?? 0.0;
        if (exp < _currentFilters.minExperience) return false;
      }

      // Price filter
      if (_currentFilters.priceRange.start > 0 || _currentFilters.priceRange.end < 10000) {
        final priceText = data['priceText']?.toString() ?? '';
        final price = double.tryParse(priceText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
        if (price < _currentFilters.priceRange.start || price > _currentFilters.priceRange.end) {
          return false;
        }
      }

      // Location filter (text match)
      if (_locationController.text.trim().isNotEmpty) {
        final location = (data['location'] ?? '').toString().toLowerCase();
        final searchText = _locationController.text.trim().toLowerCase();
        if (!location.contains(searchText)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ✅ Build query based on type and sort
  Query<Map<String, dynamic>> _buildQuery() {
    final collection = FirebaseFirestore.instance.collection('users');
    Query<Map<String, dynamic>> query = collection.where('userRole', isEqualTo: widget.targetRole);

    // Type-based initial filters
    switch (widget.type) {
      case SuggestionType.sponsored:
        query = query.where('isSponsored', isEqualTo: true);
        break;
      case SuggestionType.topRated:
        query = query.where('rating', isGreaterThanOrEqualTo: 4.0);
        break;
      case SuggestionType.newUsers:
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo));
        break;
      case SuggestionType.recommended:
        query = query.where('kyc_completed', isEqualTo: true);
        break;
      default:
        break;
    }

    // ✅ Apply sort
    switch (_currentFilters.sortBy) {
      case 'rating':
        query = query.orderBy('rating', descending: true);
        break;
      case 'price_low':
        query = query.orderBy('price', descending: false);
        break;
      case 'price_high':
        query = query.orderBy('price', descending: true);
        break;
      case 'experience':
        query = query.orderBy('experienceYears', descending: true);
        break;
      case 'nearest':
      default:
        query = query.orderBy('xpPoints', descending: true);
        break;
    }

    return query;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : AppColors.brandLight;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      showBack: true,
      title: widget.type.title.toUpperCase(),
      backgroundColor: scaffoldBg,
      titleColor: titleColor,
      iconColor: titleColor,
      actions: [
        // ✅ Filter Button with Badge
        _buildFilterButton(isDark),
      ],
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: widget.type.color,
        child: _buildContent(isDark),
      ),
    );
  }

  // ✅ Filter Button with Active Count Badge
  Widget _buildFilterButton(bool isDark) {
    final activeCount = _currentFilters.activeFilterCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.tune,
              size: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: _openFilterSheet,
            padding: EdgeInsets.zero,
            tooltip: 'Filter',
          ),

          // Active filter count badge
          if (activeCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.brandMain,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isInitialLoading) {
      return _buildVerticalShimmer(isDark);
    }

    if (_users.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Header Info
        SliverToBoxAdapter(
          child: _buildHeaderInfo(isDark),
        ),

        // ✅ Active Filters Chips (if any)
        if (_currentFilters.hasActiveFilters)
          SliverToBoxAdapter(
            child: _buildActiveFiltersChips(isDark),
          ),

        // User List
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final doc = _users[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildUserCard(doc.id, data, isDark);
            },
            childCount: _users.length,
          ),
        ),

        // Loading More
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // End Message
        if (!_hasMore && _users.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildEndMessage(isDark),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  // ✅ Show Active Filters as Chips
  Widget _buildActiveFiltersChips(bool isDark) {
    final chips = <Widget>[];

    if (_currentFilters.verifiedOnly) {
      chips.add(_filterChip("Verified", Icons.verified, Colors.blue, isDark));
    }
    if (_currentFilters.topRatedOnly) {
      chips.add(_filterChip("Top Rated", Icons.star, Colors.orange, isDark));
    }
    if (_currentFilters.trustedOnly) {
      chips.add(_filterChip("Trusted", Icons.shield, Colors.green, isDark));
    }
    if (_currentFilters.liveOnly) {
      chips.add(_filterChip("Online", Icons.circle, Colors.greenAccent, isDark));
    }
    if (_currentFilters.selectedGender != 'Any') {
      chips.add(_filterChip(_currentFilters.selectedGender, Icons.person, Colors.purple, isDark));
    }
    if (_currentFilters.minExperience > 0) {
      chips.add(_filterChip("${_currentFilters.minExperience.toInt()}+ Yrs", Icons.work, Colors.teal, isDark));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...chips,
          // Clear all button
          GestureDetector(
            onTap: () {
              setState(() {
                _currentFilters = FilterOptions.defaults();
                _locationController.clear();
              });
              _refreshData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear_all, size: 14, color: Colors.red[400]),
                  const SizedBox(width: 4),
                  Text(
                    "Clear All",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
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

  Widget _filterChip(String label, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER INFO
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeaderInfo(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.type.color.withOpacity(0.15),
            widget.type.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.type.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.type.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.type.icon, color: widget.type.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.type.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(),
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.type.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_users.length}${_hasMore ? '+' : ''}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    switch (widget.type) {
      case SuggestionType.topRated:
        return "Users with 4.0+ star ratings";
      case SuggestionType.newUsers:
        return "Joined in the last 30 days";
      case SuggestionType.recentlyActive:
        return "Active in the last 7 days";
      case SuggestionType.recommended:
        return "Verified users with high XP";
      case SuggestionType.similarProfiles:
        return "Similar to your profile";
      case SuggestionType.sponsored:
        return "Featured & sponsored users";
      default:
        return "Browse all users";
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER CARD (Same UniversalWorkerCard)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserCard(String uid, Map<String, dynamic> data, bool isDark) {
    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();
    final String role = (data['userRole'] ?? 'finder').toString();
    final String location = (data['location'] ?? 'Location not set').toString();
    final double rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
    final int completed = int.tryParse(data['completedCount']?.toString() ?? '0') ?? 0;
    final int followers = int.tryParse(data['followersCount']?.toString() ?? '0') ?? 0;
    final bool isVerified = data['kyc_completed'] == true;
    final String priceText = data['priceText']?.toString() ?? 'Negotiable';
    final bool isOnline = data['isOnline'] == true;

    final String roleLabel = role == 'finder' ? 'Worker' : 'Supporter';

    // Tag based on type
    String? tagText;
    Color? tagColor;
    IconData? tagIcon;

    switch (widget.type) {
      case SuggestionType.topRated:
        tagText = "Top Rated";
        tagColor = Colors.orange;
        tagIcon = Icons.star;
        break;
      case SuggestionType.newUsers:
        tagText = "New";
        tagColor = Colors.green;
        tagIcon = Icons.fiber_new;
        break;
      case SuggestionType.recommended:
        tagText = "Recommended";
        tagColor = AppColors.brandMain;
        tagIcon = Icons.thumb_up;
        break;
      case SuggestionType.recentlyActive:
        tagText = "Active";
        tagColor = Colors.teal;
        tagIcon = Icons.access_time;
        break;
      case SuggestionType.similarProfiles:
        tagText = "Similar";
        tagColor = Colors.purple;
        tagIcon = Icons.people;
        break;
      case SuggestionType.sponsored:
        tagText = "Featured";
        tagColor = Colors.amber;
        tagIcon = Icons.verified;
        break;
      default:
        break;
    }

    void navigateToProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProfileScreen(
            uid: uid,
            isOwner: false,
            showBack: true,
          ),
        ),
      );
    }

    return UniversalWorkerCard(
      id: uid,
      name: name,
      role: roleLabel,
      imageUrl: image,
      address: location,
      rating: rating.toStringAsFixed(1),
      completed: completed.toString(),
      reviews: "0",
      price: priceText,
      followersCount: followers,
      isVerifiedWorker: isVerified,
      isTopRated: rating >= 4.9,
      isTrusted: completed >= 50 && rating >= 4.5,
      isOnline: isOnline,
      showOnlineStatus: true,
      showStats: true,
      showActionButtons: true,
      showSaveButton: true,
      showShareButton: true,
      primaryButtonText: "View Profile",
      jobLabel: role == 'finder' ? "JOBS" : "HIRED",
      tagText: tagText,
      tagColor: tagColor,
      tagIcon: tagIcon,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: navigateToProfile,
      onViewProfileTap: navigateToProfile,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY, END, SHIMMER STATES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.type.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.type.icon,
                size: 60,
                color: widget.type.color.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No ${widget.type.title} Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentFilters.hasActiveFilters
                  ? "Try adjusting your filters"
                  : "Check back later for more suggestions",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_currentFilters.hasActiveFilters)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFilters = FilterOptions.defaults();
                    _locationController.clear();
                  });
                  _refreshData();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text("Clear Filters"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.type.color,
                  side: BorderSide(color: widget.type.color),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type.color,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndMessage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: widget.type.color.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              "You've seen all ${widget.type.title.toLowerCase()}",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalShimmer(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
// lib/screens/explore/explore_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// Constants & Services
import '../../../constants/app_colors.dart';
import 'package:findus_app/services/user_role_service.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/services/notification_service.dart';

// Models
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/explore/models/worker_profile_bottom_sheet.dart';
import 'package:findus_app/screens/explore/models/filter_bottom_sheet.dart';

// Screens
import 'package:findus_app/screens/profile/earn_post_screen.dart';
import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/screens/explore/responsive_worker_pin.dart';
import 'package:findus_app/screens/explore/notifications_page.dart';
import '../auth/login_screen.dart';
import '../emergency_screen.dart';
import 'profile_sidebar_menu.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ═══════════════════════════════════════════════════════════
  // CONTROLLERS & KEYS
  // ═══════════════════════════════════════════════════════════
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final MapController _mapController;
  final TextEditingController _locationSearchController = TextEditingController();
  final TextEditingController _mainSearchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ═══════════════════════════════════════════════════════════
  // LOCATION STATE
  // ═══════════════════════════════════════════════════════════
  LatLng? _userCurrentLocation;
  final LatLng _dhakaLocation = const LatLng(23.8103, 90.4125);
  final Distance _distance = const Distance();
  static bool _hasInitialZoomHappened = false;
  double _currentZoom = 2.5;
  double _currentRotation = 0.0;
  bool _isSearchingLocation = true;

  // ═══════════════════════════════════════════════════════════
  // SEARCH STATE
  // ═══════════════════════════════════════════════════════════
  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;
  bool _isSearchingWorker = false;
  List<Map<String, dynamic>> _searchSuggestions = [];
  List<String> _recentSearches = [];
  Timer? _suggestDebounce;

  final List<String> _trendingSearches = [
    'Electrician',
    'Plumber',
    'Driver',
    'Cleaner',
    'Carpenter',
    'Painter',
    'Helper',
  ];

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION STATE
  // ═══════════════════════════════════════════════════════════
  bool _hasUnreadNotifs = false;
  int _unreadNotifCount = 0;

  // ═══════════════════════════════════════════════════════════
  // ROLE & FILTER STATE
  // ═══════════════════════════════════════════════════════════
  bool _isWorker = false;
  RangeValues _priceRange = const RangeValues(0, 10000);
  bool _verifiedOnly = false;
  bool _liveOnly = false;
  String _selectedGender = "Any";
  double _minExperience = 0;
  String _sortBy = 'nearest';
  String? _selectedCategory;
  double? _maxDistance;
  bool _topRatedOnly = false;
  bool _trustedOnly = false;

  // ═══════════════════════════════════════════════════════════
  // WORKER DATA
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filteredWorkers = [];
  Set<String> _blockedUserIds = {};

  // ═══════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════
  StreamSubscription<List<Map<String, dynamic>>>? _postsSub;
  StreamSubscription<QuerySnapshot>? _notifSub;

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _initSearchListeners();
    _loadRecentSearches();
    _loadUserRole();
    _loadBlockedUsers();
    _handleWelcomeLogic();
    _listenToNotifications();
    _updateMapQuest();

    _isSearchingLocation = true;

    if (!_hasInitialZoomHappened) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startInitialZoomSequence());
    } else {
      _isSearchingLocation = false;
      _checkLocationOnly();
    }
  }

  void _initSearchListeners() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = true);
        _updateSearchSuggestions(_mainSearchController.text);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_searchFocusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });

    _mainSearchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _mainSearchController.dispose();
    _searchFocusNode.dispose();
    _postsSub?.cancel();
    _notifSub?.cancel();
    _suggestDebounce?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // WELCOME & QUESTS
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleWelcomeLogic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'welcome_sent_${user.uid}';
    final hasSentWelcome = prefs.getBool(key) ?? false;

    if (!hasSentWelcome) {
      await NotificationService.sendNotificationToUser(
        toUserId: user.uid,
        title: "Welcome to FindUs! 🎉",
        body: "Need help getting started? Tap here to visit our Help Center.",
        type: "help_center",
        data: {},
      );
      await prefs.setBool(key, true);
    }
  }

  Future<void> _updateMapQuest() async {
    await AchievementService.incrementProgress('daily_explore');
    await AchievementService.syncWeeklyChestFromServer();
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════
  void _listenToNotifications() {
    _notifSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notifSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((q) {
      if (mounted) {
        setState(() {
          _unreadNotifCount = q.docs.length;
          _hasUnreadNotifs = q.docs.isNotEmpty;
        });
      }
    });
  }

  void _showNotificationPanel() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  // ═══════════════════════════════════════════════════════════
  // BLOCKED USERS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadBlockedUsers() async {
    final users = await BlockedUserService().getBlockedUsers();
    if (mounted) {
      setState(() => _blockedUserIds = users.map((u) => u['id'] ?? '').toSet());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ROLE MANAGEMENT
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadUserRole() async {
    try {
      final role = await UserRoleService.getCurrentUserRole();
      final isFinder = UserRoleService.isFinder(role);

      if (mounted) {
        setState(() => _isWorker = isFinder);
        _listenToPosts();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isWorker = false);
        _listenToPosts();
      }
    }
  }

  Future<void> _toggleRole() async {
    final newRole = _isWorker ? 'maker' : 'finder';
    await UserRoleService.updateUserRole(newRole);

    setState(() => _isWorker = !_isWorker);
    _listenToPosts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Switched to ${_isWorker ? 'Earning' : 'Hiring'} Mode"),
          backgroundColor: _isWorker ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // POST LISTENER
  // ═══════════════════════════════════════════════════════════
  void _listenToPosts() {
    _postsSub?.cancel();

    _postsSub = PostService.streamPins().listen((posts) {
      if (!mounted) return;

      final all = posts.map((post) {
        double lat = 0.0;
        double lng = 0.0;
        if (post['latitude'] != null) {
          lat = (post['latitude'] as num).toDouble();
        }
        if (post['longitude'] != null) {
          lng = (post['longitude'] as num).toDouble();
        }

        final postOwnerRole = post['ownerRole'];
        final targetRole = _isWorker ? 'maker' : 'finder';

        if (postOwnerRole != null && postOwnerRole != targetRole) {
          return null;
        }

        return {
          ...post,
          'location': LatLng(lat, lng),
        };
      }).where((element) => element != null).cast<Map<String, dynamic>>().toList();

      setState(() {
        _allWorkers = all;
        _filteredWorkers = List.from(_allWorkers);
      });
    }, onError: (error) {
      debugPrint("❌ Error in streamPins: $error");
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LOCATION METHODS
  // ═══════════════════════════════════════════════════════════
  Future<void> _checkLocationOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocationEnabledInSettings = prefs.getBool('settings_location_enabled') ?? true;

    if (!isLocationEnabledInSettings) return;

    try {
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _userCurrentLocation = LatLng(p.latitude, p.longitude);
          _currentZoom = 15.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _startInitialZoomSequence() async {
    final start = DateTime.now();

    Future<void> waitMin2Seconds() async {
      const int minMillis = 2000;
      final int elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed < minMillis) {
        await Future.delayed(Duration(milliseconds: minMillis - elapsed));
      }
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await waitMin2Seconds();
        _cancelLoadingWithoutZoom();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await waitMin2Seconds();
        _cancelLoadingWithoutZoom();
        return;
      }

      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await waitMin2Seconds();

      _animateMapMove(LatLng(p.latitude, p.longitude), 15.0, const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _userCurrentLocation = LatLng(p.latitude, p.longitude);
          _isSearchingLocation = false;
        });
      }
      _hasInitialZoomHappened = true;
    } catch (_) {
      await waitMin2Seconds();
      _cancelLoadingWithoutZoom();
    }
  }

  void _cancelLoadingWithoutZoom() {
    if (mounted) {
      setState(() {
        _isSearchingLocation = false;
        _userCurrentLocation = null;
      });
      _hasInitialZoomHappened = true;
    }
  }

  Future<void> _zoomToUser() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() => _userCurrentLocation = LatLng(p.latitude, p.longitude));
        _animateMapMove(_userCurrentLocation!, 16.0, const Duration(milliseconds: 400));
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _showLocationServiceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              "Location Disabled",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Please enable location services to find your position on the map.",
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("ENABLE NOW"),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAP ANIMATIONS
  // ═══════════════════════════════════════════════════════════
  void _animateMapMove(LatLng dest, double destZoom, Duration duration) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(duration: duration, vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _animateMapRotationTo(double targetDeg, {Duration duration = const Duration(milliseconds: 300)}) {
    final start = _currentRotation;
    final rotTween = Tween<double>(begin: start, end: targetDeg);
    final controller = AnimationController(duration: duration, vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      if (!mounted) return;
      _mapController.rotate(rotTween.evaluate(animation));
    });

    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _resetNorth() => _animateMapRotationTo(0);

  // ═══════════════════════════════════════════════════════════
  // SEARCH METHODS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);

    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    await prefs.setStringList('recent_searches', _recentSearches);
    if (mounted) setState(() {});
  }

  Future<void> _removeRecentSearch(String search) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(search);
    await prefs.setStringList('recent_searches', _recentSearches);
    if (mounted) setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (mounted) {
      setState(() => _recentSearches = []);
    }
  }

  void _clearSearch() {
    _mainSearchController.clear();
    _updateSearchSuggestions('');
    setState(() => _filteredWorkers = List.from(_allWorkers));
  }

  void _updateSearchSuggestions(String query) {
    _suggestDebounce?.cancel();

    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isLoadingSuggestions = false;
        _showSuggestions = _searchFocusNode.hasFocus;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _suggestDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final results = <Map<String, dynamic>>[];

      // Recent matches
      final recentMatches = _recentSearches
          .where((s) => s.toLowerCase().contains(q))
          .take(2)
          .map((s) => {'type': 'recent', 'text': s});
      results.addAll(recentMatches);

      // Worker matches
      final workerMatches = _allWorkers.where((item) {
        final name = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        final role = (item['roleLabel'] ?? item['role'] ?? '').toString().toLowerCase();
        final address = (item['address'] ?? '').toString().toLowerCase();
        return name.contains(q) || role.contains(q) || address.contains(q);
      }).take(5).map((w) => {...w, 'type': 'worker'});
      results.addAll(workerMatches);

      // Trending matches
      final trendingMatches = _trendingSearches
          .where((s) => s.toLowerCase().contains(q))
          .take(2)
          .map((s) => {'type': 'trending', 'text': s});
      results.addAll(trendingMatches);

      setState(() {
        _searchSuggestions = results.take(8).toList();
        _isLoadingSuggestions = false;
        _showSuggestions = results.isNotEmpty || _searchFocusNode.hasFocus;
      });
    });
  }

  void _executeSearch(String query) {
    final searchText = query.trim();

    setState(() => _showSuggestions = false);
    _searchFocusNode.unfocus();

    if (searchText.isNotEmpty) {
      _saveRecentSearch(searchText);
      _mainSearchController.text = searchText;
    }

    _performSearch(searchText);
    _maybeMoveCameraToSearchLocation(mainQuery: searchText);
  }

  void _performSearch(String query) {
    final searchText = query.trim();

    if (searchText.isEmpty) {
      setState(() {
        _filteredWorkers = List.from(_allWorkers);
        _isSearchingWorker = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearchingWorker = true);

    Future.microtask(() {
      if (!mounted) return;

      final searchTextLower = searchText.toLowerCase();
      final locationText = _locationSearchController.text.toLowerCase().trim();

      List<Map<String, dynamic>> results = _allWorkers.where((worker) {
        final name = (worker['title'] ?? worker['name'] ?? '').toString().toLowerCase();
        final role = (worker['roleLabel'] ?? worker['role'] ?? '').toString().toLowerCase();
        final address = (worker['address'] ?? '').toString().toLowerCase();
        final rating = (worker['rating'] ?? 0).toDouble();
        final experience = (worker['experience'] ?? 0).toDouble();
        final price = (worker['price'] ?? 0).toDouble();

        final matchesMainQuery = searchTextLower.isEmpty ||
            name.contains(searchTextLower) ||
            role.contains(searchTextLower) ||
            address.contains(searchTextLower);

        final matchesLocationQuery = locationText.isEmpty ||
            address.contains(locationText) ||
            name.contains(locationText);

        final matchesVerified = !_verifiedOnly || worker['verified'] == true;
        final matchesLive = !_liveOnly || worker['isLive'] == true;
        final matchesGender = _selectedGender == "Any" || worker['gender'] == _selectedGender;
        final matchesExp = experience >= _minExperience;
        final matchesTopRated = !_topRatedOnly || rating >= 4.5;
        final matchesTrusted = !_trustedOnly || worker['trusted'] == true || worker['isTrusted'] == true;
        final matchesPrice = price >= _priceRange.start && price <= _priceRange.end;

        return matchesMainQuery &&
            matchesLocationQuery &&
            matchesVerified &&
            matchesLive &&
            matchesGender &&
            matchesExp &&
            matchesTopRated &&
            matchesTrusted &&
            matchesPrice;
      }).toList();

      _sortResults(results);

      setState(() {
        _isSearchingWorker = false;
        _filteredWorkers = results;
        _showSuggestions = false;
      });

      if (results.isNotEmpty) {
        final firstLoc = results.first['location'];
        if (firstLoc is LatLng) {
          _animateMapMove(firstLoc, 15.0, const Duration(milliseconds: 500));
        }
      }
    });
  }

  void _sortResults(List<Map<String, dynamic>> results) {
    results.sort((a, b) {
      switch (_sortBy) {
        case 'nearest':
          final aLoc = a['location'];
          final bLoc = b['location'];
          if (aLoc is LatLng && bLoc is LatLng) {
            final aDist = _getDistanceKm(aLoc);
            final bDist = _getDistanceKm(bLoc);
            if (aDist != null && bDist != null) {
              final diff = aDist.compareTo(bDist);
              if (diff != 0) return diff;
            }
          }
          return (b['rating'] ?? 0).toDouble().compareTo((a['rating'] ?? 0).toDouble());
        case 'rating':
          return (b['rating'] ?? 0).toDouble().compareTo((a['rating'] ?? 0).toDouble());
        case 'price_low':
          return (a['price'] ?? 0).toDouble().compareTo((b['price'] ?? 0).toDouble());
        case 'price_high':
          return (b['price'] ?? 0).toDouble().compareTo((a['price'] ?? 0).toDouble());
        case 'experience':
          return (b['experience'] ?? 0).toDouble().compareTo((a['experience'] ?? 0).toDouble());
        default:
          return 0;
      }
    });
  }

  double? _getDistanceKm(LatLng workerLocation) {
    if (_userCurrentLocation == null) return null;
    return _distance.as(LengthUnit.Kilometer, _userCurrentLocation!, workerLocation);
  }

  // ═══════════════════════════════════════════════════════════
  // GEOCODING
  // ═══════════════════════════════════════════════════════════
  Future<LatLng?> _geocodeLocation(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final latLngMatch = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)\s*$').firstMatch(q);
    if (latLngMatch != null) {
      final lat = double.tryParse(latLngMatch.group(1)!);
      final lng = double.tryParse(latLngMatch.group(3)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=1&countrycodes=bd',
    );

    try {
      final resp = await http
          .get(uri, headers: {'User-Agent': 'findus-app/1.0'})
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final arr = jsonDecode(resp.body);
        if (arr is List && arr.isNotEmpty) {
          final lat = double.tryParse(arr[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(arr[0]['lon']?.toString() ?? '');
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (_) {}

    return null;
  }

  bool _looksLikeLocation(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t.contains(',')) return true;
    return false;
  }

  Future<void> _maybeMoveCameraToSearchLocation({String? mainQuery}) async {
    final locText = _locationSearchController.text.trim();
    final mainText = (mainQuery ?? '').trim();
    String q = locText.isNotEmpty ? locText : (_looksLikeLocation(mainText) ? mainText : '');
    if (q.isEmpty) return;
    final pos = await _geocodeLocation(q);
    if (pos != null) {
      _animateMapMove(pos, 13.5, const Duration(milliseconds: 600));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FILTER PANEL
  // ═══════════════════════════════════════════════════════════
  Future<void> _showFilterPanel() async {
    bool isProUser = false;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final plan = (data['subscription_plan'] ?? 'free').toString().toLowerCase();
          isProUser = plan == 'pro' || plan == 'business';
        }
      } catch (e) {
        debugPrint("Error fetching user plan: $e");
      }
    }

    final currentFilters = FilterOptions(
      priceRange: _priceRange,
      verifiedOnly: _verifiedOnly,
      liveOnly: _liveOnly,
      selectedGender: _selectedGender,
      minExperience: _minExperience,
      topRatedOnly: _topRatedOnly,
      trustedOnly: _trustedOnly,
      selectedCategory: _selectedCategory,
      maxDistance: _maxDistance,
      sortBy: _sortBy,
    );

    final result = await showFilterBottomSheet(
      context: context,
      locationController: _locationSearchController,
      currentFilters: currentFilters,
      isProUser: isProUser,
    );

    if (result == null) return;

    setState(() {
      _priceRange = result.priceRange;
      _verifiedOnly = result.verifiedOnly;
      _liveOnly = result.liveOnly;
      _selectedGender = result.selectedGender;
      _minExperience = result.minExperience;
      _topRatedOnly = result.topRatedOnly;
      _trustedOnly = result.trustedOnly;
      _sortBy = result.sortBy;
      _selectedCategory = result.selectedCategory;
      _maxDistance = result.maxDistance;
    });

    _performSearch(_mainSearchController.text);
    _maybeMoveCameraToSearchLocation(mainQuery: _mainSearchController.text);
  }

  // ═══════════════════════════════════════════════════════════
  // WORKER PROFILE
  // ═══════════════════════════════════════════════════════════
  Worker _mapDataToWorker(Map<String, dynamic> data) {
    final String uid = (data['ownerId'] ?? data['uid'] ?? data['userId'] ?? data['id'] ?? '').toString().trim();

    String userRole = 'finder';
    if (data['ownerRole'] != null) {
      userRole = data['ownerRole'].toString();
    } else if (data['userRole'] != null) {
      userRole = data['userRole'].toString();
    }

    String priceText = 'Negotiable';
    num? price;
    final priceData = data['price'];
    if (priceData is num) {
      price = priceData;
      priceText = '৳$priceData';
    } else if (priceData is String) {
      priceText = priceData;
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(priceData);
      if (match != null) price = num.tryParse(match.group(0)!);
    }

    double rating = 0.0;
    if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    } else {
      rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
    }

    return Worker(
      uid: uid,
      postId: data['id']?.toString(),
      name: (data['title'] ?? data['name'] ?? 'Unknown').toString(),
      userRole: userRole,
      image: (data['image'] ?? '').toString(),
      location: (data['address'] ?? 'Bangladesh').toString(),
      priceText: (data['priceLabel'] ?? priceText).toString(),
      price: price,
      rating: rating,
      kycCompleted: data['verified'] == true,
      isVerified: data['verified'] == true,
      experience: double.tryParse(data['experience']?.toString() ?? '0'),
      gender: data['gender']?.toString(),
      languages: data['language'] != null ? [data['language'].toString()] : null,
      isLive: data['isLive'] ?? false,
      isTrusted: data['trusted'] ?? false,
      isPromoted: data['isPromoted'] ?? false,
      phone: data['phone']?.toString(),
    );
  }

  void _showProfilePopup(Map<String, dynamic> data) async {
    final workerModel = _mapDataToWorker(data);
    await showWorkerProfileBottomSheet(
      context: context,
      data: data,
      isWorker: _isWorker,
      allWorkers: _allWorkers,
      workerModel: workerModel,
    );
    _loadBlockedUsers();
  }

  // ═══════════════════════════════════════════════════════════
  // EMERGENCY & DIALOGS
  // ═══════════════════════════════════════════════════════════
  void _openEmergency() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Login Required"),
        content: const Text(
          "You need to login to create or post jobs.\n\nPlease login to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
            ),
            child: const Text("LOGIN NOW"),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD METHOD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade500;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileSideBar(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // MAP
          _buildMap(isDark),

          // TAP TO CLOSE SUGGESTIONS
          if (_showSuggestions)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _searchFocusNode.unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(),
              ),
            ),

          // LOADING OVERLAY
          if (_isSearchingLocation || _isSearchingWorker)
            _buildLoadingOverlay(),

          // SEARCH BAR & SUGGESTIONS
          if (!_isSearchingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 15,
              right: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(isDark, bgColor, textColor, hintColor),
                  if (_showSuggestions)
                    _buildSuggestionsDropdown(isDark, bgColor, textColor, subtitleColor),
                ],
              ),
            ),

          // Search bar এর নিচে results count দেখাও
          if (!_isSearchingLocation && _mainSearchController.text.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 75,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandMain,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_filteredWorkers.length} found",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // _buildMap() এর পরে add করো
          if (!_isSearchingLocation && _filteredWorkers.isEmpty)
            Positioned(
              bottom: 200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "No workers found",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Try adjusting your filters or search in a different area",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        _clearSearch();
                        setState(() {
                          _priceRange = const RangeValues(0, 10000);
                          _verifiedOnly = false;
                          _liveOnly = false;
                          _topRatedOnly = false;
                          _trustedOnly = false;
                          _selectedGender = "Any";
                          _minExperience = 0;
                        });
                        _performSearch('');
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Filters"),
                    ),
                  ],
                ),
              ),
            ),

          // RIGHT SIDE BUTTONS
          if (!_isSearchingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + 75,
              right: 15,
              child: Column(
                children: [
                  _buildNotificationButton(isDark, bgColor),
                  const SizedBox(height: 12),
                  _mapBtn(Icons.tune, AppColors.brandDark, _showFilterPanel, isDark),
                  const SizedBox(height: 12),
                  _compassBtn(isDark),
                  const SizedBox(height: 12),
                  _mapBtn(Icons.my_location, AppColors.brandMain, _zoomToUser, isDark),
                ],
              ),
            ),

          // EMERGENCY BUTTON
          if (!_isSearchingLocation)
            Positioned(
              bottom: 250,
              right: 20,
              child: _mapBtn(Icons.medical_services_outlined, Colors.redAccent, _openEmergency, isDark),
            ),

          // ROLE SWITCH
          if (!_isSearchingLocation)
            Positioned(
              bottom: 180,
              right: 20,
              child: _buildRoleSwitchButton(),
            ),

          // ZOOM CONTROLS
          if (!_isSearchingLocation)
            Positioned(
              bottom: 110,
              left: 20,
              child: _buildZoomControls(isDark),
            ),

          // POST FAB
          if (!_isSearchingLocation)
            Positioned(
              bottom: 110,
              right: 20,
              child: _buildPostFAB(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════
  Widget _buildMap(bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _dhakaLocation,
        initialZoom: 2.5,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        onPositionChanged: (camera, hasGesture) {
          if (_currentZoom != camera.zoom || _currentRotation != camera.rotation) {
            setState(() {
              _currentZoom = camera.zoom;
              _currentRotation = camera.rotation;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.findus.app',
          tileBuilder: isDark
              ? (context, widget, tile) => ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1, 0, 0, 0, 255,
              0, -1, 0, 0, 255,
              0, 0, -1, 0, 255,
              0, 0, 0, 1, 0,
            ]),
            child: widget,
          )
              : null,
        ),
        MarkerLayer(
          markers: _filteredWorkers
              .where((data) => !_blockedUserIds.contains((data['id'] ?? data['ownerId']).toString()))
              .map((data) {
            final LatLng workerLoc = data['location'] is LatLng
                ? data['location']
                : const LatLng(23.8103, 90.4125);

            final double markerSize = _getMarkerSize(_currentZoom);

            return Marker(
              point: workerLoc,
              width: markerSize,
              height: markerSize,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showProfilePopup(data),
                child: ResponsiveWorkerPin(
                  key: ValueKey("${data['id']}_${_currentZoom.toInt()}"),
                  role: (data['roleLabel'] ?? data['role'] ?? 'Worker').toString(),
                  price: data['priceLabel']?.toString() ?? data['price']?.toString() ?? 'Negotiable',
                  isLive: data['isLive'] ?? false,
                  currentZoom: _currentZoom,
                  distanceKm: _getDistanceKm(workerLoc),
                  isPromoted: data['isPromoted'] ?? false,
                ),
              ),
            );
          }).toList(),
        ),
        if (_userCurrentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userCurrentLocation!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.brandMain,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Filter button এ badge দেখাও
  Widget _buildFilterButton(bool isDark) {
    final activeCount = _getActiveFilterCount();

    return GestureDetector(
      onTap: _showFilterPanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.tune, color: AppColors.brandDark),
          ),
          if (activeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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

  int _getActiveFilterCount() {
    int count = 0;
    if (_verifiedOnly) count++;
    if (_liveOnly) count++;
    if (_topRatedOnly) count++;
    if (_trustedOnly) count++;
    if (_selectedGender != "Any") count++;
    if (_minExperience > 0) count++;
    if (_priceRange.start > 0 || _priceRange.end < 10000) count++;
    if (_selectedCategory != null) count++;
    return count;
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/search.json', width: 200, height: 200),
              const SizedBox(height: 20),
              Text(
                _isSearchingLocation ? "Finding your location..." : "Searching workers...",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color bgColor, Color textColor, Color hintColor) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          // App Icon
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brandDark,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset("assets/images/app_icon.png", fit: BoxFit.contain),
            ),
          ),

          const SizedBox(width: 12),

          // Search Input
          Expanded(
            child: TextField(
              controller: _mainSearchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: textColor, fontSize: 15),
              textInputAction: TextInputAction.search,
              onTap: () {
                setState(() => _showSuggestions = true);
                _updateSearchSuggestions(_mainSearchController.text);
              },
              onChanged: _updateSearchSuggestions,
              onSubmitted: _executeSearch,
              decoration: InputDecoration(
                hintText: "Search workers, services, locations...",
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),

          // Clear Button (only shows when text exists)
          if (_mainSearchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: hintColor, size: 20),
              ),
            ),

          // ❌ REMOVED: Search Button
          // GestureDetector(
          //   onTap: () => _executeSearch(_mainSearchController.text),
          //   child: Container(
          //     padding: const EdgeInsets.all(10),
          //     margin: const EdgeInsets.only(right: 4),
          //     decoration: BoxDecoration(
          //       color: AppColors.brandMain.withOpacity(0.1),
          //       shape: BoxShape.circle,
          //     ),
          //     child: const Icon(Icons.search_rounded, color: AppColors.brandMain, size: 22),
          //   ),
          // ),

          const SizedBox(width: 8),

          // Profile Button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandMain, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFFD6F9FF),
                radius: 16,
                child: Icon(Icons.person, color: Color(0xFF003F67), size: 20),
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown(bool isDark, Color bgColor, Color textColor, Color subtitleColor) {
    final hasQuery = _mainSearchController.text.trim().isNotEmpty;
    final hasResults = _searchSuggestions.isNotEmpty;
    final hasRecent = _recentSearches.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingSuggestions)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandMain),
                    ),
                  ),
                )
              else if (!hasQuery) ...[
                if (hasRecent) ...[
                  _buildSectionHeader("Recent Searches", Icons.history, textColor, onClear: _clearRecentSearches),
                  ..._recentSearches.take(5).map((search) => _buildSuggestionTile(
                    icon: Icons.history,
                    iconColor: Colors.grey,
                    title: search,
                    textColor: textColor,
                    onTap: () => _executeSearch(search),
                    onRemove: () => _removeRecentSearch(search),
                  )),
                  Divider(height: 1, color: textColor.withOpacity(0.1)),
                ],
                _buildSectionHeader("Trending", Icons.trending_up, textColor),
                ..._trendingSearches.take(5).map((search) => _buildSuggestionTile(
                  icon: Icons.trending_up,
                  iconColor: Colors.orange,
                  title: search,
                  textColor: textColor,
                  onTap: () => _executeSearch(search),
                )),
              ] else if (!hasResults)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 40, color: subtitleColor),
                        const SizedBox(height: 8),
                        Text(
                          "No results found",
                          style: TextStyle(color: subtitleColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._searchSuggestions.map((item) {
                  final type = item['type'] ?? 'worker';

                  if (type == 'recent') {
                    return _buildSuggestionTile(
                      icon: Icons.history,
                      iconColor: Colors.grey,
                      title: item['text'] ?? '',
                      textColor: textColor,
                      onTap: () => _executeSearch(item['text']),
                    );
                  }

                  if (type == 'trending') {
                    return _buildSuggestionTile(
                      icon: Icons.trending_up,
                      iconColor: Colors.orange,
                      title: item['text'] ?? '',
                      textColor: textColor,
                      onTap: () => _executeSearch(item['text']),
                    );
                  }

                  return _buildWorkerSuggestionTile(item, textColor, subtitleColor);
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor, {VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  "Clear all",
                  style: TextStyle(fontSize: 12, color: AppColors.brandMain, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 18, color: textColor.withOpacity(0.4)),
                ),
              )
            else
              Icon(Icons.north_west, size: 14, color: textColor.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerSuggestionTile(Map<String, dynamic> item, Color textColor, Color subtitleColor) {
    final name = (item['title'] ?? item['name'] ?? 'Unknown').toString();
    final role = (item['roleLabel'] ?? item['role'] ?? '').toString();
    final image = (item['image'] ?? '').toString();
    final isLive = item['isLive'] == true;
    final rating = (item['rating'] ?? 0).toDouble();

    return InkWell(
      onTap: () {
        _executeSearch(name);
        _showProfilePopup(item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty ? Icon(Icons.person, color: Colors.grey.shade600, size: 24) : null,
                ),
                if (isLive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (role.isNotEmpty) Text(role, style: TextStyle(fontSize: 12, color: subtitleColor)),
                      if (rating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: subtitleColor)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textColor.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(bool isDark, Color bgColor) {
    return GestureDetector(
      onTap: _showNotificationPanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 24,
            ),
          ),
          if (_hasUnreadNotifs)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: bgColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitchButton() {
    return GestureDetector(
      onTap: _toggleRole,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isWorker ? [Colors.deepOrange, Colors.orange] : [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_isWorker ? Colors.deepOrange : Colors.blueAccent).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.15,
              child: Icon(
                _isWorker ? Icons.work_outline : Icons.person_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            Icon(
              _isWorker ? Icons.currency_exchange : Icons.search,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _mapController.move(_mapController.camera.center, (_currentZoom + 1).clamp(2.0, 18.0)),
          child: _squareBtn(Icons.add, isDark),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _mapController.move(_mapController.camera.center, (_currentZoom - 1).clamp(2.0, 18.0)),
          child: _squareBtn(Icons.remove, isDark),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
          ),
          child: Text(
            _getZoomScaleText(_currentZoom),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildPostFAB() {
    return FloatingActionButton.extended(
      heroTag: 'postBtn',
      onPressed: () async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          _showLoginRequiredDialog();
          return;
        }

        if (_isWorker) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPostScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPostScreen()));
        }
      },
      backgroundColor: _isWorker ? Colors.green : const Color(0xFFFFF59D),
      elevation: 4,
      icon: Icon(
        _isWorker ? Icons.currency_exchange : Icons.handshake_outlined,
        color: _isWorker ? Colors.white : Colors.black,
      ),
      label: Text(
        _isWorker ? "EARN" : "SUPPORT",
        style: TextStyle(
          color: _isWorker ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════
  double _getMarkerSize(double zoom) {
    if (zoom < 13) return 20.0;
    if (zoom < 15) return 50.0;
    return 160.0;
  }

  String _getZoomScaleText(double zoom) {
    if (zoom < 4) return "2000 km";
    if (zoom < 6) return "500 km";
    if (zoom < 8) return "200 km";
    if (zoom < 10) return "50 km";
    if (zoom < 12) return "20 km";
    if (zoom < 14) return "5 km";
    if (zoom < 16) return "2 km";
    if (zoom < 18) return "500 m";
    return "100 m";
  }

  Widget _mapBtn(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _squareBtn(IconData icon, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, color: isDark ? Colors.white : AppColors.brandDark),
    );
  }

  Widget _compassBtn(bool isDark) {
    return GestureDetector(
      onTap: _resetNorth,
      child: Transform.rotate(
        angle: _currentRotation * pi / 180,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.explore, color: AppColors.brandMain),
        ),
      ),
    );
  }
}
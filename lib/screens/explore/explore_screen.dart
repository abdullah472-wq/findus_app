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
import '../../../constants/dummy_data.dart';
import 'package:findus_app/services/user_role_service.dart';
import 'package:findus_app/services/profile_completion_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/services/notification_service.dart';

// Models
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/explore/models/worker_profile_bottom_sheet.dart';
import 'package:findus_app/screens/explore/models/filter_bottom_sheet.dart';

// Screens
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/profile/earn_post_screen.dart';
import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/screens/explore/responsive_worker_pin.dart';
import 'package:findus_app/screens/explore/notifications_page.dart';
import '../auth/log_in_chacker_screen.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final MapController _mapController;
  LatLng? _userCurrentLocation;

  final LatLng _dhakaLocation = const LatLng(23.8103, 90.4125);
  final Distance _distance = const Distance();

  // ✅ Missing variables defined here
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _searchSuggestions = [];
  Timer? _suggestDebounce;

  late AnimationController _shakeController;
  bool _hasUnreadNotifs = false;

  static bool _hasInitialZoomHappened = false;
  double _currentZoom = 2.5;
  double _currentRotation = 0.0;

  bool _isSearchingLocation = true;
  bool _isSearchingWorker = false;

  bool _isWorker = false; // finder == worker/earner, maker == supporter

  RangeValues _priceRange = const RangeValues(0, 10000);
  bool _verifiedOnly = false;
  bool _liveOnly = false;
  String _selectedGender = "Any";
  double _minExperience = 0;

  bool _topRatedOnly = false;
  bool _trustedOnly = false;

  final TextEditingController _locationSearchController = TextEditingController();
  final TextEditingController _mainSearchController = TextEditingController();

  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filteredWorkers = [];

  Set<String> _blockedUserIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _postsSub;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Focus listener to hide suggestions when focus lost
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        // Delay slightly to allow tap on suggestion item
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_searchFocusNode.hasFocus) {
            setState(() {
              _showSuggestions = false;
            });
          }
        });
      }
    });

    _loadUserRole();
    _loadBlockedUsers();
    _checkNotifications();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    if (_hasUnreadNotifs) _shakeController.repeat(reverse: true);

    _isSearchingLocation = true;

    if (!_hasInitialZoomHappened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startInitialZoomSequence();
      });
    } else {
      _isSearchingLocation = false;
      _checkLocationOnly();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _locationSearchController.dispose();
    _mainSearchController.dispose();
    _searchFocusNode.dispose(); // Dispose focus node
    _postsSub?.cancel();
    _suggestDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBlockedUsers() async {
    final users = await BlockedUserService().getBlockedUsers();
    if (mounted) {
      setState(() {
        _blockedUserIds = users.map((u) => u['id'] ?? '').toSet();
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await UserRoleService.getCurrentUserRole();
      final isFinder = UserRoleService.isFinder(role);

      if (!mounted) return;

      setState(() => _isWorker = isFinder);
      _listenToPosts();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWorker = true);
      _listenToPosts();
    }
  }

  List<Map<String, dynamic>> _buildDemoPins() {
    final List<Map<String, dynamic>> demo = [];
    final rnd = Random();

    final regions = [
      {'city': 'Dhaka', 'lat': 23.8103, 'lng': 90.4125},
      {'city': 'Chattogram', 'lat': 22.3569, 'lng': 91.7832},
      {'city': 'Sylhet', 'lat': 24.8949, 'lng': 91.8687},
      {'city': 'Rajshahi', 'lat': 24.3636, 'lng': 88.6241},
      {'city': 'Khulna', 'lat': 22.8456, 'lng': 89.5403},
    ];

    final workerRoles = [
      'DRIVER', 'CLEANER', 'ELECTRICIAN', 'PLUMBER', 'GARDENER',
      'COOK', 'DELIVERY', 'PAINTER',
    ];

    // Demo Workers
    for (int i = 0; i < 25; i++) {
      final reg = regions[i % regions.length];
      final baseLat = reg['lat'] as double;
      final baseLng = reg['lng'] as double;
      final city = reg['city'] as String;

      final latOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final lngOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final roleLabel = workerRoles[i % workerRoles.length];

      demo.add({
        "id": "demo_worker_$i",
        "name": "$roleLabel in $city #${i + 1}",
        "role": roleLabel,
        "location": LatLng(baseLat + latOffset, baseLng + lngOffset),
        "address": "$city, Bangladesh",
        "image": "https://i.pravatar.cc/150?img=${rnd.nextInt(70)}",
        "price": "৳${300 + rnd.nextInt(700)} / day",
        "verified": rnd.nextBool(),
        "isLive": rnd.nextBool(),
        "phone": "+88017${10000000 + rnd.nextInt(8999999)}",
        "gender": rnd.nextBool() ? 'Male' : 'Female',
        "experience": rnd.nextInt(10),
        "rating": 3.5 + rnd.nextDouble() * 1.5,
        "language": "Bangla",
        "trusted": rnd.nextBool(),
        "type": "finder",
      });
    }

    // Demo Supporters
    for (int i = 0; i < 25; i++) {
      final reg = regions[i % regions.length];
      final baseLat = reg['lat'] as double;
      final baseLng = reg['lng'] as double;
      final city = reg['city'] as String;

      final latOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final lngOffset = (rnd.nextDouble() - 0.5) * 0.08;
      final roleLabel = workerRoles[i % workerRoles.length];

      demo.add({
        "id": "demo_supporter_$i",
        "name": "Need $roleLabel in $city #${i + 1}",
        "role": roleLabel,
        "location": LatLng(baseLat + latOffset, baseLng + lngOffset),
        "address": "$city, Bangladesh",
        "image": "https://i.pravatar.cc/150?img=${rnd.nextInt(70)}",
        "price": "৳${400 + rnd.nextInt(900)} / job",
        "verified": rnd.nextBool(),
        "isLive": rnd.nextBool(),
        "phone": "+88018${10000000 + rnd.nextInt(8999999)}",
        "gender": "Any",
        "experience": 0,
        "rating": 4.0 + rnd.nextDouble(),
        "language": "Bangla",
        "trusted": rnd.nextBool(),
        "type": "maker",
      });
    }

    return demo;
  }

  void _listenToPosts() {
    _postsSub?.cancel();
    final viewerRole = _isWorker ? 'finder' : 'maker';

    _postsSub = PostService.streamPinsForViewerRole(viewerRole).listen((posts) {
      if (!mounted) return;

      final demoPins = _buildDemoPins();
      final all = <Map<String, dynamic>>[];
      all.addAll(demoPins);
      all.addAll(posts);

      setState(() {
        _allWorkers = all;
        _filteredWorkers = List.from(_allWorkers);
      });
    });
  }

  void _checkNotifications() {
    bool hasUnread = DummyData.notifications.any((n) => n['read'] == false);
    setState(() => _hasUnreadNotifs = hasUnread);
  }

  Future<void> _checkLocationOnly() async {
    try {
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
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

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
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
    if (!mounted) return;
    setState(() {
      _isSearchingLocation = false;
      _userCurrentLocation = null;
    });
    _hasInitialZoomHappened = true;
  }

  void _animateMapMove(LatLng dest, double destZoom, Duration duration) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: dest.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: duration, vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
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
      final val = rotTween.evaluate(animation);
      _mapController.rotate(val);
    });

    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _resetNorth() => _animateMapRotationTo(0);

  void _zoomToUser() {
    if (_userCurrentLocation != null) {
      _animateMapMove(_userCurrentLocation!, 16.0, const Duration(milliseconds: 400));
    }
  }

  double? _getDistanceKm(LatLng workerLocation) {
    if (_userCurrentLocation == null) return null;
    return _distance.as(LengthUnit.Kilometer, _userCurrentLocation!, workerLocation);
  }

  void _updateSearchSuggestions(String query) {
    if (_suggestDebounce?.isActive ?? false) {
      _suggestDebounce!.cancel();
    }

    _suggestDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        setState(() {
          _showSuggestions = false;
          _searchSuggestions = [];
        });
        return;
      }

      // 🔁 এখানে শুধু _allWorkers ইউজ করো, extra _buildDemoPins() না
      final suggestions = _allWorkers
          .where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final role = (item['role'] ?? '').toString().toLowerCase();
        final address = (item['address'] ?? '').toString().toLowerCase();
        return name.contains(q) || role.contains(q) || address.contains(q);
      })
          .take(6)
          .toList();

      setState(() {
        _searchSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    });
  }

  // ✅ Updated _mapDataToWorker logic
  Worker _mapDataToWorker(Map<String, dynamic> data) {
    // 1. UID extraction (Robust)
    final String uid = (data['ownerId'] ?? data['uid'] ?? data['userId'] ?? data['id'] ?? '').toString().trim();

    // 2. UserRole extraction
    String userRole = 'finder'; // default
    if (data['userRole'] != null) {
      userRole = data['userRole'].toString();
    } else if (data['type'] != null) {
      userRole = data['type'].toString();
    } else {
      final id = (data['id'] ?? '').toString();
      if (id.contains('supporter')) {
        userRole = 'maker';
      } else if (id.contains('worker')) userRole = 'finder';
    }

    // 3. Price and PriceText logic
    String priceText = 'Negotiable';
    num? price;

    final priceData = data['price'];
    if (priceData is num) {
      price = priceData;
      priceText = '৳$priceData';
    } else if (priceData is String) {
      priceText = priceData;
      // Try extracting number from string like "৳500 / day"
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(priceData);
      if (match != null) {
        price = num.tryParse(match.group(0)!);
      }
    }

    // 4. Rating parsing
    double rating = 0.0;
    if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    } else {
      rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0;
    }

    return Worker(
      uid: uid,
      postId: data['id']?.toString(),
      name: (data['name'] ?? 'Unknown').toString(),
      userRole: userRole,
      image: (data['image'] ?? '').toString(),
      location: (data['address'] ?? 'Bangladesh').toString(),
      priceText: priceText,
      price: price, // Optional num
      rating: rating,
      kycCompleted: data['verified'] == true,
      isVerified: data['verified'] == true,

      // Optional fields
      experience: double.tryParse(data['experience']?.toString() ?? '0'),
      gender: data['gender']?.toString(),
      languages: data['language'] != null ? [data['language'].toString()] : null,
      isLive: data['isLive'] ?? false,
      isTrusted: data['trusted'] ?? false,
      isPromoted: data['isPromoted'] ?? false,
      phone: data['phone']?.toString(),
    );
  }

  void _showNotificationPanel() {
    setState(() {
      _hasUnreadNotifs = false;
      _shakeController.stop();
      _shakeController.reset();
      for (var n in DummyData.notifications) {
        n['read'] = true;
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  Future<void> _sendProfileViewNotification(Map<String, dynamic> data) async {
    try {
      final postId = data['id']?.toString() ?? '';
      if (postId.isEmpty || postId.startsWith('demo_')) return;

      final doc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (!doc.exists) return;

      final postData = doc.data()!;
      final ownerId = postData['ownerId']?.toString();
      if (ownerId == null || ownerId.isEmpty) return;

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && currentUid == ownerId) return;

      final title = postData['title']?.toString() ?? 'Your post';
      final roleLabel = postData['roleLabel']?.toString();

      await NotificationService.sendNotificationToUser(
        toUserId: ownerId,
        title: "Your post was viewed",
        body: 'Someone viewed your job/post “$title”.',
        type: 'profile_view',
        relatedPostId: postId,
        data: {
          'roleLabel': roleLabel,
          'viewerRole': _isWorker ? 'finder' : 'maker',
          'source': 'map_pin',
        },
      );
    } catch (_) {}
  }

  void _showProfilePopup(Map<String, dynamic> data) async {
    final workerModel = _mapDataToWorker(data);
    _sendProfileViewNotification(data);

    await showWorkerProfileBottomSheet(
      context: context,
      data: data,
      isWorker: _isWorker,
      allWorkers: _allWorkers,
      workerModel: workerModel,
    );

    _loadBlockedUsers();
  }

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
      final resp = await http.get(uri, headers: {'User-Agent': 'findus-app/1.0'}).timeout(const Duration(seconds: 8));
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
    const cities = [
      'dhaka','chattogram','chittagong','sylhet','rajshahi','khulna','barishal','barisal','mymensingh','rangpur',
      'gazipur','narayanganj','cumilla','comilla','bogura','bogra','tangail','narsingdi','brahmanbaria','feni',
      'noakhali','kishoreganj','habiganj','moulvibazar','sunamganj','gopalganj','madaripur','manikganj','narail'
    ];
    for (final c in cities) {
      if (t.contains(c)) return true;
    }
    return false;
  }

  Future<void> _maybeMoveCameraToSearchLocation({String? mainQuery}) async {
    final locText = _locationSearchController.text.trim();
    final mainText = (mainQuery ?? '').trim();
    String q = '';
    if (locText.isNotEmpty) {
      q = locText;
    } else if (_looksLikeLocation(mainText)) {
      q = mainText;
    }

    if (q.isEmpty) return;

    final pos = await _geocodeLocation(q);
    if (pos != null) {
      _animateMapMove(pos, 13.5, const Duration(milliseconds: 600));
    }
  }

  Future<void> _showFilterPanel() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString('subscription_plan') ?? 'free';
    final isProUser = plan == 'pro' || plan == 'business';

    final result = await showFilterBottomSheet(
      context: context,
      locationController: _locationSearchController,
      initialPriceRange: _priceRange,
      initialVerifiedOnly: _verifiedOnly,
      initialLiveOnly: _liveOnly,
      initialGender: _selectedGender,
      initialMinExperience: _minExperience,
      initialTopRatedOnly: _topRatedOnly,
      initialTrustedOnly: _trustedOnly,
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
    });

    _performSearch(_mainSearchController.text);
    _maybeMoveCameraToSearchLocation(mainQuery: _mainSearchController.text);
  }

  void _performSearch(String query) {
    FocusScope.of(context).unfocus();
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

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final searchTextLower = searchText.toLowerCase();
      final locationText = _locationSearchController.text.toLowerCase().trim();

      List<Map<String, dynamic>> results = _allWorkers.where((worker) {
        final name = worker['name'].toString().toLowerCase();
        final role = worker['role'].toString().toLowerCase();
        final address = worker['address'].toString().toLowerCase();

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
        final workerExp = (worker['experience'] ?? 0).toDouble();
        final matchesExp = workerExp >= _minExperience;

        // Price filtering
        final priceStr = worker['price']?.toString() ?? '0';
        final priceMatch = RegExp(r'\d+').firstMatch(priceStr);
        final priceValue = int.tryParse(priceMatch?.group(0) ?? '0') ?? 0;
        final matchesPrice = priceValue >= _priceRange.start && priceValue <= _priceRange.end;

        final rating = (worker['rating'] ?? 0).toDouble();
        final matchesTopRated = !_topRatedOnly || rating >= 4.8;
        final matchesTrusted = !_trustedOnly || worker['trusted'] == true || rating >= 4.2;

        return matchesMainQuery && matchesLocationQuery && matchesVerified && matchesLive && matchesGender && matchesExp && matchesPrice && matchesTopRated && matchesTrusted;
      }).toList();

      results.sort((a, b) {
        final aLoc = a['location'] as LatLng;
        final bLoc = b['location'] as LatLng;
        final aDist = _getDistanceKm(aLoc);
        final bDist = _getDistanceKm(bLoc);

        if (aDist != null && bDist != null) {
          final diff = aDist.compareTo(bDist);
          if (diff != 0) return diff;
        }
        final aRating = (a['rating'] ?? 0).toDouble();
        final bRating = (b['rating'] ?? 0).toDouble();
        return bRating.compareTo(aRating);
      });

      setState(() {
        _isSearchingWorker = false;
        _filteredWorkers = results;
        _showSuggestions = false;
      });

      if (results.isNotEmpty) {
        final firstLoc = results.first['location'] as LatLng;
        _animateMapMove(firstLoc, 15.0, const Duration(milliseconds: 500));
      }
    });
  }

  void _openEmergency() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileSideBar(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dhakaLocation,
              initialZoom: 2.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onPositionChanged: (camera, hasGesture) {
                setState(() {
                  _currentZoom = camera.zoom;
                  _currentRotation = camera.rotation;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findus.app',
              ),
              MarkerLayer(
                markers: _filteredWorkers
                    .where((data) => !_blockedUserIds.contains((data['id'] ?? data['name']).toString()))
                    .map((data) {
                  final LatLng workerLoc = data['location'] as LatLng;
                  final double? distKm = _getDistanceKm(workerLoc);

                  return Marker(
                    point: workerLoc,
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _showProfilePopup(data),
                      child: ResponsiveWorkerPin(
                        role: data['role'],
                        price: data['price'],
                        isLive: data['isLive'] ?? false,
                        currentZoom: _currentZoom,
                        distanceKm: distKm,
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
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.brandMain,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (_showSuggestions)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => _showSuggestions = false);
                  _searchFocusNode.unfocus();
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),

          if (_isSearchingLocation || _isSearchingWorker)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset('assets/animations/search.json', width: 200, height: 200),
                      const SizedBox(height: 20),
                      Text(
                        _isSearchingLocation ? "Finding your location..." : "Searching workers...",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ),

          if (!_isSearchingLocation)
            Positioned(
              top: 50,
              left: 15,
              right: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.brandDark,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset("assets/images/app_icon.png", fit: BoxFit.scaleDown),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _mainSearchController,
                            focusNode: _searchFocusNode,
                            onTap: () {
                              if (_mainSearchController.text.isNotEmpty) {
                                _updateSearchSuggestions(_mainSearchController.text);
                                setState(() => _showSuggestions = true);
                              }
                            },
                            onChanged: (value) {
                              _updateSearchSuggestions(value);
                              setState(() => _isSearchingWorker = false);
                            },
                            textInputAction: TextInputAction.search,
                            onSubmitted: (txt) {
                              _performSearch(txt);
                              _maybeMoveCameraToSearchLocation(mainQuery: txt);
                              setState(() => _showSuggestions = false);
                              _searchFocusNode.unfocus();
                            },
                            decoration: InputDecoration(
                              hintText: "Search name/role or type a location...",
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF003F67), width: 2),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFD6F9FF),
                              radius: 18,
                              child: Icon(Icons.person, color: Color(0xFF003F67), size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),

                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text('Suggestions', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ..._searchSuggestions.map((item) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(item['image'] ?? ''),
                                backgroundColor: Colors.grey.shade200,
                                child: item['image'] == null ? Icon(Icons.person, color: Colors.grey.shade400) : null,
                              ),
                              title: Text(
                                item['name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item['role']?.toString() ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Text(
                                item['price']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.brandMain, fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                final name = item['name']?.toString() ?? '';
                                setState(() {
                                  _mainSearchController.text = name;
                                  _showSuggestions = false;
                                });
                                _performSearch(name);
                                _maybeMoveCameraToSearchLocation(mainQuery: name);
                                _searchFocusNode.unfocus();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (!_isSearchingLocation)
            Positioned(
              top: 120,
              right: 15,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showNotificationPanel,
                        child: RotationTransition(
                          turns: Tween(begin: -0.05, end: 0.05).animate(_shakeController),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                            child: const Icon(Icons.notifications, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      if (_hasUnreadNotifs)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.brandMain,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _mapBtn(Icons.tune, AppColors.brandDark, _showFilterPanel),
                  const SizedBox(height: 15),
                  _compassBtn(),
                  const SizedBox(height: 15),
                  _mapBtn(Icons.my_location, AppColors.brandMain, _zoomToUser),
                ],
              ),
            ),

          if (!_isSearchingLocation)
            Positioned(
              bottom: 180,
              right: 20,
              child: _mapBtn(Icons.medical_services_outlined, Colors.redAccent, _openEmergency),
            ),

          if (!_isSearchingLocation)
            Positioned(
              bottom: 110,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _mapController.move(_mapController.camera.center, (_currentZoom + 1).clamp(2, 18)),
                    child: _squareBtn(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _mapController.move(_mapController.camera.center, (_currentZoom - 1).clamp(2, 18)),
                    child: _squareBtn(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      _getZoomScaleText(_currentZoom),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isSearchingLocation)
            Positioned(
              bottom: 110,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  // 🔑 1) আগে লগইন আছে কিনা চেক করো
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser == null) {
                    // ✅ লগইন না থাকলে পপ-আপ (Dialog) দেখাবে
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          "Login Required",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          "You need to login to create a post or offer support.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx); // ডায়ালগ বন্ধ
                              // লগইন স্ক্রিনে নেভিগেট
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandMain,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("LOGIN NOW"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // 🔑 2) প্রোফাইল কমপ্লিশন চেক
                  final completed = await ProfileCompletionService.isCompleted();
                  if (!completed) {
                    final go = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text(
                          "Complete your profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          "To post a job or earn post, please complete your main account profile.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("CANCEL"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandMain,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("GO TO PROFILE"),
                          ),
                        ],
                      ),
                    );

                    if (go == true) {
                      final uid = currentUser.uid;
                      if (uid.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnifiedProfileEditScreen(uid: uid),
                        ),
                      );
                    }
                    return;
                  }

                  // 🔑 3) সব ঠিক থাকলে পোস্ট স্ক্রিনে নিয়ে যাও
                  if (_isWorker) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EarnPostScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportPostScreen()),
                    );
                  }
                },
                backgroundColor: _isWorker ? Colors.green : const Color(0xFFFFF59D),
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
              ),
            ),
        ],
      ),
    );
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

  Widget _mapBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: Icon(icon, color: color),
    ),
  );

  Widget _squareBtn(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
    child: Icon(icon, color: AppColors.brandDark),
  );

  Widget _compassBtn() => GestureDetector(
    onTap: _resetNorth,
    child: Transform.rotate(
      angle: _currentRotation * pi / 180,
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
        child: const Icon(Icons.explore, color: AppColors.brandMain),
      ),
    ),
  );
}
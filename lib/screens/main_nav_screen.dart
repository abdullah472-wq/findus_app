import 'package:findus_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'emergency_screen.dart';
import 'dashboard_screen.dart';

// Profile screens + model
import 'package:findus_app/screens/supporter/supporter_profile_screen.dart';
import 'package:findus_app/screens/earner/worker_profile_screen.dart';
import 'package:findus_app/models/worker_model.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 1; // ডিফল্ট Explore Screen

  // পেজ কন্ট্রোলার (এটি পেজ মেমোরিতে ধরে রাখবে)
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ট্যাব চেঞ্জ হলে পেজ জাম্প করবে
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // Emergency এখন শুধু ExploreScreen থেকে ব্যবহার হবে (map এ আলাদা বাটন আছে)
  void _openEmergencyFromAnywhere(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EmergencyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // আগের মতই PageView, শুধু EmergencyScreen বের করে আনা হয়েছে
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // সোয়াইপ বন্ধ (শুধু ট্যাবে কাজ করবে)
        children: const [
          HomeFeedScreen(),
          ExploreScreen(),      // map screen – এখানেই emergency গোল বাটন থাকবে
          DashboardScreen(),
          ProfileNavScreen(),   // নিচে owner profile loader
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.brandLight,
        selectedItemColor: const Color(0xFF004D40),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

/// Profile tab এর পেজ
/// এখানে SharedPreferences থেকে role+info নিয়ে
/// SupporterProfileScreen বা WorkerProfileScreen দেখানো হবে
class ProfileNavScreen extends StatefulWidget {
  const ProfileNavScreen({super.key});

  @override
  State<ProfileNavScreen> createState() => _ProfileNavScreenState();
}

class _ProfileNavScreenState extends State<ProfileNavScreen> {
  bool _loading = true;
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  Future<void> _loadOwnerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final role = (prefs.getString('user_role') ?? '').toLowerCase().trim();
      final name = (prefs.getString('user_name') ?? 'FINDUS User').trim();
      final location =
      (prefs.getString('user_location') ?? 'Add your address').trim();
      final phone = (prefs.getString('user_phone') ?? '').trim();
      final image =
          prefs.getString('user_image') ?? 'https://i.pravatar.cc/150?img=3';
      final rating = (prefs.getDouble('user_rating') ?? 4.8);
      final jobsCompleted = prefs.getInt('user_jobs_completed') ?? 0;

      if (!mounted) return;

      Widget child;

      if (role == 'maker' || role == 'supporter') {
        final plan =
        (prefs.getString('subscription_plan') ?? 'free').toLowerCase();

        child = SupporterProfileScreen(
          isOwner: true,
          name: name,
          role: role,
          location: location,
          phone: phone,
          email: prefs.getString('user_email'),
          facebookUrl: prefs.getString('user_facebook'),
          instagramUrl: prefs.getString('user_instagram'),
          linkedInUrl: prefs.getString('user_linkedin'),
          completedText: jobsCompleted.toString(),
          ratingText: rating.toStringAsFixed(1),
          reviewsText: (prefs.getInt('user_reviews') ?? 0).toString(),
          subscriptionPlan: plan,
        );
      } else {
        // Worker / finder / earner → WorkerProfileScreen (owner view)
        final worker = Worker(
          name: name,
          role: role.isEmpty ? 'earner' : role,
          image: image,
          location: location,
          price: prefs.getString('worker_price') ?? '৳ 0 / day',
          rating: rating,
          isVerified: prefs.getBool('user_verified') ?? false,
        );

        child = WorkerProfileScreen(
          worker: worker,
          phoneNumber: phone,
          facebookUrl: prefs.getString('user_facebook'),
          emailAddress: prefs.getString('user_email'),
          instagramUrl: prefs.getString('user_instagram'),
          linkedInUrl: prefs.getString('user_linkedin'),
          isOwner: true,
        );
      }

      setState(() {
        _child = child;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _child = const Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          body: Center(
            child: Text(
              "Could not load profile.\nPlease check your connection.",
              textAlign: TextAlign.center,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _child ??
        const Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          body: Center(
            child: Text(
              "No profile data found.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        );
  }
}
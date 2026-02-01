import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/ads/ad_model.dart';
import 'package:findus_app/screens/ads/ad_service.dart';

class AdDisplayScreen extends StatefulWidget {
  final VoidCallback onAdDismissed;

  const AdDisplayScreen({super.key, required this.onAdDismissed});

  @override
  State<AdDisplayScreen> createState() => _AdDisplayScreenState();
}

class _AdDisplayScreenState extends State<AdDisplayScreen> {
  int _countdown = 5;
  Timer? _timer;
  AdModel? _ad;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _fetchAd() async {
    final ad = await AdService.getRandomAd();
    if (mounted) {
      if (ad == null) {
        // কোনো অ্যাড না থাকলে সরাসরি স্কিপ
        widget.onAdDismissed();
      } else {
        setState(() {
          _ad = ad;
          _loading = false;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        // অটোমেটিক ক্লোজ হবে না, ইউজারকে ক্রস চাপতে হবে (বা চাইলে ক্লোজ করতে পারেন)
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _closeAd() {
    _timer?.cancel();
    if (mounted) {
      Navigator.pop(context);
      widget.onAdDismissed();
    }
  }

  Future<void> _onAdClick() async {
    if (_ad == null || _ad!.targetUrl.isEmpty) return;

    // ক্লিক কাউন্ট আপডেট (Analytics)
    AdService.incrementClick(_ad!.id);

    final uri = Uri.parse(_ad!.targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.brandMain)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Ad Content (Full Screen Clickable)
          GestureDetector(
            onTap: _onAdClick,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _ad?.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: _ad!.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
              )
                  : Container(color: Colors.grey.shade900),
            ),
          ),

          // 2. Overlay Gradient (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Sponsored",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ad?.title ?? "Advertisement",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 3. Skip Button (Top Right)
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: _countdown == 0 ? _closeAd : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countdown > 0 ? "Wait $_countdown" : "Skip Ad",
                      style: TextStyle(
                          color: _countdown > 0 ? Colors.white70 : Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    if (_countdown == 0) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.skip_next_rounded, color: Colors.white, size: 16),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
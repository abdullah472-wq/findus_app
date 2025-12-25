// lib/screens/explore/responsive_worker_pin.dart

import 'package:flutter/material.dart';

class ResponsiveWorkerPin extends StatefulWidget {
  final String role;
  final String price;
  final bool isLive;
  final double currentZoom;
  final double? distanceKm;
  final bool isPromoted;

  const ResponsiveWorkerPin({
    super.key,
    required this.role,
    required this.price,
    required this.isLive,
    required this.currentZoom,
    this.distanceKm,
    required this.isPromoted,
  });

  @override
  State<ResponsiveWorkerPin> createState() => _ResponsiveWorkerPinState();
}

class _ResponsiveWorkerPinState extends State<ResponsiveWorkerPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 2.5).animate(_controller);
    _fadeAnimation =
        Tween<double>(begin: 0.6, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color pinColor = const Color(0xFF38B6FF);
    if (widget.role.toUpperCase().contains("PAINTER")) {
      pinColor = Colors.orange;
    }
    if (widget.role.toUpperCase().contains("GARDENER")) {
      pinColor = Colors.green;
    }
    if (widget.role.toUpperCase().contains("RICKSHAW") ||
        widget.role.toUpperCase().contains("DRIVER")) {
      pinColor = const Color(0xFF003F67);
    }

    bool showDotOnly;

    // 🔹 zoom-based logic:
    //
    // zoom >= 14  → সব card (২ কিমি বা তার বেশি zoom in)
    // 12 <= zoom < 14 → শুধু promoted card (৫ কিমি)
    // zoom < 12 → সব dot
    final z = widget.currentZoom;

    if (z >= 14) {
      showDotOnly = false; // সব card
    } else if (z >= 12) {
      showDotOnly = !widget.isPromoted; // শুধু promoted card
    } else {
      showDotOnly = true; // সব dot
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.isLive)
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: showDotOnly ? 15 : 40,
                height: showDotOnly ? 15 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pinColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        if (showDotOnly)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pinColor, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        widget.price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: pinColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(9),
                        ),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ClipPath(
                clipper: _PinPointerClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: pinColor,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// 🔹 আলাদা top-level ক্লাস (ResponsiveWorkerPin এর বাইরে)
class _PinPointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
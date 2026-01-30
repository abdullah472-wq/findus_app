// lib/screens/explore/responsive_worker_pin.dart

import 'package:flutter/material.dart';

class ResponsiveWorkerPin extends StatefulWidget {
  final String role;
  final String price; // e.g. "500" or "৳500"
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getStyle() {
    final role = widget.role.toUpperCase();
    if (role.contains("PAINTER")) {
      return {'color': Colors.orange, 'icon': Icons.format_paint_rounded};
    } else if (role.contains("GARDENER")) {
      return {'color': Colors.green, 'icon': Icons.grass_rounded};
    } else if (role.contains("DRIVER") || role.contains("RICKSHAW")) {
      return {'color': const Color(0xFF003F67), 'icon': Icons.directions_car_rounded};
    } else if (role.contains("ELECTRICIAN")) {
      return {'color': Colors.amber.shade700, 'icon': Icons.electrical_services_rounded};
    } else if (role.contains("PLUMBER")) {
      return {'color': Colors.blue, 'icon': Icons.plumbing_rounded};
    }
    return {'color': const Color(0xFF38B6FF), 'icon': Icons.work_rounded};
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    final Color color = style['color'];
    final IconData icon = style['icon'];

    final z = widget.currentZoom;
    bool isSmallDot = z < 12;
    bool isCompact = z >= 12 && z < 14 && !widget.isPromoted;

    if (isSmallDot) {
      return _buildDot(color);
    }

    return widget.isLive
        ? ScaleTransition(scale: _controller, child: _buildPin(color, icon, isCompact))
        : _buildPin(color, icon, isCompact);
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }

  Widget _buildPin(Color color, IconData icon, bool isCompact) {
    // ✅ শুধু টাকার অংক বের করা হচ্ছে (টাকা বা টেক্সট)
    // উদাহরণ: "৳500" অথবা শুধু "500"
    String displayPrice = widget.price;

    // যদি শুধু নাম্বার আসে, তার আগে টাকার চিহ্ন যোগ করতে পারেন (অপশনাল)
    // if (!displayPrice.contains('৳') && RegExp(r'^\d+$').hasMatch(displayPrice)) {
    //   displayPrice = '৳$displayPrice';
    // }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 6 : 8
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5), // হালকা বর্ডার
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),

              if (!isCompact) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ শুধু প্রাইস (বড় করে)
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // ✅ রোল (ছোট করে)
                    Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
        // Triangle Pointer
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 12,
            height: 7,
            color: Colors.white, // পয়েন্টার সাদা হবে যাতে পিলের সাথে মিশে যায়
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
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
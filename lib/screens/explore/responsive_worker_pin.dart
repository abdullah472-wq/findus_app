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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true); // Heartbeat animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // পেশা অনুযায়ী আইকন এবং কালার সিলেক্টর
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
    // Default
    return {'color': const Color(0xFF38B6FF), 'icon': Icons.work_rounded};
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    final Color color = style['color'];
    final IconData icon = style['icon'];

    // Zoom Logic
    final z = widget.currentZoom;
    bool isSmallDot = z < 12;
    bool isCompact = z >= 12 && z < 14 && !widget.isPromoted;

    if (isSmallDot) {
      return _buildDot(color);
    }

    // লাইভ হলে পালস অ্যানিমেশন
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: isCompact ? 6 : 8
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),

              if (!isCompact) ...[
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
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
            width: 10,
            height: 6,
            color: Colors.white,
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
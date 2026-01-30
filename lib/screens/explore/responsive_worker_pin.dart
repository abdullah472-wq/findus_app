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

    // বর্তমান জুম লেভেল নিন
    final double z = widget.currentZoom;

    // --- 🎯 জুম লজিক (Updated) ---

    // ১. যদি জুম ১৩ এর কম হয় (খুব দূরে) -> ছোট ডট
    if (z < 13.0) {
      return widget.isLive
          ? ScaleTransition(scale: _controller, child: _buildDot(color))
          : _buildDot(color);
    }

    // ২. যদি জুম ১৩ থেকে ১৫ এর মধ্যে হয় -> কম্প্যাক্ট পিন (শুধু আইকন)
    else if (z >= 13.0 && z < 15.0) {
      return widget.isLive
          ? ScaleTransition(scale: _controller, child: _buildCompactPin(color, icon))
          : _buildCompactPin(color, icon);
    }

    // ৩. যদি জুম ১৫ বা তার বেশি হয় (কাছে) -> ফুল কার্ড
    else {
      return widget.isLive
          ? ScaleTransition(scale: _controller, child: _buildFullCard(color, icon))
          : _buildFullCard(color, icon);
    }
  }

  // ১. ডট ডিজাইন (অনেক দূরের জন্য)
  Widget _buildDot(Color color) {
    return Container(
      width: 12, // আগে 10 ছিল, একটু বাড়িয়ে 12 করা হলো
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // সাদা বর্ডার
        boxShadow: const [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2)
          )
        ],
      ),
    );
  }

  // ২. পিন ডিজাইন (মাঝামাঝি দূরত্বের জন্য - শুধু আইকন)
  Widget _buildCompactPin(Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        // নিচের ত্রিভুজ
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 10,
            height: 6,
            color: color,
          ),
        ),
      ],
    );
  }

  // ৩. বাবল কার্ড ডিজাইন (কাছের জন্য - সম্পূর্ণ ডিটেইলস)
  Widget _buildFullCard(Color color, IconData icon) {
    // টেক্সট ক্লিনিং (আগের ফিক্স সহ)
    String displayPrice = widget.price;
    if (displayPrice.contains('/')) {
      displayPrice = displayPrice.split('/').first.trim();
    }
    displayPrice = displayPrice
        .replaceAll('day', '')
        .replaceAll('Day', '')
        .replaceAll('hr', '')
        .replaceAll('hour', '')
        .trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
              // রঙিন আইকন সার্কেল
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),

              // টেক্সট ইনফো
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // সাদা ত্রিভুজ
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 12,
            height: 7,
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
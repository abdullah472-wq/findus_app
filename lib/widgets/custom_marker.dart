// lib/widgets/custom_marker.dart

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart'; // ✅ এই প্যাকেজটি অবশ্যই ইমপোর্ট করতে হবে
import '../models/worker_model.dart';
import 'package:findus_app/services/post_service.dart'; // ✅ PostService ইমপোর্ট

class CustomMarkerWidget extends StatefulWidget {
  final Worker worker;
  final VoidCallback onTap;
  final String? roleLabel;

  const CustomMarkerWidget({
    super.key,
    required this.worker,
    required this.onTap,
    this.roleLabel,
  });

  @override
  State<CustomMarkerWidget> createState() => _CustomMarkerWidgetState();
}

class _CustomMarkerWidgetState extends State<CustomMarkerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ✅ ইম্প্রেশন যাতে বারবার কাউন্ট না হয়, তার জন্য ফ্ল্যাগ
  bool _hasRecordedImpression = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ ইম্প্রেশন ট্র্যাক করার মেথড
  void _trackImpression() {
    if (_hasRecordedImpression) return;

    // পোস্ট আইডি থাকলে সার্ভারে পাঠানো
    if (widget.worker.postId != null && widget.worker.postId!.isNotEmpty) {
      PostService.trackImpression(widget.worker.postId!); // ✅ আপনার সার্ভিসের ফাংশন
      _hasRecordedImpression = true; // একবার কাউন্ট হয়ে গেলে ফ্ল্যাগ সেট
    }
  }

  IconData _getCategoryIcon(String label) {
    final r = label.toLowerCase();
    if (r.contains('electric')) return Icons.bolt;
    if (r.contains('plumb')) return Icons.build;
    if (r.contains('clean')) return Icons.cleaning_services;
    if (r.contains('mechanic')) return Icons.settings;
    if (r.contains('paint')) return Icons.format_paint;
    if (r.contains('driver')) return Icons.directions_car;
    if (r.contains('helper')) return Icons.person;
    return Icons.person;
  }

  String _bestRoleLabel() {
    final explicit = widget.roleLabel?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final guessPool = '${widget.worker.about} ${widget.worker.name}'.toLowerCase();
    if (guessPool.contains('electric')) return 'Electrician';
    if (guessPool.contains('plumb')) return 'Plumber';
    if (guessPool.contains('clean')) return 'Cleaner';
    if (guessPool.contains('mechanic')) return 'Mechanic';
    if (guessPool.contains('paint')) return 'Painter';
    if (guessPool.contains('driver')) return 'Driver';
    if (guessPool.contains('helper')) return 'Helper';
    return widget.worker.userRole.toLowerCase().trim() == 'finder'
        ? 'Worker'
        : 'Supporter';
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
    widget.worker.rating >= 4.5 ? Colors.green : Colors.blueAccent;

    final String roleLabel = _bestRoleLabel();

    final String priceLabel = widget.worker.priceText.trim().isNotEmpty
        ? widget.worker.priceText
        : (widget.worker.price != null
        ? '৳ ${widget.worker.price!.toInt()}'
        : 'Negotiable');

    final bool hasImg = widget.worker.image.trim().isNotEmpty;

    // পোস্ট আইডি অথবা ইউজার আইডি দিয়ে ইউনিক কী তৈরি করা
    final String visibilityKey = "marker_vis_${widget.worker.postId ?? widget.worker.uid}";

    return VisibilityDetector(
      key: Key(visibilityKey),
      onVisibilityChanged: (info) {
        // যদি মার্কারের ৫০% বা তার বেশি দেখা যায়, তখন ইম্প্রেশন কাউন্ট হবে
        if (info.visibleFraction > 0.5) {
          _trackImpression();
        }
      },
      child: GestureDetector(
        PostService.trackProfileClick(widget.worker.uid);
        onTap: widget.onTap,
        child: SizedBox(
          width: 80,
          height: 110,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 25,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 60 * _controller.value + 40,
                      height: 60 * _controller.value + 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(1.0 - _controller.value),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 15,
                child: CustomPaint(
                  painter: TrianglePainter(statusColor),
                  size: const Size(15, 12),
                ),
              ),
              Positioned(
                bottom: 25,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5)
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: hasImg ? NetworkImage(widget.worker.image) : null,
                    child: hasImg ? null : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                  ),
                  child: Icon(
                    _getCategoryIcon(roleLabel),
                    size: 14,
                    color: statusColor,
                  ),
                ),
              ),
              Positioned(
                top: 5,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    priceLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (widget.worker.kycCompleted)
                Positioned(
                  bottom: 25,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, size: 16, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';

class FloatingScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  final bool showBack;
  final VoidCallback? onBack;

  final bool scrollable;
  final EdgeInsetsGeometry bodyPadding;

  final double topMargin;
  final double radius;
  final double horizontalMargin;
  final double barHeight;

  final Gradient? gradient;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  final Color? titleColor;
  final Color? iconColor;

  // FAB (Floating Action Button) সাপোর্ট যোগ করা হয়েছে
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const FloatingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.scrollable = true,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.topMargin = 10, // 'top' এর নাম পরিবর্তন করে 'topMargin' রাখা হয়েছে বোঝার সুবিধার্থে
    this.radius = 20,
    this.horizontalMargin = 16,
    this.barHeight = kToolbarHeight,
    this.gradient,
    this.backgroundColor,
    this.boxShadow,
    this.titleColor,
    this.iconColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    // বডি কন্টেন্ট অ্যাপ বারের নিচ থেকে শুরু হবে, তাই উপরের প্যাডিং হিসাব করা হলো
    final contentTopPadding = paddingTop + topMargin + barHeight + 16;

    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      )
    ];

    final resolvedTitleColor =
        titleColor ?? Theme.of(context).textTheme.titleLarge?.color;
    final resolvedIconColor = iconColor ?? Theme.of(context).iconTheme.color;

    // কন্টেন্ট তৈরি
    Widget content = Padding(
      padding: bodyPadding,
      child: body,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // আইফোনের মতো বাউন্সি স্ক্রল
        padding: EdgeInsets.only(
            top: contentTopPadding,
            bottom: paddingBottom + 24
        ),
        child: content,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.only(
            top: contentTopPadding,
            bottom: paddingBottom + 24
        ),
        child: content,
      );
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        children: [
          // ১. মেইন বডি (The Body)
          Positioned.fill(child: content),

          // ২. ভাসমান অ্যাপ বার (The Floating App Bar)
          Positioned(
            top: paddingTop + topMargin, // স্ট্যাটাস বারের নিচে পজিশন করা হলো
            left: horizontalMargin,
            right: horizontalMargin,
            height: barHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null
                    ? (backgroundColor ?? Theme.of(context).cardColor)
                    : null,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: boxShadow ?? defaultShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    // ব্যাক বাটন লজিক
                    if (showBack)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _HoverIconButton(
                          icon: Icons.arrow_back_rounded,
                          color: resolvedIconColor ?? Colors.black,
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        ),
                      )
                    else
                      const SizedBox(width: 16),

                    // টাইটেল
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: resolvedTitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // অ্যাকশন বাটনসমূহ
                    IconTheme(
                      data: IconThemeData(color: resolvedIconColor),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),

                    const SizedBox(width: 4),
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

// ✅ উন্নত মানের Hover Icon Button (ইন্টারনাল হেল্পার)
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _HoverIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // থিম অনুযায়ী হোভার কালার সেট হবে
          color: _isHovered
              ? Theme.of(context).hoverColor
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color, size: 22),
          onPressed: widget.onPressed,
          splashRadius: 22,
          tooltip: 'Back',
        ),
      ),
    );
  }
}
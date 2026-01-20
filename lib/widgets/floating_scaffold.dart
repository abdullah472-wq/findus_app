import 'package:flutter/material.dart';

class FloatingScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  final bool showBack;
  final VoidCallback? onBack;

  final bool scrollable;
  final EdgeInsetsGeometry bodyPadding;

  final double top;
  final double radius;
  final double horizontalMargin;
  final double barHeight;

  final Gradient? gradient;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  final Color? titleColor;
  final Color? iconColor;

  const FloatingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.scrollable = true,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.top = 10,
    this.radius = 20,
    this.horizontalMargin = 10,
    this.barHeight = kToolbarHeight,
    this.gradient,
    this.backgroundColor,
    this.boxShadow,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final topSpace = paddingTop + barHeight + top + 10;

    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 2),
      )
    ];

    final content = Padding(
      padding: bodyPadding,
      child: body,
    );

    final resolvedTitleColor =
        titleColor ?? Theme.of(context).textTheme.titleMedium?.color;
    final resolvedIconColor = iconColor ?? Theme.of(context).iconTheme.color;

    return Scaffold(
      body: Stack(
        children: [
          if (scrollable)
            SingleChildScrollView(
              padding: EdgeInsets.only(top: topSpace, bottom: 24),
              child: content,
            )
          else
            Padding(
              padding: EdgeInsets.only(top: topSpace, bottom: 24),
              child: content,
            ),
          Positioned(
            top: top,
            left: horizontalMargin,
            right: horizontalMargin,
            child: Container(
              height: barHeight + paddingTop,
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null
                    ? (backgroundColor ?? Theme.of(context).cardColor)
                    : null,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: boxShadow ?? defaultShadow,
              ),
              child: Column(
                children: [
                  SizedBox(height: paddingTop),
                  SizedBox(
                    height: barHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          if (showBack)
                            _HoverIconButton(
                              icon: Icons.arrow_back,
                              color: resolvedIconColor ?? Colors.black,
                              onPressed:
                              onBack ?? () => Navigator.of(context).pop(),
                            )
                          else
                            const SizedBox(width: 48),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: resolvedTitleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconTheme(
                            data: IconThemeData(color: resolvedIconColor),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: actions),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Hover effect সহ icon button (internal helper)
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
          color: _isHovered
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color, size: 20),
          onPressed: widget.onPressed,
          splashRadius: 20,
        ),
      ),
    );
  }
}
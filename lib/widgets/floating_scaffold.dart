import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class DashboardFloatingAppBar extends StatefulWidget {
  final double scrollOffset;
  final VoidCallback onMenuPressed;
  final VoidCallback onAnalyticsPressed; // ✅ analytics callback
  final VoidCallback onSearchPressed;

  const DashboardFloatingAppBar({
    super.key,
    this.scrollOffset = 0.0,
    required this.onMenuPressed,
    required this.onAnalyticsPressed,
    required this.onSearchPressed,
  });

  @override
  State<DashboardFloatingAppBar> createState() => _DashboardFloatingAppBarState();
}

class _DashboardFloatingAppBarState extends State<DashboardFloatingAppBar> {
  @override
  Widget build(BuildContext context) {
    final double opacity = (widget.scrollOffset / 100).clamp(0.0, 1.0);
    final bool isScrolled = widget.scrollOffset > 20;

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: kToolbarHeight + MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandLight.withOpacity(isScrolled ? 0.95 : 0.8),
              AppColors.brandLight.withOpacity(isScrolled ? 0.9 : 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            if (isScrolled)
              BoxShadow(
                color: Colors.black.withOpacity(0.15 * opacity),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // Menu Button
                    _buildActionButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Menu',
                      onPressed: widget.onMenuPressed,
                    ),

                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: 1.0,
                          child: Text(
                            'DASHBOARD',
                            style: TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                              shadows: isScrolled
                                  ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Search Button
                    _buildActionButton(
                      icon: Icons.search_rounded,
                      tooltip: 'Search',
                      onPressed: widget.onSearchPressed,
                    ),

                    const SizedBox(width: 8),

                    // ✅ Analytics Button (instead of notification)
                    _buildActionButton(
                      icon: Icons.analytics_outlined,
                      tooltip: 'Analytics',
                      onPressed: widget.onAnalyticsPressed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return _HoverActionButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

// ✅ Hover effect সহ action button (FloatingScaffold style)
class _HoverActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<_HoverActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white
                : Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.1),
                blurRadius: _isHovered ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(widget.icon, size: 20, color: Colors.black),
            onPressed: widget.onPressed,
            splashRadius: 20,
          ),
        ),
      ),
    );
  }
}// TODO Implement this library.
// lib/screens/tabs/dashboard/widgets/floating_dashboard_app_bar.dart
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class FloatingDashboardAppBar extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const FloatingDashboardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = false,
  });

  @override
  State<FloatingDashboardAppBar> createState() => _FloatingDashboardAppBarState();
}

class _FloatingDashboardAppBarState extends State<FloatingDashboardAppBar> {
  double _scrollOffset = 0.0;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    // এই controller parent থেকে pass করতে হবে
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final double maxOffset = 100; // কত স্ক্রল হলে full opacity হবে
    final double opacity = (_scrollOffset / maxOffset).clamp(0.0, 1.0);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: appBarHeight,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          boxShadow: opacity > 0.1
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1 * opacity),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (widget.showBackButton)
                      _buildBackButton()
                    else
                      _buildLogo(),
                    Expanded(
                      child: _buildTitle(),
                    ),
                    ..._buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: widget.onBackPressed ?? () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.brandDark,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandMain.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.dashboard_rounded,
        color: AppColors.brandMain,
        size: 20,
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        widget.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
          letterSpacing: 1.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<Widget> _buildActions() {
    final List<Widget> actionWidgets = [];

    if (widget.actions != null) {
      actionWidgets.addAll(widget.actions!);
    }

    // Default notification bell
    actionWidgets.add(
      _buildNotificationButton(),
    );

    return actionWidgets;
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to notifications
        print('Notifications tapped');
      },
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.brandDark,
              size: 20,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
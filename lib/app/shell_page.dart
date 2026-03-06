import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/design_system/design_system.dart';

/// Shell page wrapping the bottom navigation bar and tab content.
///
/// Uses GoRouter's [ShellRoute] to maintain tab state across navigation.
/// The [AppBottomNavBar] from the design system provides the premium
/// glass-effect navigation bar.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.child});

  /// The currently active tab content provided by GoRouter.
  final Widget child;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  /// Determines the current tab index from the GoRouter location.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.insights)) return 1;
    if (location.startsWith(RoutePaths.profile)) return 2;
    return 0;
  }

  /// Navigates to the appropriate tab route.
  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
      case 1:
        context.go(RoutePaths.insights);
      case 2:
        context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        items: const [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          AppBottomNavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Insights',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

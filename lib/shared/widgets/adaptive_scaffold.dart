import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AdaptiveScaffold — Responsive ultra-modern navigation shell
/// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveScaffold extends StatelessWidget {
  final Widget child; // The current page content
  final int selectedIndex; // Which nav item is active (0 to 7)

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  static const List<NavItem> allItems = [
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavItem(
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle_rounded,
      label: 'To-Do',
      route: '/todo',
    ),
    NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'AI Tutor',
      route: '/ai',
    ),
    NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Search',
      route: '/search',
    ),
    NavItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum_rounded,
      label: 'Community',
      route: '/community',
    ),
    NavItem(
      icon: Icons.calculate_outlined,
      activeIcon: Icons.calculate_rounded,
      label: 'Calculator',
      route: '/calculator',
    ),
    NavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'PDF Tools',
      route: '/pdf-tools',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
    NavItem(
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer_rounded,
      label: 'Focus',
      route: '/study-tools',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    context.go(allItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppConstants.tabletBreakpoint) {
      return _DesktopShell(
        selectedIndex: selectedIndex,
        items: allItems,
        onTap: (i) => _onTap(context, i),
        child: child,
      );
    }

    if (width >= AppConstants.mobileBreakpoint) {
      return _TabletShell(
        selectedIndex: selectedIndex,
        items: allItems,
        onTap: (i) => _onTap(context, i),
        child: child,
      );
    }

    return _MobileShell(
      selectedIndex: selectedIndex,
      onTap: (i) => _onTap(context, i),
      child: child,
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// ── Mobile Shell (Glassmorphic Bottom Navbar with Quick Sheets) ──────────────
class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _MobileShell({
    required this.child,
    required this.selectedIndex,
    required this.onTap,
  });

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'StudySpace Suite',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF806A63),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.forum_rounded,
                  color: const Color(0xFF38BDF8),
                  title: 'Community Lounge',
                  subtitle:
                      'Real-time discussion & notes sharing with classmates',
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap(4);
                  },
                ),
                _MenuTile(
                  icon: Icons.calculate_rounded,
                  color: const Color(0xFFF2CC8F),
                  title: 'Scientific Calculator',
                  subtitle:
                      '100% offline scientific calculations & expression history',
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap(5);
                  },
                ),
                _MenuTile(
                  icon: Icons.description_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'PDF & Document Studio',
                  subtitle:
                      'Convert, merge, extract text & view Word/PDF docs in-app',
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap(6);
                  },
                ),
                _MenuTile(
                  icon: Icons.person_rounded,
                  color: const Color(0xFFE07A5F),
                  title: 'My Profile & Preferences',
                  subtitle:
                      'Manage account, guest status, and academic settings',
                  onTap: () {
                    Navigator.pop(ctx);
                    onTap(7);
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07A5F).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE07A5F).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'StudySpace v${AppConstants.appVersion}',
                      style: TextStyle(
                        color: Color(0xFFD66A50),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobileIndex = selectedIndex < 4 ? selectedIndex : 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8).withValues(alpha: 0.85),
          border: const Border(top: BorderSide(color: Color(0xFFF7EBDD))),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: mobileIndex,
                onTap: (index) {
                  if (index == 4) {
                    _showMoreMenu(context);
                  } else {
                    onTap(index);
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFD66A50),
                unselectedItemColor: const Color(0xFF64748B),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.check_circle_outline),
                    activeIcon: Icon(Icons.check_circle_rounded),
                    label: 'To-Do',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome_outlined),
                    activeIcon: Icon(Icons.auto_awesome_rounded),
                    label: 'AI Tutor',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    activeIcon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.widgets_outlined),
                    activeIcon: Icon(Icons.widgets_rounded),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBDD).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D4C4)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF806A63), fontSize: 12),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ── Tablet Shell ──────────────────────────────────────────────────────────────
class _TabletShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const _TabletShell({
    required this.child,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex.clamp(0, items.length - 1),
            onDestinationSelected: onTap,
            backgroundColor: const Color(0xFFFFFCF8),
            useIndicator: true,
            indicatorColor: const Color(0xFFE07A5F).withValues(alpha: 0.2),
            labelType: NavigationRailLabelType.selected,
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFFD66A50),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon, color: const Color(0xFF64748B)),
                    selectedIcon: Icon(
                      item.activeIcon,
                      color: const Color(0xFFD66A50),
                    ),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFF7EBDD)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop Shell (Glassmorphic Sidebar) ──────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const _DesktopShell({
    required this.child,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Container(
              color: const Color(0xFFFFFCF8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE07A5F),
                                Color(0xFFF2CC8F),
                                Color(0xFFEC4899),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE07A5F,
                                ).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '✦',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'StudySpace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Student Operating System',
                              style: TextStyle(
                                color: Color(0xFF806A63),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = index == selectedIndex;
                        return _SidebarItem(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => onTap(index),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Color(0xFFF7EBDD), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE07A5F,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFE07A5F,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'v${AppConstants.appVersion}',
                            style: TextStyle(
                              color: Color(0xFFD66A50),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFF7EBDD)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFE07A5F).withValues(alpha: 0.22),
                        const Color(0xFFF2CC8F).withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFE07A5F).withValues(alpha: 0.4),
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? const Color(0xFFD66A50)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF806A63),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

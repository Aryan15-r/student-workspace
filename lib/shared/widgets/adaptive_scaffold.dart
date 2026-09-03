import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AdaptiveScaffold — Responsive navigation shell
///
/// Automatically switches between:
///   Mobile  (< 600px):  Bottom navigation bar
///   Tablet  (600–1024): Navigation rail
///   Desktop (> 1024px): Sidebar navigation
///
/// Every authenticated page is wrapped in this widget.
/// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveScaffold extends StatelessWidget {
  final Widget child;       // The current page content
  final int selectedIndex;  // Which nav item is active

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  // ── Nav destinations ───────────────────────────────────────────────────────
  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        label: 'Home',      route: '/dashboard'),
    _NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle_rounded,label: 'To-Do',     route: '/todo'),
    _NavItem(icon: Icons.auto_awesome_outlined,activeIcon: Icons.auto_awesome_rounded, label: 'AI',       route: '/ai'),
    _NavItem(icon: Icons.search_outlined,      activeIcon: Icons.search_rounded,       label: 'Search',   route: '/search'),
    _NavItem(icon: Icons.people_outline,       activeIcon: Icons.people_rounded,       label: 'Community',route: '/community'),
    _NavItem(icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view_rounded,    label: 'Tools',    route: '/calculator'),
    _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,       label: 'Profile',  route: '/profile'),
  ];

  void _onTap(BuildContext context, int index) {
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppConstants.tabletBreakpoint) {
      return _DesktopShell(
        selectedIndex: selectedIndex,
        items: _items,
        onTap: (i) => _onTap(context, i),
        child: child,
      );
    }

    if (width >= AppConstants.mobileBreakpoint) {
      return _TabletShell(
        selectedIndex: selectedIndex,
        items: _items,
        onTap: (i) => _onTap(context, i),
        child: child,
      );
    }

    return _MobileShell(
      selectedIndex: selectedIndex,
      items: _items,
      onTap: (i) => _onTap(context, i),
      child: child,
    );
  }
}

// ── Nav Item model ─────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// ── Mobile Shell (Bottom Navigation Bar) ──────────────────────────────────────
class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _MobileShell({
    required this.child,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: items.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}

// ── Tablet Shell (Navigation Rail) ────────────────────────────────────────────
class _TabletShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;
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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
            backgroundColor: AppColors.surface,
            useIndicator: true,
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            labelType: NavigationRailLabelType.selected,
            destinations: items.map((item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
              label: Text(item.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop Shell (Sidebar) ───────────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final List<_NavItem> items;
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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          SizedBox(
            width: 240,
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'StudySpace',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nav items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          // ── Main content ──────────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

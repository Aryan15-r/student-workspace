import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AdaptiveScaffold — Responsive navigation shell
///
/// Automatically switches between:
///   Mobile  (< 600px):  5-tab Bottom navigation bar (with More modal)
///   Tablet  (600–1024): Navigation rail
///   Desktop (> 1024px): Sidebar navigation
/// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveScaffold extends StatelessWidget {
  final Widget child;       // The current page content
  final int selectedIndex;  // Which nav item is active (0 to 6)

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  // ── All Nav destinations ───────────────────────────────────────────────────
  static const List<NavItem> allItems = [
    NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        label: 'Home',      route: '/dashboard'),
    NavItem(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle_rounded,label: 'To-Do',     route: '/todo'),
    NavItem(icon: Icons.auto_awesome_outlined,activeIcon: Icons.auto_awesome_rounded, label: 'AI',       route: '/ai'),
    NavItem(icon: Icons.search_outlined,      activeIcon: Icons.search_rounded,       label: 'Search',   route: '/search'),
    NavItem(icon: Icons.people_outline,       activeIcon: Icons.people_rounded,       label: 'Community',route: '/community'),
    NavItem(icon: Icons.calculate_outlined,   activeIcon: Icons.calculate_rounded,    label: 'Calculator',route: '/calculator'),
    NavItem(icon: Icons.picture_as_pdf_outlined, activeIcon: Icons.picture_as_pdf_rounded, label: 'PDF Tools', route: '/pdf-tools'),
    NavItem(icon: Icons.person_outline,       activeIcon: Icons.person_rounded,       label: 'Profile',  route: '/profile'),
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

// ── Nav Item model ─────────────────────────────────────────────────────────────
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

// ── Mobile Shell (5-tab Bottom Navigation Bar with More Sheet) ────────────────
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'More Tools',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.people_rounded, color: AppColors.accent),
                  title: const Text('Community Lounge', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Chat and collaborate with classmates', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () { Navigator.pop(ctx); onTap(4); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_rounded, color: AppColors.secondary),
                  title: const Text('Scientific Calculator', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Works 100% offline with expressions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () { Navigator.pop(ctx); onTap(5); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.warning),
                  title: const Text('PDF Tools', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Convert, merge, and extract PDF text', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () { Navigator.pop(ctx); onTap(6); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                ListTile(
                  leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                  title: const Text('My Profile & Settings', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Manage your account and preferences', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  onTap: () { Navigator.pop(ctx); onTap(7); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: const Text(
                      'StudySpace v${AppConstants.appVersion}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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
    // Determine which mobile tab is selected (0 to 3, or 4 for 'More')
    final mobileIndex = selectedIndex < 4 ? selectedIndex : 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
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
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle_rounded), label: 'To-Do'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome_rounded), label: 'AI'),
              BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search_rounded), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tablet Shell (Navigation Rail) ────────────────────────────────────────────
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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex.clamp(0, items.length - 1),
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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Divider(color: AppColors.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: const Text(
                            'v${AppConstants.appVersion}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
          const VerticalDivider(width: 1, color: AppColors.border),
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

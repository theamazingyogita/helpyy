import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';

class _Tab {
  const _Tab(
    this.label,
    this.material,
    this.materialSelected,
    this.cupertino,
    this.cupertinoSelected,
  );

  final String label;
  final IconData material;
  final IconData materialSelected;
  final IconData cupertino;
  final IconData cupertinoSelected;
}

const _tabs = [
  _Tab(
    'Home',
    Icons.home_outlined,
    Icons.home_rounded,
    CupertinoIcons.house,
    CupertinoIcons.house_fill,
  ),
  _Tab(
    'Calls',
    Icons.phone_outlined,
    Icons.phone_rounded,
    CupertinoIcons.phone,
    CupertinoIcons.phone_fill,
  ),
  _Tab(
    'Settings',
    Icons.settings_outlined,
    Icons.settings_rounded,
    CupertinoIcons.gear,
    CupertinoIcons.gear_solid,
  ),
];

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final isApple = switch (theme.platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    if (isApple) {
      return CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: onSelected,
        backgroundColor: colorScheme.surface,
        activeColor: colorScheme.primary,
        inactiveColor: colors.muted,
        iconSize: 28,
        border: null,
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.cupertino, semanticLabel: tab.label),
              activeIcon: Icon(tab.cupertinoSelected, semanticLabel: tab.label),
              tooltip: tab.label,
            ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: [
        for (final tab in _tabs)
          NavigationDestination(
            icon: Icon(tab.material),
            selectedIcon: Icon(tab.materialSelected),
            label: tab.label,
            tooltip: tab.label,
          ),
      ],
    );
  }
}

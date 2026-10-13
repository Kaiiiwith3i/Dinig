import 'package:flutter/material.dart';
import '../theme/dinig_theme.dart';

/// A standard iOS tab bar: full width, icon over label, one tint for the
/// selected tab.
class DinigBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const DinigBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.description_outlined, Icons.description, 'Reports'),
      (Icons.phone_outlined, Icons.phone, 'Hotlines'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];

    return Material(
      color: DinigColors.cardSurface,
      shape: const Border(top: BorderSide(color: DinigColors.borderLight)),
      child: SafeArea(
        top: false,
        // Tab labels keep their size, as the system tab bar's do.
        child: MediaQuery.withNoTextScaling(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final (index, item) in items.indexed)
                  Expanded(
                    child: Semantics(
                      selected: currentIndex == index,
                      child: InkWell(
                        onTap: () => onTabSelected(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentIndex == index ? item.$2 : item.$1,
                              size: 26,
                              color: currentIndex == index
                                  ? DinigColors.primaryBlue
                                  : DinigColors.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: currentIndex == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: currentIndex == index
                                    ? DinigColors.primaryBlue
                                    : DinigColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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

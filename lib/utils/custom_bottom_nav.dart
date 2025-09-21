import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _icons = [
    Icons.home_outlined,
    Icons.newspaper_outlined,
    Icons.favorite_outline,
    Icons.storefront_outlined,
    Icons.person_outline,
  ];

  static const _activeIcons = [
    Icons.home,
    Icons.newspaper,
    Icons.favorite,
    Icons.store,
    Icons.person,
  ];

  static const _labels = ['Home', 'News', 'Match', 'Market', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.translucent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? _activeIcons[index] : _icons[index],
                    color: isSelected ? AppColors.primary : AppColors.subtitle,
                    size: isSelected ? 28 : 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.subtitle,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

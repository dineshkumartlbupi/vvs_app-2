import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class CustomBottomNav extends StatefulWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _pressedIndex;

  static const _icons = [
    Icons.home_outlined,
    Icons.newspaper_outlined,
    Icons.favorite_outline,
    Icons.storefront_outlined,
    Icons.person_outline,
  ];

  static const _activeIcons = [
    Icons.home_rounded,
    Icons.newspaper_rounded,
    Icons.favorite_rounded,
    Icons.storefront_rounded,
    Icons.person_rounded,
  ];

  static const _labels = ['Home', 'News', 'Match', 'Market', 'Profile'];

  static const _colors = [
    AppColors.primary, // Home - Orange
    AppColors.accent, // News - Bright Orange
    AppColors.error, // Match - Red
    AppColors.gold, // Market - Gold
    AppColors.primary, // Profile - Orange
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _pressedIndex = index);
    _animationController.forward().then((_) {
      _animationController.reverse();
      widget.onTap(index);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _pressedIndex = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.card,
                AppColors.card.withOpacity(0.98),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_icons.length, (index) {
                  final isSelected = index == widget.selectedIndex;
                  final isPressing = index == _pressedIndex;
                  final color = _colors[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _handleTap(index),
                      behavior: HitTestBehavior.translucent,
                      child: ScaleTransition(
                        scale: isPressing ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      color.withOpacity(0.15),
                                      color.withOpacity(0.08),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: color.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon container with subtle glow when selected
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(0.15)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isSelected ? _activeIcons[index] : _icons[index],
                                  color: isSelected ? color : AppColors.subtitle,
                                  size: isSelected ? 26 : 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Label
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: isSelected ? 12 : 11,
                                  color: isSelected ? color : AppColors.subtitle,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                                child: Text(
                                  _labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Active indicator dot
                              if (isSelected) ...[
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

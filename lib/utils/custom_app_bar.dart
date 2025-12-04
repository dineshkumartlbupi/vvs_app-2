import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vvs_app/constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_components.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMenuTap;

  /// Optional enhancements
  final bool autoScroll; // slide auto-advance
  final Duration slideInterval;
  final Duration slideDuration;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onProfileTap,
    this.onMenuTap,
    this.autoScroll = true,
    this.slideInterval = const Duration(seconds: 5),
    this.slideDuration = const Duration(milliseconds: 450),
  });

  // Enhanced height for better visual presence
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late AnimationController _shimmerController;
  int _currentPage = 0;
  Timer? _autoTimer;

  final List<Map<String, String>> _slidesText = const [
    {'title': '', 'subtitle': appTitle},
    {'title': 'Connect  •  Share  •  Grow', 'subtitle': ''},
    {
      'title': 'Empowering our Varshney Samaj',
      'subtitle': 'Together, we thrive.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Ensure controller has clients before starting auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    if (!widget.autoScroll || _slidesText.length < 2) return;
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(widget.slideInterval, (_) async {
      if (!mounted || !_pageController.hasClients) return;

      final next = (_currentPage + 1) % _slidesText.length;
      try {
        if (next == 0) {
          // wrap-around: animate back to first slide
          await _pageController.animateToPage(
            0,
            duration: widget.slideDuration,
            curve: Curves.easeInOutCubic,
          );
        } else {
          await _pageController.nextPage(
            duration: widget.slideDuration,
            curve: Curves.easeInOutCubic,
          );
        }
      } catch (_) {
        // If the controller detaches momentarily (hot reload, route change), ignore
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.95),
            AppColors.accent.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with enhanced styling
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
             
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Animated subtitle slider
            SizedBox(
              height: 20,
              child: GestureDetector(
                onPanDown: (_) {
                  HapticFeedback.selectionClick();
                  _autoTimer?.cancel();
                },
                onPanEnd: (_) => _startAutoScroll(),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _slidesText.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, i) {
                    final item = _slidesText[i];
                    final text = (item['title']?.isNotEmpty ?? false)
                        ? item['title']!
                        : (item['subtitle'] ?? '');

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Align(
                        key: ValueKey(text),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Page indicator dots
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _slidesText.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentPage == index ? 16 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Enhanced menu button
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (widget.onMenuTap != null) {
                widget.onMenuTap!();
              } else {
                Scaffold.maybeOf(context)?.openDrawer();
              }
            },
            tooltip: 'Menu',
            padding: EdgeInsets.zero,
          ),
        ),
        // Enhanced profile/logo button
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onProfileTap?.call();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

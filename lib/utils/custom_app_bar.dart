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
    this.slideInterval = const Duration(seconds: 4),
    this.slideDuration = const Duration(milliseconds: 450),
  });

  // Use the actual default toolbar height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late final PageController _pageController;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTitle(widget.title, color: Colors.white, size: 18),
          const SizedBox(height: 2),
          // Single-line slider INSIDE the toolbar height
          SizedBox(
            height: 20,
            child: GestureDetector(
              onPanDown: (_) => _autoTimer?.cancel(),
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
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Align(
                      key: ValueKey(text),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AppSubTitle(
                          text,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed:
            widget.onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
        tooltip: 'Menu',
      ),
      actions: [
        GestureDetector(
          onTap: widget.onProfileTap,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

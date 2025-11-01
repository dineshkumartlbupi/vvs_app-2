import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsDetailScreen.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AutoSlidingNewsBanner extends StatefulWidget {
  final List<Map<String, String>> slidesNews;

  /// kept for API compatibility; not used internally
  final bool isLoading;

  const AutoSlidingNewsBanner({
    super.key,
    required this.slidesNews,
    required this.isLoading,
  });

  @override
  State<AutoSlidingNewsBanner> createState() => _AutoSlidingNewsBannerState();
}

class _AutoSlidingNewsBannerState extends State<AutoSlidingNewsBanner>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: true);
    // Start auto-slide after first frame so controller has clients.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartTimer());
  }

  @override
  void didUpdateWidget(covariant AutoSlidingNewsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slidesNews.length != widget.slidesNews.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!mounted) return;
    if (widget.slidesNews.length < 2) return; // nothing to slide

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.slidesNews.length;
      try {
        await _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (_) {
        // Ignore occasional detach (hot reload / route transition).
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final hasItems = widget.slidesNews.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 254,
        child: Column(
          children: [
            Expanded(
              child: Listener(
                onPointerDown: (_) => _timer?.cancel(), // pause while dragging
                onPointerUp: (_) => _restartTimer(), // resume after
                child: hasItems
                    ? PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.slidesNews.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (ctx, i) {
                          final news = widget.slidesNews[i];
                          final imageUrl = (news['imageUrl'] ?? '').trim();
                          final title = (news['title'] ?? '').trim();
                          final content = (news['content'] ?? '').trim();

                          return GestureDetector(
                            onTap: () => _onNewsTap(news),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            height: 132,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _imageFallback(),
                                            loadingBuilder:
                                                (ctx, child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }
                                                  return _imageFallback(
                                                    isLoading: true,
                                                  );
                                                },
                                          )
                                        : _imageFallback(),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 6),
                                              Text(
                                                title.isEmpty
                                                    ? 'Varshney One Update'
                                                    : title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                  letterSpacing: 0.4,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              if (content.isNotEmpty)
                                                Text(
                                                  content,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: AppSubTitle('No news available')),
              ),
            ),
            const SizedBox(height: 6),
            _buildPageIndicator(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback({bool isLoading = false}) => Container(
    height: 120,
    width: double.infinity,
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.image_not_supported),
  );

  Widget _buildPageIndicator() {
    if (widget.slidesNews.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.slidesNews.length, (index) {
        final active = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey[400],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  void _onNewsTap(Map<String, String> news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailScreen(newsData: news)),
    );
  }
}

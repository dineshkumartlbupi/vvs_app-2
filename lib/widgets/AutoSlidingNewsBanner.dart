import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsDetailScreen.dart';
//import 'package:vvs_app/screens/News/NewsDetailScreen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class AutoSlidingNewsBanner extends StatefulWidget {
  final List<Map<String, String>> slidesNews;

  const AutoSlidingNewsBanner({
    super.key,
    required this.slidesNews,
    required bool isLoading,
  });

  @override
  State<AutoSlidingNewsBanner> createState() => _AutoSlidingNewsBannerState();
}

class _AutoSlidingNewsBannerState extends State<AutoSlidingNewsBanner> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.slidesNews.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Widget buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.slidesNews.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.primary : Colors.grey[400],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.slidesNews.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) {
                  final news = widget.slidesNews[i];
                  return GestureDetector(
                    onTap: () => _onNewsTap(news),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              news['imageUrl'] ?? '',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit
                                  .fitHeight, // keeps width proper, avoids vertical stretch
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (news['imageUrl'] != null &&
                                  news['imageUrl']!.isNotEmpty)
                                const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(
                                      news['title'] ?? '',
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
                                    Text(
                                      news['content'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            buildPageIndicator(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _onNewsTap(Map<String, String> news) {
    print('News tapped: ${news['title']}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(newsData: news)),
    );
  }
}

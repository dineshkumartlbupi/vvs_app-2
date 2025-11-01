import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/blood_donor/screen/blood_donor_form.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/screens/family_registration_screen.dart';
import 'package:vvs_app/screens/events_screen/events_screen.dart';
import 'package:vvs_app/screens/marketplace/marketplace_all_screen.dart.dart';
import 'package:vvs_app/services/home_service.dart';

import 'package:vvs_app/widgets/AutoSlidingNewsBanner.dart';
import 'package:vvs_app/widgets/bottom_footer.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ui_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// News list
  List<Map<String, String>> _slidesNews = [];
  bool _isLoadingNews = true;
  String? _newsError;
  final HomeService _homeService = HomeService();
  bool _isLoadingStats = true;
  Map<String, int> _stats = {};
  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await _homeService.fetchQuickStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          // .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      final docs = querySnapshot.docs;
      if (!mounted) return;

      setState(() {
        if (docs.isEmpty) {
          _slidesNews = [
            {
              'title': 'No news available.',
              'content': '',
              'imageUrl': '',
              'timestamp': '',
            },
          ];
        } else {
          _slidesNews = docs.map((doc) {
            final data = doc.data();
            // Safe stringify timestamp (supports Timestamp or String)
            String ts = '';
            final raw = data['timestamp'];
            if (raw is Timestamp) {
              final d = raw.toDate();
              ts =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
                  '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            } else if (raw is String) {
              ts = raw;
            }
            return {
              'title': (data['title'] ?? '').toString(),
              'content': (data['content'] ?? '').toString(),
              'imageUrl': (data['imageUrl'] ?? '').toString(),
              'timestamp': ts,
            };
          }).toList();
        }
        _isLoadingNews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNews = false;
        _newsError = 'Unable to load news';
        _slidesNews = [
          {
            'title': '⚠️ Unable to load news at this moment',
            'content': '',
            'imageUrl': '',
            'timestamp': '',
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNews,
          color: AppColors.primary,
          child: ListView(
            key: const PageStorageKey('home_list'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // Header
              Row(
                children: [
                  Expanded(child: AppTitle("Welcome to Varshney One")),
                ],
              ),
              const SizedBox(height: 12),

              // News Banner with graceful states
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLoadingNews
                    ? _NewsSkeleton(cardColor: AppColors.card)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_newsError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  AppSubTitle(
                                    'Showing cached/fallback news',
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          AutoSlidingNewsBanner(
                            slidesNews: _slidesNews,
                            isLoading: _isLoadingNews,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              _SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              _QuickActionsGrid(
                onFamilyTap: _navigateToAddMember,
                onDonorTap: _navigateToBloodDonorForm,
                onMarketTap: _navigateToMarketplace,
                onEventsTap: _navigateToEvents,
              ),

              const SizedBox(height: 24),
              _HighlightCTA(
                title: 'Did You Register Your Family?',
                subtitle: 'Keep your family connected and searchable.',
                buttonText: 'Register Now',
                onPressed: _navigateToAddMember,
                accentColor: AppColors.primary,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(height: 16),
              _HighlightCTA(
                title: 'Did You Register as a Blood Donor?',
                subtitle: 'Help save lives by joining our donor network.',
                buttonText: 'Become a Blood Donor',
                onPressed: _navigateToBloodDonorForm,
                accentColor: AppColors.gold,
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.14),
                    AppColors.gold.withOpacity(0.07),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),

              const SizedBox(height: 24),

              // Announcements
              _SectionHeader(
                title: 'Recent Announcements',
                actionText: 'See all',
                onAction: () {},
              ),
              const SizedBox(height: 8),
              _buildCard(
                title: '',
                children: const [
                  _BulletLine('Blood Donation Camp – Aug 15, 2025'),
                  _BulletLine('Samaj Youth Meet Highlights Uploaded'),
                  _BulletLine('Scholarship Applications Open Until Sep 10'),
                ],
              ),
              const SizedBox(height: 24),
              // Highlights
              _SectionHeader(title: 'Community Highlights'),
              const SizedBox(height: 8),
              _buildCard(
                title: '',
                children: const [
                  _BulletLine('Dr. Asha Varshney awarded Padma Shri'),
                  _BulletLine('Launch of Varshney One Matrimonial App'),
                  _BulletLine('New Health Insurance Tie-up Announced'),
                ],
              ),
              const SizedBox(height: 24),
              // Explore
              _SectionHeader(title: 'Explore More'),
              const SizedBox(height: 8),
              _buildCard(
                title: '',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppOutlinedButton(text: 'Matrimonial', onPressed: () {}),
                      AppOutlinedButton(text: 'MarketPlace', onPressed: () {}),
                      AppOutlinedButton(
                        text: 'Offers & Discounts',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats
              _SectionHeader(title: 'Quick Stats'),
              const SizedBox(height: 8),
              _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _StatsStrip(
                      items: [
                        _StatItemData(
                          icon: Icons.groups_2_rounded,
                          label: 'Members',
                          value: _stats['members'].toString(),
                        ),
                        _StatItemData(
                          icon: Icons.family_restroom_rounded,
                          label: 'Families',
                          value: _stats['families'].toString(),
                        ),
                        _StatItemData(
                          icon: Icons.volunteer_activism_rounded,
                          label: 'Donors',
                          value: _stats['donors'].toString(),
                        ),
                        _StatItemData(
                          icon: Icons.event_available_rounded,
                          label: 'Events',
                          value: _stats['events'].toString(),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              const BottomFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddMember() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyRegistrationScreen()),
    );
  }

  void _navigateToBloodDonorForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BloodDonorFormScreen()),
    );
  }

  void _navigateToMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceAllScreen()),
    );
  }

  void _navigateToEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
  }

  /// Reusable card
  Widget _buildCard({required String title, required List<Widget> children}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            AppLabel(title),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/* =========================== Helper Widgets =========================== */

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AppLabel(title)),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class _HighlightCTA extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final Color accentColor;
  final Gradient gradient;

  const _HighlightCTA({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.accentColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 420; // phone portrait

        final textCol = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLabel(title),
              const SizedBox(height: 6),
              AppSubTitle(subtitle),
            ],
          ),
        );

        final buttonWide = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
          child: AppButton(text: buttonText, onPressed: onPressed),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            border: Border.all(color: accentColor.withOpacity(0.45)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isNarrow
              // Column on narrow screens: full-width button is safe (finite width)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: accentColor, size: 28),
                        const SizedBox(width: 12),
                        textCol,
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(text: buttonText, onPressed: onPressed),
                    ),
                  ],
                )
              // Row on wide screens: button gets explicit width constraints
              : Row(
                  children: [
                    Icon(Icons.star_rounded, color: accentColor, size: 28),
                    const SizedBox(width: 12),
                    textCol,
                    const SizedBox(width: 12),
                    buttonWide,
                  ],
                ),
        );
      },
    );
  }
}

/* ======================= Quick Actions (Improved) ======================= */
/* ======================= Quick Actions (Truly Responsive) ======================= */

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onFamilyTap;
  final VoidCallback onDonorTap;
  final VoidCallback onMarketTap;
  final VoidCallback onEventsTap;

  const _QuickActionsGrid({
    required this.onFamilyTap,
    required this.onDonorTap,
    required this.onMarketTap,
    required this.onEventsTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const spacing = 12.0;
        const minTileWidth = 150.0; // desired minimum tile width

        final maxW = constraints.maxWidth;
        // Compute columns from available width and min tile width.
        int cross = ((maxW + spacing) / (minTileWidth + spacing)).floor();
        cross = cross.clamp(2, 6); // keep between 2 and 6 columns

        // Compute actual item width & a nice height → derive aspect ratio.
        final itemWidth = (maxW - (cross - 1) * spacing) / cross;
        final itemHeight = itemWidth < 170 ? 92.0 : 110.0;
        final aspect = itemWidth / itemHeight;

        final items = [
          _QuickAction(
            icon: Icons.family_restroom_rounded,
            label: 'Family Registration',
            onTap: onFamilyTap,
          ),
          _QuickAction(
            icon: Icons.volunteer_activism_rounded,
            label: 'Blood Donor',
            onTap: onDonorTap,
          ),

          _QuickAction(
            icon: Icons.storefront_rounded,
            label: 'Marketplace',
            onTap: onMarketTap,
          ),

          _QuickAction(
            icon: Icons.event_available_rounded,
            label: 'Events',
            onTap: onEventsTap,
          ),
        ];

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspect,
          ),
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final compact = (w < 170) || (h < 100);

          final iconSize = compact ? 22.0 : 28.0;
          final pad = compact ? 12.0 : 14.0;
          final gap = compact ? 8.0 : 10.0;

          final iconBox = Container(
            width: iconSize + 20,
            height: iconSize + 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: iconSize),
          );

          final labelWidget = Text(
            label,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: compact ? TextAlign.start : TextAlign.center,
          );

          return Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.all(pad),
                // Switch layout based on available space **inside each tile**
                child: compact
                    ? Row(
                        children: [
                          iconBox,
                          SizedBox(width: gap),
                          Expanded(child: labelWidget),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          iconBox,
                          SizedBox(height: gap),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: labelWidget,
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final List<_StatItemData> items;
  const _StatsStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((e) => _StatItem(icon: e.icon, label: e.label, value: e.value))
          .toList(),
    );
  }
}

class _StatItemData {
  final IconData icon;
  final String label;
  final String value;
  const _StatItemData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubTitle(label, color: Colors.black),
                const SizedBox(height: 2),
                AppLabel(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsSkeleton extends StatefulWidget {
  final Color cardColor;
  const _NewsSkeleton({required this.cardColor});

  @override
  State<_NewsSkeleton> createState() => _NewsSkeletonState();
}

class _NewsSkeletonState extends State<_NewsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _a = Tween(
    begin: 0.35,
    end: 0.75,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(),
                  const SizedBox(height: 8),
                  _bar(widthFactor: 0.8),
                  const SizedBox(height: 8),
                  _bar(widthFactor: 0.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({double widthFactor = 1}) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

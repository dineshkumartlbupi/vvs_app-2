import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// News list
  List<Map<String, String>> _slidesNews = [];
  bool _isLoadingNews = true;
  String? _newsError;
  final HomeService _homeService = HomeService();
  bool _isLoadingStats = true;
  Map<String, int> _stats = {};

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchStats();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.98),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await Future.wait([_fetchNews(), _fetchStats()]);
          },
          color: AppColors.primary,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                key: const PageStorageKey('home_list'),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // Enhanced Header
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Stats Strip (moved to top for prominence)
                   // News Banner with graceful states
                  _buildNewsSection(),

                  const SizedBox(height: 24),
                  
                  _buildStatsSection(),

                  const SizedBox(height: 24),

                 

                  // Quick Actions
                  _SectionHeader(
                    title: 'Quick Actions',
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(
                    onFamilyTap: _navigateToAddMember,
                    onDonorTap: _navigateToBloodDonorForm,
                    onMarketTap: _navigateToMarketplace,
                    onEventsTap: _navigateToEvents,
                  ),

                  const SizedBox(height: 24),

                  // Feature CTAs
                  _buildFeatureCTAs(),

                  const SizedBox(height: 24),

                  // Announcements
                  _SectionHeader(
                    title: 'Recent Announcements',
                    actionText: 'See all',
                    icon: Icons.campaign_rounded,
                    onAction: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedCard(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.primary,
                    children: const [
                      _EnhancedBulletLine(
                        'Blood Donation Camp – Aug 15, 2025',
                        icon: Icons.volunteer_activism,
                      ),
                      _EnhancedBulletLine(
                        'Samaj Youth Meet Highlights Uploaded',
                        icon: Icons.groups,
                      ),
                      _EnhancedBulletLine(
                        'Scholarship Applications Open Until Sep 10',
                        icon: Icons.school,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Highlights
                  _SectionHeader(
                    title: 'Community Highlights',
                    icon: Icons.celebration_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedCard(
                    icon: Icons.stars_rounded,
                    iconColor: AppColors.gold,
                    children: const [
                      _EnhancedBulletLine(
                        'Dr. Asha Varshney awarded Padma Shri',
                        icon: Icons.emoji_events,
                      ),
                      _EnhancedBulletLine(
                        'Launch of Varshney One Matrimonial App',
                        icon: Icons.favorite,
                      ),
                      _EnhancedBulletLine(
                        'New Health Insurance Tie-up Announced',
                        icon: Icons.health_and_safety,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Explore
                  _SectionHeader(
                    title: 'Explore More',
                    icon: Icons.explore_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildExploreSection(),

                  const SizedBox(height: 24),
                  const BottomFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.accent.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Varshney Samaj',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'संस्कार • एकता • जनसेवा',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Quick Stats',
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoadingStats
              ? _StatsLoadingSkeleton()
              : _EnhancedStatsGrid(
                  items: [
                    _StatItemData(
                      icon: Icons.groups_2_rounded,
                      label: 'Members',
                      value: _stats['members'].toString(),
                      color: AppColors.primary,
                    ),
                    _StatItemData(
                      icon: Icons.family_restroom_rounded,
                      label: 'Families',
                      value: _stats['families'].toString(),
                      color: AppColors.accent,
                    ),
                    _StatItemData(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Donors',
                      value: _stats['donors'].toString(),
                      color: AppColors.error,
                    ),
                    _StatItemData(
                      icon: Icons.event_available_rounded,
                      label: 'Events',
                      value: _stats['events'].toString(),
                      color: AppColors.gold,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Latest News',
          icon: Icons.article_rounded,
        ),
        const SizedBox(height: 12),
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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Showing cached/fallback news',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    AutoSlidingNewsBanner(
                      slidesNews: _slidesNews,
                      isLoading: _isLoadingNews,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFeatureCTAs() {
    return Column(
      children: [
        _EnhancedHighlightCTA(
          title: 'Register Your Family',
          subtitle: 'Keep your family connected and searchable in our network.',
          buttonText: 'Register Now',
          onPressed: _navigateToAddMember,
          icon: Icons.family_restroom_rounded,
          accentColor: AppColors.primary,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const SizedBox(height: 12),
        _EnhancedHighlightCTA(
          title: 'Become a Blood Donor',
          subtitle: 'Help save lives by joining our blood donor network.',
          buttonText: 'Register as Donor',
          onPressed: _navigateToBloodDonorForm,
          icon: Icons.volunteer_activism_rounded,
          accentColor: AppColors.error,
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(0.15),
              AppColors.error.withOpacity(0.05),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildExploreSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExploreChip(
                label: 'Matrimonial',
                icon: Icons.favorite_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                },
              ),
              _ExploreChip(
                label: 'Marketplace',
                icon: Icons.storefront_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _navigateToMarketplace();
                },
              ),
              _ExploreChip(
                label: 'Offers & Discounts',
                icon: Icons.local_offer_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                },
              ),
              _ExploreChip(
                label: 'Directory',
                icon: Icons.menu_book_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                },
              ),
              _ExploreChip(
                label: 'Donate',
                icon: Icons.volunteer_activism_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard({
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _navigateToAddMember() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyRegistrationScreen()),
    );
  }

  void _navigateToBloodDonorForm() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BloodDonorFormScreen()),
    );
  }

  void _navigateToMarketplace() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceAllScreen()),
    );
  }

  void _navigateToEvents() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
  }
}

/* ============================ Helper Widgets ============================ */

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EnhancedHighlightCTA extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData icon;
  final Color accentColor;
  final Gradient gradient;

  const _EnhancedHighlightCTA({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.icon,
    required this.accentColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        border: Border.all(color: accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.subtitle,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: accentColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= Quick Actions (Enhanced) ======================= */

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
        const minTileWidth = 150.0;

        final maxW = constraints.maxWidth;
        int cross = ((maxW + spacing) / (minTileWidth + spacing)).floor();
        cross = cross.clamp(2, 4);

        final itemWidth = (maxW - (cross - 1) * spacing) / cross;
        final itemHeight = 100.0;
        final aspect = itemWidth / itemHeight;

        final items = [
          _EnhancedQuickAction(
            icon: Icons.family_restroom_rounded,
            label: 'Family',
            onTap: onFamilyTap,
            color: AppColors.primary,
          ),
          _EnhancedQuickAction(
            icon: Icons.volunteer_activism_rounded,
            label: 'Blood Donor',
            onTap: onDonorTap,
            color: AppColors.error,
          ),
          _EnhancedQuickAction(
            icon: Icons.storefront_rounded,
            label: 'Marketplace',
            onTap: onMarketTap,
            color: AppColors.accent,
          ),
          _EnhancedQuickAction(
            icon: Icons.event_available_rounded,
            label: 'Events',
            onTap: onEventsTap,
            color: AppColors.gold,
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

class _EnhancedQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _EnhancedQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ======================= Stats Grid (Fully Responsive) ======================= */

class _EnhancedStatsGrid extends StatelessWidget {
  final List<_StatItemData> items;
  const _EnhancedStatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Calculate columns based on available width
        int columns;
        double aspectRatio;
        
        if (width < 400) {
          // Very small screens (narrow phones): 1 column
          columns = 1;
          aspectRatio = 2.8; // Wider cards
        } else if (width < 600) {
          // Small screens (phones): 2 columns
          columns = 2;
          aspectRatio = 1.6;
        } else if (width < 900) {
          // Medium screens (large phones, small tablets): 3 columns
          columns = 3;
          aspectRatio = 1.5;
        } else {
          // Large screens (tablets, desktop): 4 columns
          columns = 4;
          aspectRatio = 1.4;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _EnhancedStatItem(
            icon: items[i].icon,
            label: items[i].label,
            value: items[i].value,
            color: items[i].color,
          ),
        );
      },
    );
  }
}

class _StatItemData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItemData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _EnhancedStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _EnhancedStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: color.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingSkeleton extends StatefulWidget {
  @override
  _StatsLoadingSkeletonState createState() => _StatsLoadingSkeletonState();
}

class _StatsLoadingSkeletonState extends State<_StatsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Match the responsive logic from _EnhancedStatsGrid
        int columns;
        double aspectRatio;
        
        if (width < 400) {
          columns = 1;
          aspectRatio = 2.8;
        } else if (width < 600) {
          columns = 2;
          aspectRatio = 1.6;
        } else if (width < 900) {
          columns = 3;
          aspectRatio = 1.5;
        } else {
          columns = 4;
          aspectRatio = 1.4;
        }
        
        return FadeTransition(
          opacity: _animation,
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ======================= News Skeleton ======================= */

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
        height: 160,
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.3),
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
            color: AppColors.border.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}

/* ======================= Enhanced Bullet Line ======================= */

class _EnhancedBulletLine extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EnhancedBulletLine(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= Explore Chip ======================= */

class _ExploreChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ExploreChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/constants/app_strings.dart';
import 'package:vvs_app/screens/child_screens/blood_donor/screen/blood_donor_form.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/screens/family_registration_screen.dart';

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
  final PageController _pageController = PageController();

  final List<Map<String, String>> _slidesText = [
    {'title': '', 'subtitle': appTitle},
    {'title': 'Connect Share Grow', 'subtitle': ''},
    {
      'title': 'Empowering our Varshney Samaj',
      'subtitle': 'Together, we thrive.',
    },
  ];

  /// News list
  List<Map<String, String>> _slidesNews = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('timestamp', descending: true)
          .get();

      final docs = querySnapshot.docs;
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
            return {
              'title': (data['title'] ?? '').toString(),
              'content': (data['content'] ?? '').toString(),
              'imageUrl': (data['imageUrl'] ?? '').toString(),
              'timestamp': (data['timestamp'] ?? '').toString(),
            };
          }).toList();
        }
        _isLoadingNews = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNews = false;
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

  int _currentPage = 0;
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slidesText.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == i ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == i ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          AppTitle("Welcome to VVS"),
          // Slider
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slidesText.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (ctx, i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTitle(_slidesText[i]['title'] ?? ''),
                    const SizedBox(height: 6),
                    if (_slidesText[i]['subtitle']!.isNotEmpty)
                      AppSubTitle(_slidesText[i]['subtitle']!),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildPageIndicator(),
          const SizedBox(height: 24),
          AutoSlidingNewsBanner(
            slidesNews: _slidesNews,
            isLoading: _isLoadingNews,
          ),
          const SizedBox(height: 24),
          // CTA Highlight
          _buildHighlightCTA(
            title: 'Did You Register Your Family?',
            subtitle: 'Keep your family connected and searchable.',
            buttonText: 'Register Now',
            onPressed: () {
              _navigateToAddMember();
            },
          ),
          const SizedBox(height: 24),
 _buildHighlightCTA(
            title: 'Did You Register as a Blood Donor?',
            subtitle: 'Help save lives by joining our donor network.',
            buttonText: 'Become a Blood Donor',
            onPressed: () {
              _navigateToBloodDonorForm();
            },
          ),

          const SizedBox(height: 24),

          // News
          _buildCard(
            title: 'Recent Announcements',
            children: const [
              Text('• Blood Donation Camp – Aug 15, 2025'),
              Text('• Samaj Youth Meet Highlights Uploaded'),
              Text('• Scholarship Applications Open Until Sep 10'),
            ],
          ),

          const SizedBox(height: 24),

          // Highlights
          _buildCard(
            title: 'Community Highlights',
            children: const [
              Text('• Dr. Asha Varshney awarded Padma Shri'),
              Text('• Launch of VVS Matrimonial App'),
              Text('• New Health Insurance Tie-up Announced'),
            ],
          ),

          const SizedBox(height: 24),

          // Explore
          _buildCard(
            title: 'Explore More',
            children: [
              AppOutlinedButton(text: 'Matrimonial', onPressed: () {}),
              const SizedBox(height: 8),
              AppOutlinedButton(text: 'MarketPlace', onPressed: () {}),
              const SizedBox(height: 8),
              AppOutlinedButton(text: 'Offers & Discounts', onPressed: () {}),
            ],
          ),
          const SizedBox(height: 24),
          // Stats
          _buildCard(
            title: 'Quick Stats',
            children: const [
              Text('• Total Members: 1,234'),
              Text('• Registered Families: 321'),
              Text('• Blood Donors: 89'),
              Text('• Events Scheduled: 4'),
            ],
          ),
          const BottomFooter(),
        ],
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [AppLabel(title), const SizedBox(height: 12), ...children],
      ),
    );
  }

  Widget _buildHighlightCTA({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(title),
          const SizedBox(height: 6),
          AppSubTitle(subtitle),
          const SizedBox(height: 12),
          AppButton(text: buttonText, onPressed: onPressed),
        ],
      ),
    );
  }
}

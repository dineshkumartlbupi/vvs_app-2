import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/about_developer_screen.dart';
import 'package:vvs_app/screens/child_screens/blog_screen.dart';
import 'package:vvs_app/screens/child_screens/book_author/screens/books_list_screen.dart.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/screens/family_registration_screen.dart';
import 'package:vvs_app/screens/child_screens/founder_screen.dart';
import 'package:vvs_app/screens/child_screens/marketplace/screens/marketplace_screen.dart';
import 'package:vvs_app/screens/child_screens/testimonial_screen.dart';
import 'package:vvs_app/screens/child_screens/vvs_id_card_screen.dart';
import 'package:vvs_app/screens/home_screen.dart';
import 'package:vvs_app/screens/child_screens/profile/screens/profile_screen.dart.dart';
import 'package:vvs_app/screens/child_screens/news/screens/news_bulletin_screen.dart';
import 'package:vvs_app/screens/child_screens/materimonial/screens/matrimonial_screen.dart';
import 'package:vvs_app/screens/child_screens/marketplace/directory_screens/directory_screen.dart';
import 'package:vvs_app/screens/child_screens/blood_donor/screen/blood_group_screen.dart';
import 'package:vvs_app/screens/message_screen/chat_screen.dart';
import 'package:vvs_app/screens/child_screens/events_screen.dart';
import 'package:vvs_app/screens/child_screens/offers_screen.dart';
import 'package:vvs_app/screens/child_screens/payment_screen.dart';
import 'package:vvs_app/screens/child_screens/contact_us_screen.dart';
import 'package:vvs_app/screens/child_screens/about_us_screen.dart';
import 'package:vvs_app/screens/child_screens/terms_screen.dart';
import 'package:vvs_app/screens/marketplace/marketplace_all_screen.dart.dart';
import 'package:vvs_app/screens/message_screen/messages_screen.dart';
import 'package:vvs_app/utils/custom_app_bar.dart';
import 'package:vvs_app/utils/custom_bottom_nav.dart';
import 'package:vvs_app/utils/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Widget> _bottomScreens = [
    const HomeScreen(),
    NewsBulletinScreen(),
    MatrimonialScreen(),
    const MarketplaceScreen(),
    const ProfileScreen(),
  ];

  final List<String> _bottomTitles = [
    'Home',
    'News Bulletin',
    'Matrimonial',
    'Marketplace',
    'Profile',
  ];
  int _selectedIndex = 0;
  final Map<String, Widget> drawerScreenMap = {
    'About Us': const AboutUsScreen(),
    'founder': const FounderScreen(),
    'Directory Who\'s & Who': const DirectoryScreen(),
    'Books & Author': const BooksListScreen(),
    'About Developer': const AboutDeveloperScreen(),
    'Family Registration': const FamilyRegistrationScreen(),
    'Market Place': const MarketplaceAllScreen(),
    'Blood Group & Donors': const BloodDonorsScreen(),
    'Message(Chat)': const MessagesScreen(),
    'VVS ID Card': const VvsIdCardScreen(),
    'Testimonial': const TestimonialsScreen(),
    'Blog': const BlogScreen(),
    'Upcoming Events': const EventsScreen(),
    'Offers & Discounts': const OffersScreen(),
    'Payment Gateway': const PaymentScreen(),
    'Contact Us': const ContactUsScreen(),
    'Terms & Conditions': const TermsScreen(),
  };

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onDrawerTap(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _selectedIndex == 0 ? "VVS" : _bottomTitles[_selectedIndex],
      ),
      drawer: CustomDrawer(screenMap: drawerScreenMap, onTap: _onDrawerTap),
      body: _bottomScreens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  static const String developerName = "Dinesh Kumar";
  static const String role = "Mobile Apps Developer";
  static const String email = "kumar@gmail.com";
  static const String phone = "+91 98XXXXXXXX";
  static const String location = "Bengaluru, India";

  static const String bio =
      "Passionate Flutter developer with a strong focus on clean architecture, fast UIs and delightful UX. "
      "I build scalable mobile apps integrated with Firebase and REST APIs.";

  static const List<String> skills = [
    "Flutter & Dart",
    "Firebase (Auth, Firestore)",
    "REST API Integration",
    "State Management (Provider, Riverpod)",
    "UI/UX Design & Prototyping",
  ];

  static const List<String> tools = [
    "VS Code",
    "Android Studio",
    "Figma",
    "Postman",
    "Git & GitHub",
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Developer'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    developerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoPill(icon: Icons.location_on_rounded, label: location),
                      _InfoPill(icon: Icons.email_rounded, label: email),
                      _InfoPill(icon: Icons.phone_rounded, label: phone),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Section
            _buildSectionCard(
              title: 'About Me',
              icon: Icons.info_outline_rounded,
              child: Text(
                bio,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.subtitle,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Skills & Tools
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSkillsCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildToolsCard()),
                ],
              )
            else ...[
              _buildSkillsCard(),
              const SizedBox(height: 20),
              _buildToolsCard(),
            ],

            const SizedBox(height: 40),

            // Footer
            Column(
              children: [
                const Text(
                  'Made with ❤️ using Flutter',
                  style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} $developerName',
                  style: TextStyle(color: AppColors.subtitle.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return _buildSectionCard(
      title: 'Skills',
      icon: Icons.code_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildToolsCard() {
    return _buildSectionCard(
      title: 'Tools',
      icon: Icons.build_rounded,
      child: Column(
        children: tools
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success.withOpacity(0.7)),
                    const SizedBox(width: 10),
                    Text(
                      t,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.subtitle),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

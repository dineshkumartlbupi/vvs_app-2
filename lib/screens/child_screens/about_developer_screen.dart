import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart'; // For AppTitle

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  // Replace these with your real values
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Developer'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: avatar + name + role + actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.10), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar (replace AssetImage with your image or network)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: isWide ? 110 : 86,
                      height: isWide ? 110 : 86,
                      color: AppColors.primary.withOpacity(0.08),
                      child: const Icon(
                        Icons.person,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Name & role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          developerName,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role,
                          style: textTheme.bodyMedium?.copyWith(
                              color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoPill(icon: Icons.location_on_outlined, label: location),
                            _InfoPill(icon: Icons.mail_outline, label: email),
                            _InfoPill(icon: Icons.phone_outlined, label: phone),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Bio card
            Container(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTitle('About'),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                   
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Skills & Tools side-by-side on wide screens
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSkillsCard(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildToolsCard(context)),
                ],
              )
            else ...[
              _buildSkillsCard(context),
              const SizedBox(height: 12),
              _buildToolsCard(context),
            ],

            const SizedBox(height: 18),

            // Footer: small credits
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with ❤️ using Flutter',
                    style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '© ${DateTime.now().year} $developerName',
                    style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTitle('Skills'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) => Chip(
                    label: Text(s),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    elevation: 0,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTitle('Tools used'),
          const SizedBox(height: 8),
          Column(
            children: tools
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.build, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(t),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Helpers
  static void _openMail(BuildContext context, String mail) {
    final uri = Uri(
      scheme: 'mailto',
      path: mail,
    );
    // Use url_launcher in future to open externally; for now show a hint
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open mail client: ${uri.toString()} (add url_launcher to actually open)')),
    );
  }

  static void _shareText(BuildContext context, String text) {
    // If you add share_plus you can call Share.share(text)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share action triggered (add share_plus to fully enable)')),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

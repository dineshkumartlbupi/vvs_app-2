import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class DirectoryDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DirectoryDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final title = (data['title'] ?? '').toString();
    final organization = (data['organization'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final phone = (data['phone'] ?? data['mobile'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final bio = (data['bio'] ?? '').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString();
    final socials = (data['socials'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Abstract background pattern or circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person,
                                    size: 60, color: AppColors.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Actions
                  if (phone.isNotEmpty || email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          if (phone.isNotEmpty)
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.call_rounded,
                                label: 'Call',
                                color: Colors.green,
                                onTap: () => _launchUrl('tel:$phone'),
                              ),
                            ),
                          if (phone.isNotEmpty && email.isNotEmpty)
                            const SizedBox(width: 12),
                          if (email.isNotEmpty)
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.email_rounded,
                                label: 'Email',
                                color: AppColors.primary,
                                onTap: () => _launchUrl('mailto:$email'),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Info Cards
                  _buildInfoSection(
                    title: 'Professional Details',
                    icon: Icons.work_outline_rounded,
                    children: [
                      if (organization.isNotEmpty)
                        _buildInfoRow(Icons.business_rounded, 'Organization', organization),
                      if (title.isNotEmpty)
                        _buildInfoRow(Icons.badge_rounded, 'Role', title),
                      if (location.isNotEmpty)
                        _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (bio.isNotEmpty)
                    _buildInfoSection(
                      title: 'About',
                      icon: Icons.info_outline_rounded,
                      children: [
                        Text(
                          bio,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  if (socials.isNotEmpty)
                    _buildInfoSection(
                      title: 'Social Profiles',
                      icon: Icons.share_rounded,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: socials.entries.map((e) {
                            return ActionChip(
                              avatar: Icon(_getSocialIcon(e.key), size: 18),
                              label: Text(e.key),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              onPressed: () {
                                // Handle social link tap
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.subtitle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  IconData _getSocialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center_rounded;
      case 'twitter':
      case 'x':
        return Icons.alternate_email_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}

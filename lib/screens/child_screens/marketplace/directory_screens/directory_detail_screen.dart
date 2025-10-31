import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectoryDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const DirectoryDetailScreen({super.key, required this.docId, required this.data});

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
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: AppColors.primary.withOpacity(0.08),
                    child: photoUrl.isNotEmpty
                        ? Image.network(photoUrl, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 56, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        title.isNotEmpty ? title : (organization.isNotEmpty ? organization : ''),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      if (location.isNotEmpty) Text(location, style: const TextStyle(fontSize: 13, color: Colors.black45)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // contact row
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (phone.isNotEmpty)
                      _ContactButton(
                        icon: Icons.call,
                        label: phone,
                        onPressed: () {
                          // use url_launcher to actually call
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call: $phone')));
                        },
                      ),
                    if (email.isNotEmpty) const SizedBox(width: 8),
                    if (email.isNotEmpty)
                      _ContactButton(
                        icon: Icons.mail_outline,
                        label: email,
                        onPressed: () {
                          // use url_launcher mailto:
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email: $email')));
                        },
                      ),
                    const Spacer(),
                    // Edit placeholder: link to your edit screen if you have one
                    IconButton(
                      tooltip: 'Edit (if permitted)',
                      onPressed: () {
                        // Optionally navigate to an edit screen if you support editing directory entries
                      },
                      icon: const Icon(Icons.edit),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // bio / about
            if (bio.isNotEmpty) ...[
              const AppTitle('About'),
              const SizedBox(height: 8),
              Text(bio, style: const TextStyle(fontSize: 14, height: 1.6)),
              const SizedBox(height: 12),
            ],

            // socials
            if (socials.isNotEmpty) ...[
              const AppTitle('Socials'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socials.entries.map((e) {
                  return Chip(label: Text('${e.key}: ${e.value}'));
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // metadata
            const AppTitle('Details'),
            const SizedBox(height: 8),
            _metaRow('Organisation', organization),
            _metaRow('Title', title),
            _metaRow('Location', location),
            _metaRow('Phone', phone),
            _metaRow('Email', email),
            const SizedBox(height: 20),

            // share button (placeholder)
            ElevatedButton.icon(
              onPressed: () {
                final info = StringBuffer()
                  ..writeln(name)
                  ..writeln(title)
                  ..writeln(organization)
                  ..writeln(location)
                  ..writeln(phone.isNotEmpty ? 'Phone: $phone' : '')
                  ..writeln(email.isNotEmpty ? 'Email: $email' : '');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share: ${info.toString()}')));
                // replace with Share.share(info.toString()) if using share_plus
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Profile'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ContactButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

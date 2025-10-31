import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/marketplace/directory_screens/directory_detail_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () =>
          setState(() => _query = _searchController.text.toLowerCase().trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _directoryStream() {
    // Change 'directory' to your actual collection name if different
    return FirebaseFirestore.instance
        .collection('directory')
        .orderBy('name')
        .snapshots();
  }

  bool _matchesQuery(Map<String, dynamic> data) {
    if (_query.isEmpty) return true;
    final name = (data['name'] ?? '').toString().toLowerCase();
    final title = (data['title'] ?? '').toString().toLowerCase();
    final org = (data['organization'] ?? '').toString().toLowerCase();
    final location = (data['location'] ?? '').toString().toLowerCase();
    return name.contains(_query) ||
        title.contains(_query) ||
        org.contains(_query) ||
        location.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Who's & Who Directory"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppInput(
              controller: _searchController,
              label: 'Search by name, title, organisation or location',
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _directoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final raw = snapshot.data?.docs ?? [];
                if (raw.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 64,
                            color: AppColors.primary.withOpacity(0.12),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No directory entries yet.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Map to safe list preserving id
                final items = raw
                    .map((d) {
                      final map =
                          (d.data() as Map<String, dynamic>?) ??
                          <String, dynamic>{};
                      return {'id': d.id, ...map};
                    })
                    .where((m) => _matchesQuery(m as Map<String, dynamic>))
                    .toList();

                if (items.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = items[i] as Map<String, dynamic>;
                    final id = data['id'] as String? ?? '';
                    final name = (data['name'] ?? '').toString();
                    final title = (data['title'] ?? '').toString();
                    final organization = (data['organization'] ?? '')
                        .toString();
                    final location = (data['location'] ?? '').toString();
                    final photoUrl = (data['photoUrl'] ?? '').toString();

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DirectoryDetailScreen(docId: id, data: data),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : 'Unnamed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      title.isNotEmpty
                                          ? '$title • ${organization.isNotEmpty ? organization : '—'}'
                                          : (organization.isNotEmpty
                                                ? organization
                                                : ''),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (location.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        location,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

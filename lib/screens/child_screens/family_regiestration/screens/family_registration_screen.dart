import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/controller/family_controller.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/screens/FamilyRegistrationScreenForm.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class FamilyRegistrationScreen extends StatefulWidget {
  const FamilyRegistrationScreen({super.key});

  @override
  State<FamilyRegistrationScreen> createState() =>
      _FamilyRegistrationScreenState();
}

class _FamilyRegistrationScreenState extends State<FamilyRegistrationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    // listen for search
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.toLowerCase().trim(),
      );
    });

    // get current user uid (if signed in)
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddMember({Map<String, dynamic>? existing, String? docId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FamilyRegistrationScreenForm(existingData: existing, docId: docId),
      ),
    );
  }

  Future<void> _deleteMember(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete member'),
        content: const Text(
          'Are you sure you want to delete this member? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Prefer controller delete if available
      // await FamilyController.deleteMember(docId);

      // Fallback:
      await FirebaseFirestore.instance
          .collection('family_members')
          .doc(docId)
          .delete();
      messenger.showSnackBar(const SnackBar(content: Text('Member deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _buildEmptyState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: AppColors.primary.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'No family members found.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddMember(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helper to build detailed rows inside expanded tile
  Widget _detailRow(IconData icon, String label, {String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value != null && value.isNotEmpty ? value : label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Family Directory'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Family Member',
            onPressed: () => _navigateToAddMember(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppInput(
              controller: _searchController,
              label: 'Search by name, relation, age or gender',
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),

          // List - shows only documents where createdBy == _currentUid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FamilyController.getFamilyMembersStream(),
              builder: (context, snapshot) {
                // loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final rawDocs = snapshot.data?.docs ?? [];
                if (rawDocs.isEmpty) {
                  return _buildEmptyState(
                    'No family members yet. Add one using the button below.',
                  );
                }

                // Map to safe structures (preserve docId)
                final docs = rawDocs.map((d) {
                  final m =
                      (d.data() as Map<String, dynamic>?) ??
                      <String, dynamic>{};
                  return {'id': d.id, ...m};
                }).toList();

                // Filter to current user's items
                final owned = docs.where((data) {
                  if (_currentUid == null) return false;
                  final createdBy = (data['createdBy'] ?? '').toString();
                  return createdBy == _currentUid;
                }).toList();

                if (owned.isEmpty) {
                  return _buildEmptyState(
                    'You have not added any members yet.',
                  );
                }

                // Further apply search filter
                final filtered = owned.where((data) {
                  if (_searchQuery.isEmpty) return true;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final rel = (data['relation'] ?? '').toString().toLowerCase();
                  final age = (data['age'] ?? '').toString().toLowerCase();
                  final gender = (data['gender'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery) ||
                      rel.contains(_searchQuery) ||
                      age.contains(_searchQuery) ||
                      gender.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState('No matching members found.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    final docId = data['id'] as String? ?? '';
                    final name = (data['name'] ?? '').toString();
                    final relation = (data['relation'] ?? '').toString();
                    final age = (data['age'] ?? '').toString();
                    final gender = (data['gender'] ?? '').toString();
                    final photoUrl = (data['photoUrl'] ?? '').toString();
                    final phone = (data['phone'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    final address = (data['address'] ?? '').toString();
                    final notes = (data['notes'] ?? '').toString();
                    final createdAt = data['createdAt']; // could be Timestamp

                    final createdAtStr = createdAt is Timestamp
                        ? (createdAt).toDate().toString()
                        : (createdAt?.toString() ?? '');

                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header row (same as ExpansionTile header)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.isNotEmpty ? name : 'Unnamed',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${relation.isNotEmpty ? relation : 'Relation N/A'} • Age: ${age.isNotEmpty ? age : 'NA'} • ${gender.isNotEmpty ? gender : 'NA'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1),

                            // Always-visible details
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (phone.isNotEmpty)
                                    _detailRow(
                                      Icons.phone,
                                      'Phone',
                                      value: phone,
                                    ),
                                  if (email.isNotEmpty)
                                    _detailRow(
                                      Icons.mail_outline,
                                      'Email',
                                      value: email,
                                    ),
                                  if (address.isNotEmpty)
                                    _detailRow(
                                      Icons.location_on_outlined,
                                      'Address',
                                      value: address,
                                    ),
                                  if (notes.isNotEmpty)
                                    _detailRow(
                                      Icons.notes,
                                      'Notes',
                                      value: notes,
                                    ),
                                  if (createdAtStr.isNotEmpty)
                                    _detailRow(
                                      Icons.calendar_today,
                                      'Added on',
                                      value: createdAtStr,
                                    ),

                                  // optional small action row (call, map, share)
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Spacer(),
                                      if (address.isNotEmpty)
                                        GestureDetector(
                                          onTap: () => _navigateToAddMember(
                                            existing: Map<String, dynamic>.from(
                                              data,
                                            ),
                                            docId: docId,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(16),
                                              ),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 16,color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Edit',style: TextStyle(color: Colors.blue),),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () => _deleteMember(docId),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(16),
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                1.0,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 16,color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete',style: TextStyle(color: Colors.red),),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

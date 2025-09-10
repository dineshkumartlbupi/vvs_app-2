import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddMember() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyRegistrationScreenForm()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Family Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Family Member',
            onPressed: _navigateToAddMember,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppInput(
              controller: _searchController,
              label: 'Search by name or relation',
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FamilyController.getFamilyMembersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  final rel = (doc['relation'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      rel.contains(_searchQuery);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No matching members found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i];
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['relation'] ?? ''} • Age: ${data['age'] ?? 'NA'} • ${data['gender'] ?? 'NA'}',
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 180, right: 16),
        child: ElevatedButton.icon(
          onPressed: _navigateToAddMember,
          icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
          label: const Text(
            'Add Family Member',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

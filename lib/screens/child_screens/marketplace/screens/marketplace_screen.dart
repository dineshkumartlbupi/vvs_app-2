import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/screens/marketplace/add_organization_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

const String kOrganizationsCollection = 'marketplaces';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceAllScreenState();
}

class _MarketplaceAllScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _categoryFilter = '';
  String _subcategoryFilter = '';
  String _sortBy = 'recent'; // recent | nameAsc
  bool _isAdmin = false;
  late final TabController _tabController;
  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  final Map<String, List<String>> _catMap = {
    'Healthcare': ['Hospital', 'Clinic', 'Pharmacy', 'Diagnostic'],
    'Education': ['College', 'Coaching Center', 'Tuition'],
    'Retail': ['Grocery', 'Clothing', 'Electronics', 'Furniture'],
    'Food & Dining': ['Restaurant', 'Cafe', 'Bakery'],
    'Services': ['Salon', 'Plumber', 'Electrician', 'Tailor'],
    'Other': ['Other'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _search = _searchCtrl.text.trim().toLowerCase()),
    );
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snap.data();
    if (mounted) {
      setState(() => _isAdmin = data != null && data['role'] == 'admin');
    }
  }

  Query _orgsQuery({required bool onlyMine}) {
    Query q = FirebaseFirestore.instance.collection(kOrganizationsCollection);
    if (onlyMine) {
      final uid = _currentUid;
      q = q.where('createdBy', isEqualTo: uid);
    }
    if (_categoryFilter.isNotEmpty) {
      q = q.where('category', isEqualTo: _categoryFilter);
    }
    if (_subcategoryFilter.isNotEmpty) {
      q = q.where('subcategory', isEqualTo: _subcategoryFilter);
    }

    if (_sortBy == 'nameAsc') {
      q = q.orderBy('name');
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    return q;
  }

  bool _matchesSearch(Map<String, dynamic> d) {
    if (_search.isEmpty) return true;
    final name = (d['name'] ?? '').toString().toLowerCase();
    final cat = (d['category'] ?? '').toString().toLowerCase();
    final sub = (d['subcategory'] ?? '').toString().toLowerCase();
    final desc = (d['description'] ?? '').toString().toLowerCase();
    final phone = (d['phone'] ?? '').toString().toLowerCase();
    return name.contains(_search) ||
        cat.contains(_search) ||
        sub.contains(_search) ||
        desc.contains(_search) ||
        phone.contains(_search);
  }

  Future<void> _openFilters() async {
    var tmpCat = _categoryFilter;
    var tmpSub = _subcategoryFilter;
    var tmpSort = _sortBy;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModal(() {
                            tmpCat = '';
                            tmpSub = '';
                            tmpSort = 'recent';
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: tmpCat.isEmpty ? null : tmpCat,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: ['', 'Healthcare', 'Education', 'Retail', 'Food & Dining', 'Services', 'Other']
                        .where((e) => e != null)
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.isEmpty ? 'Any' : c)))
                        .toList(),
                    onChanged: (v) => setModal(() {
                      tmpCat = v ?? '';
                      tmpSub = '';
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tmpSub.isEmpty ? null : tmpSub,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: (tmpCat.isEmpty ? <String>[] : (_catMap[tmpCat] ?? []))
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModal(() => tmpSub = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tmpSort,
                    items: const [
                      DropdownMenuItem(value: 'recent', child: Text('Most recent')),
                      DropdownMenuItem(value: 'nameAsc', child: Text('Name A → Z')),
                    ],
                    onChanged: (v) => setModal(() => tmpSort = v ?? 'recent'),
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(ctx2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'Apply Filters',
                          onPressed: () {
                            setState(() {
                              _categoryFilter = tmpCat;
                              _subcategoryFilter = tmpSub;
                              _sortBy = tmpSort;
                            });
                            Navigator.pop(ctx2);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDoc(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(kOrganizationsCollection)
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _imgFallback() => const Center(
        child: Icon(Icons.storefront_rounded, color: AppColors.subtitle, size: 40),
      );

  void _showDetailSheet(BuildContext ctx, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final name = (data['name'] ?? '').toString();
        final desc = (data['description'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final address = (data['address'] ?? '').toString();
        final imageUrl = (data['imageUrl'] ?? '').toString();
        final createdBy = (data['createdBy'] ?? '').toString();

        final bool isOwner = createdBy.isNotEmpty && createdBy == _currentUid;
        final bool canManage = _isAdmin || isOwner;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[100],
                              child: _imgFallback(),
                            ),
                          )
                        : Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: _imgFallback(),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 16, color: AppColors.subtitle, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (address.isNotEmpty) ...[
                    _buildDetailRow(Icons.location_on_rounded, address),
                    const SizedBox(height: 16),
                  ],
                  if (phone.isNotEmpty) ...[
                    _buildDetailRow(Icons.phone_rounded, phone),
                    const SizedBox(height: 24),
                  ],
                  if (canManage)
                    Row(
                      children: [
                        Expanded(
                          child: AppOutlinedButton(
                            text: 'Edit',
                            leadingIcon: Icons.edit_rounded,
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddOrganizationScreen(
                                    existingData: data,
                                    docId: docId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            text: 'Delete',
                            leadingIcon: Icons.delete_rounded,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Organization'),
                                  content: const Text('Are you sure you want to delete this organization?'),
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
                              if (confirm == true) {
                                Navigator.pop(ctx);
                                await _deleteDoc(docId);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: AppColors.text),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Listings'),
            Tab(text: 'My Listings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppInput(
              controller: _searchCtrl,
              label: 'Search marketplace...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(onlyMine: false),
                _buildList(onlyMine: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Listing'),
      ),
    );
  }

  Widget _buildList({required bool onlyMine}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _orgsQuery(onlyMine: onlyMine).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return _matchesSearch(data);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 64, color: AppColors.subtitle.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No listings found',
                  style: TextStyle(fontSize: 16, color: AppColors.subtitle),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) => _orgCard(filtered[i]),
        );
      },
    );
  }

  Widget _orgCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = (data['name'] ?? 'Unnamed').toString();
    final cat = (data['category'] ?? '').toString();
    final sub = (data['subcategory'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final desc = (data['description'] ?? '').toString();

    return GestureDetector(
      onTap: () => _showDetailSheet(context, doc.id, data),
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[100],
                        child: _imgFallback(),
                      ),
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: _imgFallback(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cat,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.subtitle),
                  ),
                  const SizedBox(height: 12),
                  if (sub.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.tag_rounded, size: 14, color: AppColors.subtitle.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          sub,
                          style: TextStyle(fontSize: 12, color: AppColors.subtitle.withOpacity(0.6)),
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
  }
}

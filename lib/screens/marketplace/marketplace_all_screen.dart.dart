import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/screens/marketplace/add_organization_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/theme/app_theme.dart';

const String kOrganizationsCollection = 'marketplaces';

class MarketplaceAllScreen extends StatefulWidget {
  const MarketplaceAllScreen({super.key});
  @override
  State<MarketplaceAllScreen> createState() => _MarketplaceAllScreenState();
}

class _MarketplaceAllScreenState extends State<MarketplaceAllScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _categoryFilter = '';
  String _subcategoryFilter = '';
  String _sortBy = 'recent'; // recent | nameAsc
  bool _isAdmin = false;
  late final TabController _tabController;
  final bool _isGrid = false;
  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Local category->subcategory map (can move to controller/Firestore)
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModal) {
            final subitems = tmpCat.isEmpty
                ? <String>[]
                : (_catMap[tmpCat] ?? <String>[]);
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setModal(() {
                            tmpCat = '';
                            tmpSub = '';
                            tmpSort = 'recent';
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Reset',
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: tmpCat.isEmpty ? null : tmpCat,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              '',
                              'Healthcare',
                              'Education',
                              'Retail',
                              'Food & Dining',
                              'Services',
                              'Other',
                            ]
                            .where((e) => e != null)
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.isEmpty ? 'Any' : c),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setModal(() {
                      tmpCat = v ?? '';
                      tmpSub = '';
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Subcategory dropdown (dynamic)
                  DropdownButtonFormField<String>(
                    value: tmpSub.isEmpty ? null : tmpSub,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        (tmpCat.isEmpty ? <String>[] : (_catMap[tmpCat] ?? []))
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setModal(() => tmpSub = v ?? ''),
                  ),
                  const SizedBox(height: 12),

                  // Sort
                  DropdownButtonFormField<String>(
                    value: tmpSort,
                    items: const [
                      DropdownMenuItem(
                        value: 'recent',
                        child: Text('Most recent'),
                      ),
                      DropdownMenuItem(
                        value: 'nameAsc',
                        child: Text('Name A → Z'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => tmpSort = v ?? 'recent'),
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _categoryFilter = '';
                              _subcategoryFilter = '';
                              _sortBy = 'recent';
                            });
                            Navigator.pop(ctx2);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _categoryFilter = tmpCat;
                              _subcategoryFilter = tmpSub;
                              _sortBy = tmpSort;
                            });
                            Navigator.pop(ctx2);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Widget _imgFallback() => const Center(
    child: Icon(Icons.storefront_outlined, color: Colors.white54),
  );

  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
      }
    }
  }

  Future<void> _launchWebsite(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No website provided')));
      }
      return;
    }
    var uri = Uri.tryParse(url) ?? Uri();
    if (!uri.hasScheme) uri = Uri.parse('https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot open website')));
      }
    }
  }

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No address available')));
      }
      return;
    }
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot open maps')));
      }
    }
  }

  void _showDetailSheet(
    BuildContext ctx,
    String docId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final name = (data['name'] ?? '').toString();
        final category = (data['category'] ?? '').toString();
        final subcategory = (data['subcategory'] ?? '').toString();
        final desc = (data['description'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final website = (data['website'] ?? '').toString();
        final address = (data['address'] ?? '').toString();
        final imageUrl = (data['imageUrl'] ?? '').toString();
        final createdBy = (data['createdBy'] ?? '').toString();

        final bool isOwner = createdBy.isNotEmpty && createdBy == _currentUid;
        final bool canManage = _isAdmin || isOwner;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.white10,
                          child: _imgFallback(),
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    desc,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                if (address.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(children: [Expanded(child: Text(phone))]),

                if (canManage) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
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
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete'),
                                content: const Text(
                                  'Do you want to delete this organisation?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              Navigator.pop(ctx);
                              await _deleteDoc(docId);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orgCardList(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String name = (data['name'] ?? 'Unnamed').toString();
    final String category = (data['category'] ?? '').toString();
    final String sub = (data['subcategory'] ?? '').toString();
    final String description = (data['description'] ?? '').toString();
    final String phone = (data['phone'] ?? '').toString();
    final String imageUrl = (data['imageUrl'] ?? '').toString();
    final String createdBy = (data['createdBy'] ?? '').toString();

    final bool isOwner = createdBy.isNotEmpty && createdBy == _currentUid;
    final bool canManage = _isAdmin || isOwner;

    return GestureDetector(
      onTap: () => _showDetailSheet(context, doc.id, data),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1,
            color: AppColors.primary.withOpacity(0.3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(),
                    )
                  : Container(
                      width: 92,
                      height: 92,
                      color: Colors.grey[100],
                      child: _imgFallback(),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$category${sub.isNotEmpty ? ' • $sub' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      if (canManage)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddOrganizationScreen(
                                      existingData: data,
                                      docId: doc.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    width: 1,
                                    color: AppTheme.light.primaryColor
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  "Edit",
                                  style: TextStyle(
                                    color: AppTheme.light.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete'),
                                    content: const Text(
                                      'Delete this organisation?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) await _deleteDoc(doc.id);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.red.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _orgCardGrid(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = (data['name'] ?? 'Unnamed').toString();
    final cat = (data['category'] ?? '').toString();
    final sub = (data['subcategory'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();

    return GestureDetector(
      onTap: () => _showDetailSheet(context, doc.id, data),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback(),
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey[100],
                      child: _imgFallback(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$cat${sub.isNotEmpty ? ' • $sub' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabStream({required bool onlyMine}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _orgsQuery(onlyMine: onlyMine).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs
            .where((d) => _matchesSearch(d.data() as Map<String, dynamic>))
            .toList();
        if (docs.isEmpty) {
          return const Center(child: Text('No organisations found'));
        }

        // show chips for active filters above list
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              children: [
                Expanded(
                  child: _isGrid
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.82,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: docs.length,
                          itemBuilder: (context, i) => _orgCardGrid(docs[i]),
                        )
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) => _orgCardList(docs[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _catMap.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        // Restore normal toolbar height so leading/back button is visible
        toolbarHeight: kToolbarHeight,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              )
            : null,
        title: const Text('Marketplace'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white, // active tab text color
          unselectedLabelColor: Colors.white70, // inactive tab text color
          tabs: const [
            Tab(text: 'All MarketPlace'),
            Tab(text: 'My MarketPlace'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),

      body: Column(
        children: [
          // Search & quick filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Material(
              color: Colors.white,
              shadowColor: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(Icons.search_rounded, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(
                                () => _search = v.trim().toLowerCase(),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search name or category',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _search = '';
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Divider
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      width: 1,
                      color: Colors.black12,
                      thickness: 1,
                    ),
                  ),

                  // view toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // category quick chips
          // category quick chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // "All Marketplace"
                GestureDetector(
                  onTap: () => setState(() {
                    _categoryFilter = '';
                    _subcategoryFilter = '';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryFilter.isEmpty
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _categoryFilter.isEmpty
                            ? AppColors.primary
                            : Colors.grey.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'All MarketPlace',
                      style: TextStyle(
                        color: _categoryFilter.isEmpty
                            ? AppColors.primary
                            : Colors.black,
                        fontWeight: _categoryFilter.isEmpty
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Main categories
                ...categories.map((c) {
                  final selected = _categoryFilter == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _categoryFilter = '';
                          _subcategoryFilter = '';
                        } else {
                          _categoryFilter = c;
                          _subcategoryFilter = '';
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: selected ? AppColors.primary : Colors.black,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Subcategories
                if (_categoryFilter.isNotEmpty &&
                    (_catMap[_categoryFilter] ?? []).isNotEmpty)
                  const SizedBox(width: 8),

                if (_categoryFilter.isNotEmpty)
                  ...(_catMap[_categoryFilter] ?? []).map((s) {
                    final sel = _subcategoryFilter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _subcategoryFilter = sel ? '' : s;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : Colors.grey.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: sel ? AppColors.primary : Colors.black,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabStream(onlyMine: false),
                _buildTabStream(onlyMine: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_business, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
        ),
      ),
    );
  }
}

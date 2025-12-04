import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/screens/message_screen/chat_screen.dart';
import 'package:vvs_app/services/chat_service.dart';

import 'package:vvs_app/theme/app_colors.dart';
import 'profile_detail_screen.dart';

class MatrimonialScreen extends StatefulWidget {
  const MatrimonialScreen({super.key});

  @override
  State<MatrimonialScreen> createState() => _MatrimonialScreenState();
}

class _MatrimonialScreenState extends State<MatrimonialScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();

  String _search = '';
  String _gender = '';
  String _location = '';
  RangeValues _ageRange = const RangeValues(18, 60);
  String _sortBy = 'recent';

  final _searchFocus = FocusNode();
  int _activeFiltersCount = 0;

  Timer? _debounce;
  late AnimationController _animationController;

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = v.trim());
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _searchCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  static const RangeValues _kDefaultAge = RangeValues(18, 60);
  final List<String> _genderOptions = const ['Male', 'Female', 'Other'];

  int _computeActiveFiltersCount() {
    int n = 0;
    if (_gender.isNotEmpty) n++;
    if (_location.trim().isNotEmpty) n++;
    if (_ageRange.start > _kDefaultAge.start ||
        _ageRange.end < _kDefaultAge.end) {
      n++;
    }
    if (_sortBy != 'recent') n++;
    return n;
  }

  int? _ageOf(dynamic dob) {
    DateTime? d;
    if (dob is Timestamp) {
      d = dob.toDate();
    } else if (dob is DateTime) {
      d = dob;
    } else if (dob is String) {
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('MM/dd/yyyy'),
      ];
      for (final f in formats) {
        try {
          d = f.parseStrict(dob);
          break;
        } catch (_) {}
      }
    }
    if (d == null) return null;

    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  bool _isMatrimonialEligible(Map<String, dynamic> u) {
    final boolFlag = (u['isMatrimonial'] ?? u['matrimonialEnabled']) == true;
    final status = (u['maritalStatus'] ?? '').toString().toLowerCase();
    return boolFlag || status == 'single';
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = _search.trim().toLowerCase();
    final g = _gender.trim().toLowerCase();
    final loc = _location.trim().toLowerCase();
    final minAge = _ageRange.start.floor();
    final maxAge = _ageRange.end.floor();

    final out = <Map<String, dynamic>>[];

    for (final d in docs) {
      final data = d.data();
      if (!_isMatrimonialEligible(data)) continue;

      final name = (data['name'] ?? '').toString();
      final lowerName = name.toLowerCase();
      final profession = (data['profession'] ?? '').toString().toLowerCase();
      final education = (data['education'] ?? '').toString().toLowerCase();
      final address = (data['address'] ?? '').toString().toLowerCase();

      if (q.isNotEmpty &&
          !(lowerName.contains(q) ||
              profession.contains(q) ||
              education.contains(q) ||
              address.contains(q))) {
        continue;
      }

      final ugender = (data['gender'] ?? '').toString().toLowerCase();
      if (g.isNotEmpty && ugender != g) continue;

      if (loc.isNotEmpty && !address.contains(loc)) continue;

      final age = _ageOf(data['dob']);
      if (age != null && (age < minAge || age > maxAge)) continue;

      out.add({
        ...data,
        '_id': d.id,
      });
    }

    out.sort((a, b) {
      switch (_sortBy) {
        case 'ageAsc':
          final aa = _ageOf(a['dob']) ?? 999;
          final bb = _ageOf(b['dob']) ?? 999;
          return aa.compareTo(bb);
        case 'ageDesc':
          final aa2 = _ageOf(a['dob']) ?? -1;
          final bb2 = _ageOf(b['dob']) ?? -1;
          return bb2.compareTo(aa2);
        case 'recent':
        default:
          final ta = a['createdAt'];
          final tb = b['createdAt'];
          final da = ta is Timestamp ? ta.toDate() : DateTime(1970);
          final db = tb is Timestamp ? tb.toDate() : DateTime(1970);
          return db.compareTo(da);
      }
    });

    return out;
  }

  void _openFilters() {
    HapticFeedback.mediumImpact();
    var tmpGender = _gender;
    var tmpLoc = _location;
    var tmpAge = RangeValues(_ageRange.start, _ageRange.end);
    var tmpSort = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grab handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setModal(() {
                              tmpGender = '';
                              tmpLoc = '';
                              tmpAge = _kDefaultAge;
                              tmpSort = 'recent';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gender
                            const _EnhancedSectionTitle(
                              icon: Icons.wc_rounded,
                              title: 'Gender',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _genderOptions.map((g) {
                                final selected = tmpGender == g;
                                return _EnhancedChoiceChip(
                                  label: g,
                                  selected: selected,
                                  onSelected: () {
                                    HapticFeedback.selectionClick();
                                    setModal(() => tmpGender = selected ? '' : g);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // Location
                            const _EnhancedSectionTitle(
                              icon: Icons.location_on_rounded,
                              title: 'Location',
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.3),
                                ),
                              ),
                              child: TextFormField(
                                initialValue: tmpLoc,
                                onChanged: (v) => setModal(() => tmpLoc = v),
                                decoration: InputDecoration(
                                  hintText: 'Enter city or area',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.subtitle,
                                  ),
                                  suffixIcon: tmpLoc.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            setModal(() => tmpLoc = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Age range
                            const _EnhancedSectionTitle(
                              icon: Icons.cake_rounded,
                              title: 'Age Range',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _AgeBubble(value: tmpAge.start.round()),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.subtitle,
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                _AgeBubble(value: tmpAge.end.round()),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setModal(() => tmpAge = _kDefaultAge);
                                  },
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                rangeThumbShape: const RoundRangeSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20,
                                ),
                              ),
                              child: RangeSlider(
                                min: _kDefaultAge.start,
                                max: _kDefaultAge.end,
                                divisions: (_kDefaultAge.end - _kDefaultAge.start).toInt(),
                                values: tmpAge,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.primary.withOpacity(0.2),
                                onChanged: (v) => setModal(() => tmpAge = v),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Sort
                            const _EnhancedSectionTitle(
                              icon: Icons.sort_rounded,
                              title: 'Sort By',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: const [
                                ('recent', Icons.schedule_rounded, 'Most Recent'),
                                ('ageAsc', Icons.arrow_upward_rounded, 'Age: Low → High'),
                                ('ageDesc', Icons.arrow_downward_rounded, 'Age: High → Low'),
                              ].map((t) {
                                final value = t.$1;
                                final icon = t.$2;
                                final label = t.$3;
                                final selected = tmpSort == value;
                                return _EnhancedChoiceChip(
                                  label: label,
                                  icon: icon,
                                  selected: selected,
                                  onSelected: () {
                                    HapticFeedback.selectionClick();
                                    setModal(() => tmpSort = value);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setModal(() {
                                tmpGender = '';
                                tmpLoc = '';
                                tmpAge = _kDefaultAge;
                                tmpSort = 'recent';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: BorderSide(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                              foregroundColor: AppColors.text,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _gender = tmpGender;
                                _location = tmpLoc;
                                _ageRange = tmpAge;
                                _sortBy = tmpSort;
                                _activeFiltersCount = _computeActiveFiltersCount();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersQuery = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Enhanced Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.card,
                  AppColors.card.withOpacity(0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocus.hasFocus
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.border.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: _searchFocus.hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search profiles...',
                        hintStyle: TextStyle(
                          color: AppColors.subtitle.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _searchFocus.hasFocus
                              ? AppColors.primary
                              : AppColors.subtitle,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _searchCtrl.clear();
                                  _onSearchChanged('');
                                },
                                color: AppColors.subtitle,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    height: 32,
                    width: 1,
                    color: AppColors.border.withOpacity(0.3),
                  ),

                  // Filter button with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune_rounded),
                        color: AppColors.primary,
                        tooltip: 'Filters',
                      ),
                      if (_activeFiltersCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$_activeFiltersCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Active filters
          if (_activeFiltersCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_gender.isNotEmpty) _filterChip(_gender, Icons.wc_rounded),
                    if (_location.isNotEmpty)
                      _filterChip(_location, Icons.location_on_rounded),
                    if (_ageRange.start > _kDefaultAge.start ||
                        _ageRange.end < _kDefaultAge.end)
                      _filterChip(
                        '${_ageRange.start.round()}-${_ageRange.end.round()} yrs',
                        Icons.cake_rounded,
                      ),
                    if (_sortBy != 'recent')
                      _filterChip(
                        _sortBy == 'ageAsc' ? 'Age ↑' : 'Age ↓',
                        Icons.sort_rounded,
                      ),
                  ],
                ),
              ),
            ),

          // Profiles list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersQuery.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final list = _filterAndSort(snap.data!.docs);

                if (list.isEmpty) {
                  return _buildNoMatchesState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    // Data is already streaming, just provide feedback
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return _EnhancedProfileCard(
                        userData: u,
                        index: i,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileDetailScreen(userData: u),
                            ),
                          );
                        },
                        ageOf: _ageOf,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const _ProfileCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Profiles Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new profiles',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Matches Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your filters or search query',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.subtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _searchCtrl.clear();
                _search = '';
                _gender = '';
                _location = '';
                _ageRange = _kDefaultAge;
                _sortBy = 'recent';
                _activeFiltersCount = 0;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear All Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }
}

/* ==================== Enhanced Profile Card ==================== */

class _EnhancedProfileCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int index;
  final VoidCallback onTap;
  final int? Function(dynamic) ageOf;

  const _EnhancedProfileCard({
    required this.userData,
    required this.index,
    required this.onTap,
    required this.ageOf,
  });

  @override
  State<_EnhancedProfileCard> createState() => _EnhancedProfileCardState();
}

class _EnhancedProfileCardState extends State<_EnhancedProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.userData;
    final name = _cap(u['name']?.toString());
    final profession = _cap(u['profession']?.toString());
    final education = _cap(u['education']?.toString());
    final address = _cap(u['address']?.toString());
    final photo = (u['photoUrl'] ?? '').toString();
    final age = widget.ageOf(u['dob']);
    final phone = (u['mobile'] ?? u['phone'] ?? '').toString().trim();
    final uid = (u['_id'] ?? '').toString();
    final gender = (u['gender'] ?? '').toString();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Enhanced Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.accent.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.background,
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Icon(
                                gender.toLowerCase() == 'female'
                                    ? Icons.person_rounded
                                    : Icons.person_outline_rounded,
                                color: AppColors.primary,
                                size: 36,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Age
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              if (age != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$age yrs',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Profession & Education
                          if (profession.isNotEmpty || education.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.work_outline_rounded,
                                  size: 14,
                                  color: AppColors.subtitle,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    [profession, education]
                                        .where((e) => e.isNotEmpty)
                                        .join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 4),

                          // Address
                          if (address.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.subtitle,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 12),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Call button
                              if (phone.isNotEmpty)
                                _ActionButton(
                                  icon: Icons.call_rounded,
                                  label: 'Call',
                                  color: Colors.green,
                                  onTap: () async {
                                    HapticFeedback.mediumImpact();
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),

                              const SizedBox(width: 10),

                              // Chat button
                              _ActionButton(
                                icon: Icons.chat_bubble_rounded,
                                label: 'Chat',
                                color: AppColors.primary,
                                onTap: () async {
                                  HapticFeedback.mediumImpact();
                                  await ChatService.ensureConversation(
                                    peerId: uid,
                                    peerName: name,
                                    peerPhoto: photo,
                                    initialMessage: '',
                                  );

                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          peerId: uid,
                                          peerName: name,
                                          peerPhoto: photo,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ==================== Action Button ==================== */

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
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==================== Loading Skeleton ==================== */

class _ProfileCardSkeleton extends StatefulWidget {
  const _ProfileCardSkeleton();

  @override
  State<_ProfileCardSkeleton> createState() => _ProfileCardSkeletonState();
}

class _ProfileCardSkeletonState extends State<_ProfileCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _bar(width: 150, height: 12),
                  const SizedBox(height: 6),
                  _bar(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/* ==================== Filter Widgets ==================== */

class _EnhancedSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _EnhancedSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _EnhancedChoiceChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelected;

  const _EnhancedChoiceChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withOpacity(0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.primary : AppColors.subtitle,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeBubble extends StatelessWidget {
  final int value;
  const _AgeBubble({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        '$value yrs',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 14,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:vvs_app/theme/app_colors.dart';
import 'profile_detail_screen.dart';

class MatrimonialScreen extends StatefulWidget {
  const MatrimonialScreen({super.key});

  @override
  State<MatrimonialScreen> createState() => _MatrimonialScreenState();
}

class _MatrimonialScreenState extends State<MatrimonialScreen> {
  final _searchCtrl = TextEditingController();

  String _search = '';
  String _gender = ''; // '', 'Male', 'Female', 'Other'
  String _location = '';
  RangeValues _ageRange = const RangeValues(18, 60);
  String _sortBy = 'recent'; // 'recent', 'ageAsc', 'ageDesc'

  final _searchFocus = FocusNode();

  // how many filters are applied — update this from your filter sheet
  int _activeFiltersCount = 0;

  // (Optional) debounce typing so you don’t refilter on every keystroke
  Timer? _debounce;
  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = v.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  // Defaults + options
  static const RangeValues _kDefaultAge = RangeValues(18, 60);
  final List<String> _genderOptions = const ['Male', 'Female', 'Other'];

  // Optional: show quick location suggestions under the field
  final List<String> _recentLocations = <String>[
    // Fill from user’s last selections or popular cities
    // 'Agra', 'Aligarh', 'Delhi'
  ];

  // Badge count for the top search bar

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

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
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
    // Respect explicit flag if present, otherwise default to singles
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
        '_id': d.id, // keep id for chat routing if needed
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
    var tmpGender = _gender;
    var tmpLoc = _location;
    var tmpAge = RangeValues(_ageRange.start, _ageRange.end);
    var tmpSort = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          return SafeArea(
            top: false,
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
                  // Grab handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Header row
                  Row(
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setModal(() {
                            tmpGender = '';
                            tmpLoc = '';
                            tmpAge = _kDefaultAge;
                            tmpSort = 'recent';
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gender
                          const _SectionTitle(
                            icon: Icons.wc_rounded,
                            title: 'Gender',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genderOptions.map((g) {
                              final selected = tmpGender == g;
                              return ChoiceChip(
                                label: Text(g),
                                selected: selected,
                                onSelected: (_) => setModal(
                                  () => tmpGender = selected ? '' : g,
                                ),
                                selectedColor: AppColors.primary.withOpacity(
                                  0.12,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor: Colors.white12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Location
                          const _SectionTitle(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                          ),
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.white,
                            elevation: 1.5,
                            shadowColor: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            child: TextFormField(
                              initialValue: tmpLoc,
                              onChanged: (v) => setModal(() => tmpLoc = v),
                              decoration: InputDecoration(
                                hintText: 'City / Area',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: (tmpLoc.isNotEmpty)
                                    ? IconButton(
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () =>
                                            setModal(() => tmpLoc = ''),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (_recentLocations.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _recentLocations.map((loc) {
                                return ActionChip(
                                  label: Text(loc),
                                  onPressed: () => setModal(() => tmpLoc = loc),
                                  backgroundColor: Colors.white10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Age range
                          const _SectionTitle(
                            icon: Icons.cake_outlined,
                            title: 'Age range',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _AgeBubble(value: tmpAge.start.round()),
                              const SizedBox(width: 8),
                              const Text(
                                'to',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 8),
                              _AgeBubble(value: tmpAge.end.round()),
                              const Spacer(),
                              TextButton(
                                onPressed: () =>
                                    setModal(() => tmpAge = _kDefaultAge),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              rangeThumbShape: const RoundRangeSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: RangeSlider(
                              min: _kDefaultAge.start,
                              max: _kDefaultAge.end,
                              divisions: (_kDefaultAge.end - _kDefaultAge.start)
                                  .toInt(),
                              values: tmpAge,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setModal(() => tmpAge = v),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sort
                          const _SectionTitle(
                            icon: Icons.sort_rounded,
                            title: 'Sort by',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                const [
                                  (
                                    'recent',
                                    Icons.schedule_rounded,
                                    'Most recent',
                                  ),
                                  (
                                    'ageAsc',
                                    Icons.arrow_upward_rounded,
                                    'Age: Low → High',
                                  ),
                                  (
                                    'ageDesc',
                                    Icons.arrow_downward_rounded,
                                    'Age: High → Low',
                                  ),
                                ].map((t) {
                                  final value = t.$1;
                                  final icon = t.$2;
                                  final label = t.$3;
                                  final selected = tmpSort == value;
                                  return ChoiceChip(
                                    avatar: Icon(
                                      icon,
                                      size: 16,
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.white70,
                                    ),
                                    label: Text(label),
                                    selected: selected,
                                    onSelected: (_) => setModal(
                                      () =>
                                          tmpSort = selected ? 'recent' : value,
                                    ),
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.12),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    backgroundColor: Colors.white12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModal(() {
                            tmpGender = '';
                            tmpLoc = '';
                            tmpAge = _kDefaultAge;
                            tmpSort = 'recent';
                          }),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _gender = tmpGender;
                              _location = tmpLoc;
                              _ageRange = tmpAge;
                              _sortBy = tmpSort;
                              _activeFiltersCount =
                                  _computeActiveFiltersCount();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openConnectSheet(Map<String, dynamic> user) {
    final phone = (user['mobile'] ?? user['phone'] ?? '').toString().trim();
    final name = _cap(user['name']?.toString());
    final uid = (user['_id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with $name',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.call_rounded),
              title: const Text('Call'),
              onTap: phone.isEmpty
                  ? null
                  : () async {
                      final uri = Uri.parse('tel:$phone');
                      await launchUrl(uri);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.calculate, color: Colors.green),
              title: const Text('WhatsApp'),
              onTap: phone.isEmpty
                  ? null
                  : () async {
                      final digits = phone.replaceAll(RegExp(r'\D'), '');
                      final uri = Uri.parse('https://wa.me/$digits');
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.sms_rounded),
              title: const Text('SMS'),
              onTap: phone.isEmpty
                  ? null
                  : () async {
                      final uri = Uri.parse('sms:$phone');
                      await launchUrl(uri);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_rounded),
              title: const Text('In-App Chat'),
              onTap: () {
                // Route must exist in your app routes
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'peerId': uid,
                    'peerName': name,
                    'peerPhoto': user['photoUrl'],
                    'peerPhone': phone,
                  },
                );
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
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
          // Search + filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              color: Colors.white,
              elevation: _searchFocus.hasFocus ? 6 : 2,
              shadowColor: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged, // <-- debounced
                      onSubmitted: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by name, education, profession…',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: (_searchCtrl.text.isNotEmpty)
                            ? IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      width: 1,
                      color: Colors.black12,
                      thickness: 1,
                    ),
                  ),

                  // Filters button with badge
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TextButton.icon(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_activeFiltersCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$_activeFiltersCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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

          // Filter summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_gender.isNotEmpty) _pill(_gender, Icons.wc_rounded),
                  if (_location.isNotEmpty)
                    _pill(_location, Icons.location_on_outlined),
                  _pill(
                    'Age ${_ageRange.start.round()}–${_ageRange.end.round()}',
                    Icons.cake_rounded,
                  ),
                  _pill(
                    _sortBy == 'recent'
                        ? 'Recent'
                        : _sortBy == 'ageAsc'
                        ? 'Age ↑'
                        : 'Age ↓',
                    Icons.sort_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersQuery.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No profiles yet.'));
                }

                final list = _filterAndSort(snap.data!.docs);

                if (list.isEmpty) {
                  return const Center(child: Text('No matching profiles'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final u = list[i];
                    final name = _cap(u['name']?.toString());
                    final profession = _cap(u['profession']?.toString());
                    final address = _cap(u['address']?.toString());
                    final photo = (u['photoUrl'] ?? '').toString();
                    final createdAt = u['createdAt'];
                    final joined = createdAt is Timestamp
                        ? DateFormat.yMMMd().format(createdAt.toDate())
                        : 'N/A';
                    final age = _ageOf(u['dob']);

                    return _ProfileTile(
                      name: name,
                      profession: profession,
                      address: address,
                      age: age,
                      photoUrl: photo,
                      joinedAt: joined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(userData: u),
                        ),
                      ),
                      onConnect: () => _openConnectSheet(u),
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

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.name,
    required this.profession,
    required this.address,
    required this.age,
    required this.photoUrl,
    required this.joinedAt,
    required this.onTap,
    required this.onConnect,
  });

  final String name;
  final String profession;
  final String address;
  final int? age;
  final String photoUrl;
  final String joinedAt;
  final VoidCallback onTap;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (age != null)
                          Text(
                            '$age yrs',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        profession,
                        address,
                      ].where((e) => e.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined $joinedAt',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onConnect,
                icon: const Icon(Icons.phone_in_talk_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}

class _AgeBubble extends StatelessWidget {
  final int value;
  const _AgeBubble({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value yrs',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

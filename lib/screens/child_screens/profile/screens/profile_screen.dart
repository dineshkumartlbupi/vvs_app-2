import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/profile/screens/edit_profile_screen.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/screens/auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text("Not logged in")),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProfileSkeleton();
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text("Error fetching profile")),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text("Profile not found")),
          );
        }

        // Extract values
        final name = _s(data['name']);
        final photoUrl = _s(data['photoUrl']);
        final dobRaw = _s(data['dob']);
        final fatherHusbandName = _s(data['fatherHusbandName']);
        final gender = _s(data['gender']);
        final maritalStatus = _s(data['maritalStatus']);
        final occupation = _s(data['occupation']);
        final qualification = _s(data['qualification']);
        final profession = _s(data['profession']);
        final email = _s(FirebaseAuth.instance.currentUser?.email);
        final mobile = _s(data['mobile']);
        final address = _s(data['address']);
        final bloodGroup = _s(data['bloodGroup']);
        final aadhaar = _s(data['aadhaarNumber']);
        final role = _s(data['role'], fallback: 'user');
        final createdAt = data['createdAt'];
        final createdDate = _formatCreatedAt(createdAt);
        final age = _tryAgeFromDOB(dobRaw);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Collapsing App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeaderBlock(
                    name: name.isEmpty ? 'Member' : name,
                    email: email.isEmpty ? '-' : email,
                    photoUrl: photoUrl,
                    onEdit: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: Column(
                        children: [
                          // Quick Facts
                          _buildQuickFacts(
                            bloodGroup,
                            gender,
                            maritalStatus,
                            age,
                          ),
                          const SizedBox(height: 24),

                          // Personal Details
                          _SectionCard(
                            title: 'Personal Details',
                            icon: Icons.person_outline_rounded,
                            children: [
                              _InfoTile(
                                icon: Icons.badge_rounded,
                                label: 'Full Name',
                                value: name.isEmpty ? '-' : name,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.cake_rounded,
                                label: 'Date of Birth',
                                value: dobRaw.isEmpty ? '-' : dobRaw,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.family_restroom_rounded,
                                label: 'Father / Husband Name',
                                value: fatherHusbandName.isEmpty
                                    ? '-'
                                    : fatherHusbandName,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.perm_identity_rounded,
                                label: 'Aadhaar Number',
                                value: _maskAadhaar(aadhaar),
                                onCopy: aadhaar.isEmpty
                                    ? null
                                    : () => _copy(context, aadhaar),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Contact
                          _SectionCard(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_outlined,
                            children: [
                              _InfoTile(
                                icon: Icons.phone_rounded,
                                label: 'Mobile',
                                value: mobile.isEmpty ? '-' : mobile,
                                onCopy: mobile.isEmpty
                                    ? null
                                    : () => _copy(context, mobile),
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.mail_rounded,
                                label: 'Email',
                                value: email.isEmpty ? '-' : email,
                                onCopy: email.isEmpty
                                    ? null
                                    : () => _copy(context, email),
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.location_on_rounded,
                                label: 'Address',
                                value: address.isEmpty ? '-' : address,
                                maxLines: 3,
                                onCopy: address.isEmpty
                                    ? null
                                    : () => _copy(context, address),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Education & Work
                          _SectionCard(
                            title: 'Education & Work',
                            icon: Icons.work_outline_rounded,
                            children: [
                              _InfoTile(
                                icon: Icons.school_rounded,
                                label: 'Qualification',
                                value:
                                    qualification.isEmpty ? '-' : qualification,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.work_rounded,
                                label: 'Profession',
                                value: profession.isEmpty ? '-' : profession,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.badge_outlined,
                                label: 'Occupation',
                                value: occupation.isEmpty ? '-' : occupation,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Account
                          _SectionCard(
                            title: 'Account Details',
                            icon: Icons.verified_user_outlined,
                            children: [
                              _InfoTile(
                                icon: Icons.admin_panel_settings_rounded,
                                label: 'Role',
                                value: role.toUpperCase(),
                                valueColor: AppColors.primary,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.calendar_month_rounded,
                                label: 'Member Since',
                                value: createdDate,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Logout Button (Bottom)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _handleLogout(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickFacts(
    String bloodGroup,
    String gender,
    String maritalStatus,
    int? age,
  ) {
    final items = [
      if (bloodGroup.isNotEmpty)
        {'icon': Icons.bloodtype_rounded, 'label': bloodGroup, 'title': 'Blood'},
      if (gender.isNotEmpty)
        {'icon': Icons.person_rounded, 'label': gender, 'title': 'Gender'},
      if (maritalStatus.isNotEmpty)
        {'icon': Icons.favorite_rounded, 'label': maritalStatus, 'title': 'Status'},
      if (age != null)
        {'icon': Icons.cake_rounded, 'label': '$age yrs', 'title': 'Age'},
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              Text(
                item['title'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /* -------- helpers ---------- */

  static String _s(dynamic v, {String fallback = ''}) =>
      (v == null) ? fallback : v.toString();

  static String _maskAadhaar(String aadhaar) {
    final digits = aadhaar.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '-';
    final last4 = digits.substring(digits.length - 4);
    return '****-****-$last4';
  }

  static String _formatCreatedAt(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${_mon(d.month)} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
    }
    if (ts is String && ts.isNotEmpty) return ts;
    return '-';
  }

  static String _mon(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];

  static int? _tryAgeFromDOB(String dob) {
    if (dob.trim().isEmpty) return null;
    DateTime? d;
    try {
      final parts = dob.contains('/') ? dob.split('/') : dob.split('-');
      if (parts.length == 3) {
        final dd = int.tryParse(parts[0]);
        final mm = int.tryParse(parts[1]);
        final yy = int.tryParse(parts[2]);
        if (dd != null && mm != null && yy != null && yy > 1900) {
          d = DateTime(yy, mm, dd);
        }
      }
      d ??= DateTime.tryParse(dob);
    } catch (_) {}
    if (d == null) return null;

    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return (age >= 0 && age <= 120) ? age : null;
  }

  static Future<void> _copy(BuildContext context, String text) async {
    if (text.trim().isEmpty || text == '-') return;
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Copied to clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

/* ============================ UI Pieces ============================ */

class _HeaderBlock extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final VoidCallback onEdit;

  const _HeaderBlock({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Pattern (Optional)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.background,
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                        child: !hasPhoto
                            ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: AppColors.subtitle,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;
  final VoidCallback? onCopy;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.onCopy,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '-' : value.trim();

    return InkWell(
      onTap: onCopy,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.subtitle.withOpacity(0.5)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.text,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onCopy != null)
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.primary.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AppColors.border.withOpacity(0.3));
  }
}

/* --------------------------- Skeleton ----------------------------- */

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: _PulseBox(width: 110, height: 110, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      _SkeletonRow(),
                      SizedBox(height: 16),
                      _SkeletonRow(),
                      SizedBox(height: 16),
                      _SkeletonRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PulseBox(width: 40, height: 40, radius: 8),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _PulseBox(width: 80, height: 10),
              SizedBox(height: 8),
              _PulseBox(width: 150, height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulseBox extends StatefulWidget {
  final double width;
  final double height;
  final double? radius;
  final BoxShape? shape;

  const _PulseBox({
    required this.width,
    required this.height,
    this.radius,
    this.shape,
  });

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _a = Tween(
    begin: 0.3,
    end: 0.6,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.shape ?? BoxShape.rectangle;
    final radius = widget.radius ?? 8;
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(radius)
              : null,
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/profile/screens/edit_profile_screen.dart.dart';
import 'package:vvs_app/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,

        body: const Center(child: Text("Not logged in")),
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
          return _ScaffoldShell(
            title: 'My Profilee',
            child: const Center(child: Text("Error fetching profile")),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return _ScaffoldShell(
            title: 'My Profilee',
            child: const Center(child: Text("Profile not found")),
          );
        }

        // Extract values safely
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

          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Centered avatar header
                _HeaderBlock(
                  name: name.isEmpty ? 'Member' : name,
                  email: email.isEmpty ? '-' : email,
                  photoUrl: photoUrl,
                ),

                // Quick facts chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (bloodGroup.isNotEmpty)
                        _InfoChip(
                          icon: Icons.bloodtype,
                          label: 'Blood Group',
                          value: bloodGroup,
                        ),
                      if (gender.isNotEmpty)
                        _InfoChip(
                          icon: Icons.person,
                          label: 'Gender',
                          value: gender,
                        ),
                      if (maritalStatus.isNotEmpty)
                        _InfoChip(
                          icon: Icons.favorite,
                          label: 'Marital Status',
                          value: maritalStatus,
                        ),
                      if (age != null)
                        _InfoChip(
                          icon: Icons.cake,
                          label: 'Age',
                          value: '$age yrs',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Personal Details
                _SectionCard(
                  title: 'Personal Details',
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

                // Contact
                _SectionCard(
                  title: 'Contact',
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

                // Education & Work
                _SectionCard(
                  title: 'Education & Work',
                  children: [
                    _InfoTile(
                      icon: Icons.school_rounded,
                      label: 'Qualification',
                      value: qualification.isEmpty ? '-' : qualification,
                    ),
                    _DividerLine(),
                    _InfoTile(
                      icon: Icons.work_outline_rounded,
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

                // Account
                _SectionCard(
                  title: 'Account',
                  children: [
                    _InfoTile(
                      icon: Icons.verified_user_rounded,
                      label: 'Role',
                      value: role.isEmpty ? '-' : role,
                    ),
                    _DividerLine(),
                    _InfoTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'Member Since',
                      value: createdDate,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
    // Optionally format as "XXXX XXXX 1234" instead.
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
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }
}

/* ============================ UI Pieces ============================ */

class _ScaffoldShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _ScaffoldShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(title),
      ),
      body: child,
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;

  const _HeaderBlock({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Stack(
      children: [
        // gradient header

        // curved bottom
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),
        ),
        // content (avatar & text centered)
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.network(
                            photoUrl,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _AvatarFallback(),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const _AvatarFallback();
                            },
                          )
                        : const _AvatarFallback(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.primary),
              ),
          SizedBox(height: 8,),
              _EditFab(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      color: Colors.white10,
      alignment: Alignment.center,
      child: const Icon(Icons.account_circle, size: 64, color: Colors.white),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
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

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '-' : value.trim();

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color:AppColors.primary),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          v,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      trailing: onCopy == null
          ? null
          : IconButton(
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppColors.primary),
          ),
          Text(
            v,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Skeleton ----------------------------- */

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.primary.withOpacity(0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: _PulseBox(width: 92, height: 92, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: const [
                  _SkeletonTile(),
                  Divider(height: 1),
                  _SkeletonTile(),
                  Divider(height: 1),
                  _SkeletonTile(lines: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final int lines;
  const _SkeletonTile({this.lines = 1});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const _PulseBox(width: 40, height: 40, radius: 10),
      title: const _PulseBox(width: 80, height: 12),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines, (i) {
            final w = i == lines - 1 ? 140.0 : 220.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PulseBox(width: w, height: 14),
            );
          }),
        ),
      ),
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
    begin: 0.35,
    end: 0.75,
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
          color: Colors.white10,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(radius)
              : null,
        ),
      ),
    );
  }
}

class _EditFab extends StatelessWidget {
  final VoidCallback onTap;
  const _EditFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.card),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.card,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

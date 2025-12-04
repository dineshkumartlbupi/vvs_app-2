import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvs_app/screens/message_screen/chat_screen.dart';
import 'package:vvs_app/services/chat_service.dart';
import 'package:vvs_app/theme/app_colors.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileDetailScreen({super.key, required this.userData});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

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

    _scrollController.addListener(() {
      if (_scrollController.offset > 150 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 150 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _call(String phone) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String phone) async {
    HapticFeedback.mediumImpact();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sms(String phone) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _chat(String uid, String name, String photo) async {
    HapticFeedback.mediumImpact();
    await ChatService.ensureConversation(
      peerId: uid,
      peerName: name,
      peerPhoto: photo,
      initialMessage: '',
    );

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final name = _cap(widget.userData['name']?.toString());
    final profession = _cap(widget.userData['profession']?.toString());
    final education = _cap(widget.userData['education']?.toString());
    final address = _cap(widget.userData['address']?.toString());
    final bio = (widget.userData['bio'] ?? 'No bio available.').toString();
    final photoUrl = (widget.userData['photoUrl'] ?? '').toString();
    final joinedAt = widget.userData['createdAt'] is Timestamp
        ? DateFormat.yMMMd().format(
            (widget.userData['createdAt'] as Timestamp).toDate(),
          )
        : 'N/A';
    final age = _ageOf(widget.userData['dob']);
    final height = (widget.userData['height'] ?? '').toString();
    final gotra = (widget.userData['gotra'] ?? '').toString();
    final gender = (widget.userData['gender'] ?? '').toString();
    final maritalStatus = _cap(widget.userData['maritalStatus']?.toString());
    final phone = (widget.userData['mobile'] ?? widget.userData['phone'] ?? '').toString();
    final uid = (widget.userData['_id'] ?? widget.userData['uid'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar with Hero Image
          SliverAppBar(
            expandedHeight: photoUrl.isNotEmpty ? 350 : 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showAppBarTitle ? 1.0 : 0.0,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl.isNotEmpty)
                    Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(gender),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return _buildImagePlaceholder(gender);
                      },
                    )
                  else
                    _buildImagePlaceholder(gender),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Basic Info Card
                      _buildHeaderCard(name, age, gender, profession, education, address, joinedAt),

                      const SizedBox(height: 20),

                      // Quick Facts
                      if (height.isNotEmpty || gotra.isNotEmpty || maritalStatus.isNotEmpty)
                        _buildQuickFacts(height, gotra, maritalStatus),

                      const SizedBox(height: 20),

                      // Bio Section
                      _buildBioSection(bio),

                      const SizedBox(height: 20),

                      // Contact Actions
                      if (phone.isNotEmpty || uid.isNotEmpty)
                        _buildContactActions(phone, uid, name, photoUrl),

                      const SizedBox(height: 40),
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

  Widget _buildImagePlaceholder(String gender) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.accent.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          gender.toLowerCase() == 'female'
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          size: 120,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    String name,
    int? age,
    String gender,
    String profession,
    String education,
    String address,
    String joinedAt,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Age
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (age != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '$age years',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Gender
          if (gender.isNotEmpty)
            _buildInfoRow(Icons.wc_rounded, gender),

          // Profession & Education
          if (profession.isNotEmpty || education.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.work_outline_rounded,
              [profession, education].where((e) => e.isNotEmpty).join(' • '),
            ),
          ],

          // Address
          if (address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, address),
          ],

          // Joined Date
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_rounded, 'Joined $joinedAt'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFacts(String height, String gotra, String maritalStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Quick Facts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (height.isNotEmpty) _chip(height, Icons.height_rounded),
            if (gotra.isNotEmpty) _chip('Gotra: $gotra', Icons.family_restroom_rounded),
            if (maritalStatus.isNotEmpty) _chip(maritalStatus, Icons.favorite_outline_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.article_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
            ),
          ),
          child: Text(
            bio,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactActions(String phone, String uid, String name, String photoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.connect_without_contact_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Call Button
            if (phone.isNotEmpty)
              Expanded(
                child: _EnhancedActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => _call(phone),
                ),
              ),

            if (phone.isNotEmpty && uid.isNotEmpty) const SizedBox(width: 12),

            // WhatsApp Button
            if (phone.isNotEmpty)
              Expanded(
                child: _EnhancedActionButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _whatsapp(phone),
                ),
              ),
          ],
        ),
        if (uid.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _EnhancedActionButton(
              icon: Icons.chat_bubble_rounded,
              label: 'Start Chat',
              color: AppColors.primary,
              onTap: () => _chat(uid, name, photoUrl),
              isExpanded: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== Enhanced Action Button ==================== */

class _EnhancedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isExpanded;

  const _EnhancedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 20 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
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

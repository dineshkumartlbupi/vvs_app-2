import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsDetailScreen.dart';
import 'package:vvs_app/screens/child_screens/news/screens/NewsPostScreen.dart';
import 'package:vvs_app/theme/app_colors.dart';

class NewsBulletinScreen extends StatelessWidget {
  NewsBulletinScreen({super.key});
  final NewsBulletinController controller = Get.put(NewsBulletinController());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.login_rounded,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Not logged in',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userSnap.data!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final bool isAdmin = (userData?['role'] == 'admin');

            return Scaffold(
              backgroundColor: AppColors.background,
              body: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await controller.refreshNews();
                },
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildLoadingSkeleton();
                  }

                  final newsDocs = controller.newsList;
                  if (newsDocs.isEmpty) {
                    return _buildEmptyState(isAdmin);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemCount: newsDocs.length,
                    itemBuilder: (context, index) {
                      final doc = newsDocs[index];
                      final raw = doc.data();

                      // Safe field reads
                      final title = (raw['title'] as String? ?? '').trim();
                      final content = (raw['content'] as String? ?? '').trim();
                      final imageUrl = (raw['imageUrl'] as String? ?? '').trim();
                      
                      Timestamp? createdTs;
                      final t1 = raw['timestamp'];
                      final t2 = raw['createdAt'];
                      if (t1 is Timestamp) {
                        createdTs = t1;
                      } else if (t2 is Timestamp) {
                        createdTs = t2;
                      }

                      final updatedTs = raw['updatedAt'];
                      final tsUpdated =
                          (updatedTs is Timestamp) ? updatedTs : null;
                      
                      String fmt(Timestamp? ts) => ts == null
                          ? ''
                          : DateFormat.yMMMd().add_jm().format(ts.toDate());

                      final whenLabel = tsUpdated != null
                          ? 'Updated ${_getRelativeTime(tsUpdated)}'
                          : 'Posted ${_getRelativeTime(createdTs)}';

                      return _EnhancedNewsCard(
                        title: title.isEmpty ? 'Untitled' : title,
                        content: content,
                        imageUrl: imageUrl,
                        whenLabel: whenLabel,
                        isAdmin: isAdmin,
                        index: index,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Get.to(
                            () => NewsDetailScreen(newsData: raw),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        onEdit: isAdmin
                            ? () {
                                HapticFeedback.selectionClick();
                                Get.to(
                                  () => NewsPostScreen(
                                    existingData: raw,
                                    docId: doc.id,
                                  ),
                                  transition: Transition.rightToLeft,
                                );
                              }
                            : null,
                        onDelete: isAdmin
                            ? () async {
                                HapticFeedback.mediumImpact();
                                final confirm = await _showDeleteDialog(context);
                                if (confirm == true) {
                                  await controller.deleteNews(doc.id);
                                  HapticFeedback.heavyImpact();
                                  Get.snackbar(
                                    'Deleted',
                                    'News item deleted successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.success,
                                    colorText: Colors.white,
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  );
                }),
              ),
              floatingActionButton: isAdmin
                  ? _EnhancedFAB(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Get.to(
                          () => const NewsPostScreen(
                            existingData: {},
                            docId: '',
                          ),
                          transition: Transition.downToUp,
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    final date = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return DateFormat.yMMMd().format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete News'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this news item? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: 5,
      itemBuilder: (_, __) => const _NewsCardSkeleton(),
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
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
              Icons.article_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No News Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Tap the + button to create your first news post'
                : 'Check back later for updates',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/* ==================== Enhanced News Card ==================== */

class _EnhancedNewsCard extends StatefulWidget {
  final String title;
  final String content;
  final String imageUrl;
  final String whenLabel;
  final bool isAdmin;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EnhancedNewsCard({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.whenLabel,
    required this.isAdmin,
    required this.index,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_EnhancedNewsCard> createState() => _EnhancedNewsCardState();
}

class _EnhancedNewsCardState extends State<_EnhancedNewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Staggered animation
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
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
                  // Image Section
                  if (widget.imageUrl.isNotEmpty)
                    _EnhancedImageSection(imageUrl: widget.imageUrl),

                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Content Preview
                        if (widget.content.isNotEmpty)
                          Text(
                            widget.content,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.subtitle,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 12),

                        // Footer: Time and Actions
                        Row(
                          children: [
                            // Time Icon and Label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.whenLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Admin Actions
                            if (widget.isAdmin) ...[
                              _ActionButton(
                                icon: Icons.edit_rounded,
                                color: Colors.blue,
                                onTap: widget.onEdit,
                              ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.delete_rounded,
                                color: AppColors.error,
                                onTap: widget.onDelete,
                              ),
                            ],
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
    );
  }
}

/* ==================== Enhanced Image Section ==================== */

class _EnhancedImageSection extends StatelessWidget {
  final String imageUrl;
  const _EnhancedImageSection({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return _buildImagePlaceholder();
              },
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Read More Badge
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48,
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}

/* ==================== Action Button ==================== */

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
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
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}

/* ==================== Enhanced FAB ==================== */

class _EnhancedFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _EnhancedFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/* ==================== Loading Skeleton ==================== */

class _NewsCardSkeleton extends StatefulWidget {
  const _NewsCardSkeleton();

  @override
  State<_NewsCardSkeleton> createState() => _NewsCardSkeletonState();
}

class _NewsCardSkeletonState extends State<_NewsCardSkeleton>
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
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            // Content Placeholder
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _bar(width: 200, height: 16),
                  const SizedBox(height: 12),
                  _bar(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  _bar(width: double.infinity, height: 12),
                  const SizedBox(height: 12),
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

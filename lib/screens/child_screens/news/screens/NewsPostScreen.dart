import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import 'package:vvs_app/screens/child_screens/news/controllers/news_bulletin_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';

class NewsPostScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  final String docId;

  const NewsPostScreen({
    super.key,
    required this.existingData,
    required this.docId,
  });

  @override
  State<NewsPostScreen> createState() => _NewsPostScreenState();
}

class _NewsPostScreenState extends State<NewsPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _contentC = TextEditingController();

  final _picker = ImagePicker();
  File? _imageFile; // new local image (if selected)
  String _existingImageUrl = ''; // existing remote image (when editing)

  bool _loading = false;
  bool _dirty = false; // track unsaved changes
  final controller = Get.find<NewsBulletinController>();

  static const int _titleMaxLen = 100;
  static const int _contentMaxLen = 1500;

  @override
  void initState() {
    super.initState();
    if (widget.existingData.isNotEmpty) {
      _titleC.text = (widget.existingData['title'] ?? '').toString();
      _contentC.text = (widget.existingData['content'] ?? '').toString();
      _existingImageUrl = (widget.existingData['imageUrl'] ?? '').toString();
    }
    // Live updates for preview + counters + dirty flag
    _titleC.addListener(_onAnyFieldChanged);
    _contentC.addListener(_onAnyFieldChanged);
  }

  void _onAnyFieldChanged() {
    if (!_dirty) _dirty = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleC.removeListener(_onAnyFieldChanged);
    _contentC.removeListener(_onAnyFieldChanged);
    _titleC.dispose();
    _contentC.dispose();
    super.dispose();
  }

  bool get _hasAnyImage =>
      _imageFile != null || (_existingImageUrl.trim().isNotEmpty);

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    final source = (choice == 'camera')
        ? ImageSource.camera
        : ImageSource.gallery;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _dirty = true;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageUrl = '';
      _dirty = true;
    });
  }

  Future<String> _uploadImageIfNeeded() async {
    // If a new image is picked, upload it. Otherwise keep existing URL.
    if (_imageFile == null) {
      return _existingImageUrl;
    }

    final fileName =
        'news_images/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';

    final ref = FirebaseStorage.instance.ref().child(fileName);
    final snapshot = await ref.putFile(_imageFile!).whenComplete(() => null);
    final url = await snapshot.ref.getDownloadURL();

    _existingImageUrl = url; // keep in memory as current remote url
    return url;
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasAnyImage) {
      _toast('Please add an image for the news.');
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadImageIfNeeded();

      if (widget.docId.isEmpty) {
        // CREATE: your controller uses createdAt internally; list screen reads timestamp || createdAt
        await controller.postNews(
          title: _titleC.text.trim(),
          content: _contentC.text.trim(),
          imageUrl: imageUrl,
        );
      } else {
        // UPDATE: do not overwrite created timestamp
        final data = <String, dynamic>{
          'title': _titleC.text.trim(),
          'content': _contentC.text.trim(),
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await controller.updateNews(docId: widget.docId, data: data);
      }

      if (!mounted) return;
      _dirty = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('News saved!')));
      Navigator.pop(context);
    } catch (e) {
      _toast('Failed to save news. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Do you really want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int get _contentWordCount {
    final text = _contentC.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docId.isNotEmpty;

    // Remaining counters
    final titleLeft = (_titleMaxLen - _titleC.text.characters.length).clamp(
      0,
      _titleMaxLen,
    );
    final contentLeft = (_contentMaxLen - _contentC.text.characters.length)
        .clamp(0, _contentMaxLen);

    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(isEditing ? 'Edit News' : 'Add News'),
          actions: [
            IconButton(
              tooltip: 'Save',
              onPressed: _loading ? null : _saveNews,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      // ====== EDIT CARD ======
                      Card(
                        color: AppColors.card,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Header image
                                _HeaderImage(
                                  imageFile: _imageFile,
                                  imageUrl: _existingImageUrl,
                                  onPick: _pickImage,
                                  onRemove: _hasAnyImage ? _removeImage : null,
                                ),
                                const SizedBox(height: 16),

                                // Title
                                TextFormField(
                                  controller: _titleC,
                                  maxLength: _titleMaxLen,
                                  textCapitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(_titleMaxLen),
                                    FilteringTextInputFormatter.singleLineFormatter,
                                  ],
                                  smartDashesType: SmartDashesType.disabled,
                                  smartQuotesType: SmartQuotesType.disabled,
                                  decoration: _inputDecoration(
                                    label: 'Title',
                                    hint:
                                        'Short, clear headline (e.g. “Blood Donation Camp Announced”)',
                                    icon: Icons.title_rounded,
                                    counterText: '$titleLeft left',
                                    helperText:
                                        'A strong headline helps readers discover your news.',
                                    suffix: _titleC.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Clear',
                                            onPressed: () =>
                                                setState(() => _titleC.clear()),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Title is required'
                                      : null,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),

                                // Content
                                TextFormField(
                                  controller: _contentC,
                                  maxLength: _contentMaxLen,
                                  minLines: 6,
                                  maxLines: 12,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  keyboardType: TextInputType.multiline,
                                  smartDashesType: SmartDashesType.enabled,
                                  smartQuotesType: SmartQuotesType.enabled,
                                  decoration: _inputDecoration(
                                    label: 'Content',
                                    hint: 'Write the full news content…',
                                    icon: Icons.notes_rounded,
                                    counterText:
                                        '$contentLeft left • $_contentWordCount words',
                                    helperText:
                                        'Keep it concise and factual. Add dates, places, and credits if any.',
                                    suffix: _contentC.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Clear',
                                            onPressed: () => setState(
                                              () => _contentC.clear(),
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Content is required'
                                      : null,
                                  textInputAction: TextInputAction.newline,
                                ),
                                const SizedBox(height: 18),

                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.save_rounded),
                                    label: Text(
                                      isEditing ? 'Update News' : 'Post News',
                                    ),
                                    onPressed: _loading ? null : _saveNews,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== LIVE PREVIEW ======
                      _PreviewCard(
                        title: _titleC.text.trim(),
                        content: _contentC.text.trim(),
                        imageFile: _imageFile,
                        imageUrl: _existingImageUrl,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_loading)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    child: const Center(
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? counterText,
    String? helperText,
    Widget? suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      counterText: counterText ?? '',
      helperText: helperText,
      helperMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      suffixIcon: suffix,
    );
  }
}

/* ======================= Header Image Widget ======================= */

class _HeaderImage extends StatelessWidget {
  final File? imageFile;
  final String imageUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _HeaderImage({
    required this.imageFile,
    required this.imageUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = imageFile != null;
    final hasRemote = imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Image / Placeholder
            Positioned.fill(
              child: (hasLocal || hasRemote)
                  ? (hasLocal
                        ? Image.file(imageFile!, fit: BoxFit.cover)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return _placeholder();
                            },
                          ))
                  : _placeholder(),
            ),

            // Top-right: Change
            Positioned(
              top: 8,
              right: 8,
              child: _ActionChip(
                icon: Icons.image_rounded,
                label: (hasLocal || hasRemote) ? 'Change' : 'Add image',
                onTap: onPick,
              ),
            ),

            // Top-left: Remove (only if image present)
            if (onRemove != null)
              Positioned(
                top: 8,
                left: 8,
                child: _ActionChip(
                  icon: Icons.delete_forever_rounded,
                  label: 'Remove',
                  onTap: onRemove!,
                  isDestructive: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image_outlined, size: 42, color: Colors.white54),
          SizedBox(height: 6),
          Text('Add a cover image', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDestructive
        ? Colors.red.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.14);
    final fg = isDestructive ? Colors.red : AppColors.primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================ Live Preview ============================ */

class _PreviewCard extends StatelessWidget {
  final String title;
  final String content;
  final File? imageFile;
  final String imageUrl;

  const _PreviewCard({
    required this.title,
    required this.content,
    required this.imageFile,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = imageFile != null;
    final hasRemote = imageUrl.trim().isNotEmpty;

    return Card(
      color: AppColors.card,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: (hasLocal || hasRemote)
                  ? (hasLocal
                        ? Image.file(imageFile!, fit: BoxFit.cover)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return _ph();
                            },
                          ))
                  : _ph(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Your headline will appear here' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.isEmpty
                      ? 'Start typing your news content to see a live preview…'
                      : content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _todayPretty(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
    color: Colors.white10,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: Colors.white38, size: 42),
  );

  static String _todayPretty() {
    final d = DateTime.now();
    const mons = [
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
    ];
    return 'Preview • ${mons[d.month - 1]} ${d.day}, ${d.year}';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/auth/screens/login_screen.dart';
import 'package:vvs_app/widgets/bottom_footer.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_components.dart';

class CustomDrawer extends StatefulWidget {
  final Map<String, Widget> screenMap;
  final void Function(Widget) onTap;

  const CustomDrawer({super.key, required this.screenMap, required this.onTap});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String displayName = 'Guest User';
  String email = 'Not signed in';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          displayName = data['name'] ?? user.displayName ?? 'Guest User';
          email = data['email'] ?? user.email ?? 'Not signed in';
          photoUrl = data['photoUrl'] ?? user.photoURL;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            photoUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(displayName, color: Colors.white),
                    const SizedBox(height: 4),
                    AppSubTitle(email, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.screenMap.length,
              itemBuilder: (context, index) {
                final title = widget.screenMap.keys.elementAt(index);
                final screen = widget.screenMap.values.elementAt(index);
                return ListTile(
                  leading: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                  title: AppLabel(title),
                  onTap: () => widget.onTap(screen),
                );
              },
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
            ),
            title: AppLabel("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          const BottomFooter(),
        ],
      ),
    );
  }
}

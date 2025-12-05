import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/child_screens/profile/controller/edit_profile_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());
    controller.fetchUserData();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Profile Image Picker
              _buildProfileImagePicker(controller),
              const SizedBox(height: 32),

              // Personal Details Section
              _EditSection(
                title: 'Personal Details',
                icon: Icons.person_outline_rounded,
                children: [
                  AppInput(
                    controller: controller.nameC,
                    label: 'Full Name',
                    prefixIcon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.dobC,
                    label: 'Date of Birth',
                    hint: 'DD/MM/YYYY',
                    prefixIcon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.genderC,
                    label: 'Gender',
                    prefixIcon: Icons.wc_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.maritalStatusC,
                    label: 'Marital Status',
                    prefixIcon: Icons.favorite_border_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.fatherHusbandNameC,
                    label: 'Father / Husband Name',
                    prefixIcon: Icons.family_restroom_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Info Section
              _EditSection(
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                children: [
                  AppInput(
                    controller: controller.mobileC,
                    label: 'Mobile Number',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.addressC,
                    label: 'Address',
                    prefixIcon: Icons.location_on_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Other Details Section
              _EditSection(
                title: 'Other Details',
                icon: Icons.info_outline_rounded,
                children: [
                  AppInput(
                    controller: controller.bgC,
                    label: 'Blood Group',
                    prefixIcon: Icons.bloodtype_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.samajC,
                    label: 'Samaj',
                    prefixIcon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.aadhaarC,
                    label: 'Aadhaar Number',
                    prefixIcon: Icons.fingerprint_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.qualificationC,
                    label: 'Qualification',
                    prefixIcon: Icons.school_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.occupationC,
                    label: 'Occupation',
                    prefixIcon: Icons.work_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: controller.professionC,
                    label: 'Profession',
                    prefixIcon: Icons.business_center_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'SAVE CHANGES',
                  emphasis: true,
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await controller.saveProfile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Profile updated successfully!'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileImagePicker(EditProfileController controller) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.background,
                backgroundImage: controller.imageFile != null
                    ? FileImage(controller.imageFile!)
                    : controller.photoUrl.value.isNotEmpty
                        ? NetworkImage(controller.photoUrl.value)
                        : null as ImageProvider<Object>?,
                child: (controller.imageFile == null &&
                        controller.photoUrl.value.isEmpty)
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
              onTap: () {
                HapticFeedback.selectionClick();
                controller.pickImage();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _EditSection({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

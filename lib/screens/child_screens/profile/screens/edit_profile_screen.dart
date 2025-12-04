import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text("Edit Profile")),
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: controller.pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: controller.imageFile != null
                      ? FileImage(controller.imageFile!)
                      : controller.photoUrl.value.isNotEmpty
                          ? NetworkImage(controller.photoUrl.value)
                          : null as ImageProvider<Object>?,
                  child: (controller.imageFile == null &&
                          controller.photoUrl.value.isEmpty)
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 24), // Increased spacing below profile image

              AppInput(controller: controller.nameC, label: 'Name'),
              const SizedBox(height: 16),

              AppInput(controller: controller.mobileC, label: 'Mobile'),
              const SizedBox(height: 16),

              AppInput(controller: controller.addressC, label: 'Address'),
              const SizedBox(height: 16),

              AppInput(controller: controller.bgC, label: 'Blood Group'),
              const SizedBox(height: 16),

              AppInput(controller: controller.samajC, label: 'Samaj'),
              const SizedBox(height: 16),

              AppInput(controller: controller.aadhaarC, label: 'Aadhaar Number'),
              const SizedBox(height: 16),

              AppInput(controller: controller.dobC, label: 'Date of Birth'),
              const SizedBox(height: 16),

              AppInput(controller: controller.genderC, label: 'Gender'),
              const SizedBox(height: 16),

              AppInput(controller: controller.maritalStatusC, label: 'Marital Status'),
              const SizedBox(height: 16),

              AppInput(controller: controller.fatherHusbandNameC, label: 'Father/Husband Name'),
              const SizedBox(height: 16),

              AppInput(controller: controller.qualificationC, label: 'Qualification'),
              const SizedBox(height: 16),

              AppInput(controller: controller.occupationC, label: 'Occupation'),
              const SizedBox(height: 16),

              AppInput(controller: controller.professionC, label: 'Profession'),
              const SizedBox(height: 32),

              Obx(() => controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : AppButton(
                      text: 'SAVE',
                      onPressed: () async {
                        await controller.saveProfile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated!')),
                          );
                          Navigator.pop(context);
                        }
                      },
                    )),
            ],
          ),
        );
      }),
    );
  }
}

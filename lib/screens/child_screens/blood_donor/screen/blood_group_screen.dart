import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/app_dropdown.dart';
import 'package:vvs_app/screens/child_screens/blood_donor/controller/blood_donor_controller.dart';

class BloodDonorsScreen extends StatelessWidget {
  const BloodDonorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BloodDonorController controller = Get.put(BloodDonorController());

    final List<String> bloodGroups = [
      'A+',
      'A−',
      'B+',
      'B−',
      'AB+',
      'AB−',
      'O+',
      'O−',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blood Donors'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AppDropdown(
                label: 'Filter by Blood Group',
                items: bloodGroups,
                value: controller.selectedBloodGroup.value.isEmpty
                    ? null
                    : controller.selectedBloodGroup.value,
                onChanged: (val) {
                  controller.selectedBloodGroup.value = val ?? '';
                },
                validator: (_) => null,
              ),
            ),
          ),

          // List Section
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final donors = controller.filteredDonors;

              if (donors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bloodtype_rounded,
                          size: 60,
                          color: AppColors.error.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No donors found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subtitle.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try selecting a different blood group',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: donors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final donor = donors[i].data();
                  final name = donor['name'] ?? 'No Name';
                  final bloodGroup = donor['bloodGroup'] ?? '-';
                  final mobile = donor['mobile'] ?? '-';
                  final location = donor['location'] ?? 'Not specified';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // TODO: Show donor details or call action
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    bloodGroup,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.error,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 14,
                                            color: AppColors.subtitle.withOpacity(0.7)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.subtitle.withOpacity(0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_rounded,
                                            size: 14,
                                            color: AppColors.subtitle.withOpacity(0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          mobile,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.subtitle.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

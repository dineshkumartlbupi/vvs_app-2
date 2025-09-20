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
        title: const Text('Blood Group & Donors'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppDropdown(
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
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final donors = controller.filteredDonors;

                if (donors.isEmpty) {
                  return const Center(child: Text('No donors found'));
                }

                return ListView.builder(
                  itemCount: donors.length,
                  itemBuilder: (ctx, i) {
                    final d = donors[i].data();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Blood Group: ${d['bloodGroup'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mobile: ${d['mobile'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            if (d['location'] != null)
                              Text(
                                'Location: ${d['location']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

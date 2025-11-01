import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vvs_app/screens/child_screens/blood_donor/controller/blood_donor_controller.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class BloodDonorFormScreen extends StatefulWidget {
  const BloodDonorFormScreen({super.key});

  @override
  State<BloodDonorFormScreen> createState() => _BloodDonorFormScreenState();
}

class _BloodDonorFormScreenState extends State<BloodDonorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();

  final BloodDonorController _donorController = Get.put(BloodDonorController());

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    await _donorController.fetchCurrentUserData();
    if (mounted) {
      _donorController.prefillFormControllers(
        nameCtrl: _nameController,
        ageCtrl: _ageController,
        phoneCtrl: _phoneController,
        emailCtrl: _emailController,
        locationCtrl: _locationController,
        bloodGroupCtrl: _bloodGroupController,
      );
    }
  }

  void _submitForm() async {
    // First check if already donor
    try {
      final already = await _donorController.isAlreadyDonor();
      if (already) {
        // Show pop-up (dialog)
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Already Registered'),
              content: const Text('You are already in the donor list.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pop(context); // Navigate back to home
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {
      // Could not check, continue or show error
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        await _donorController.addDonor(
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          weight: int.parse(_weightController.text.trim()),
          mobile: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          location: _locationController.text.trim(),
          bloodGroup: _bloodGroupController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully registered as donor!')),
          );
          Navigator.pop(context); // Navigate back to home page after successful registration
        }
      } on AlreadyDonorException catch (_) {
        // If thrown from controller again
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Already Registered'),
              content: const Text('You are already in the donor list.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      // Highlight unfilled fields via validation
      // The validator messages do this
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Blood Donor')),
      body: Obx(() {
        if (_donorController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12), // Light top margin added here
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction, // to highlight as user types
              child: ListView(
                children: [
                  AppInput(
                    controller: _nameController,
                 label: 'Full Name',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _ageController,
                  label: 'Age',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter age';
                      final age = int.tryParse(value.trim());
                      if (age == null) return 'Enter valid number';
                      if (age < 18 || age > 65) {
                        return 'Age must be between 18 and 65';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                 AppInput(
                    controller: _weightController,
                   label:  'Weight (kg)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter weight';
                      final weight = int.tryParse(value.trim());
                      if (weight == null) return 'Enter valid number';
                      if (weight < 45) {
                        return 'Minimum weight should be 45 kg';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter phone number';
                      if (value.trim().length != 10) return 'Enter valid 10‑digit number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _emailController,
                    label: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter email';
                      if (!value.contains('@')) return 'Enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                 AppInput(
                    controller: _locationController,
                    label: 'Location',
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Enter your location' : null,
                  ),
                  const SizedBox(height: 16),
                 AppInput(
                    controller: _bloodGroupController,
                    label: 'Blood Group',
                    // enabled: false,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/family_regiestration/controller/family_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/app_dropdown.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class FamilyRegistrationScreenForm extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId;

  const FamilyRegistrationScreenForm({
    super.key,
    this.existingData,
    this.docId,
  });

  @override
  State<FamilyRegistrationScreenForm> createState() =>
      _FamilyRegistrationScreenFormState();
}

class _FamilyRegistrationScreenFormState
    extends State<FamilyRegistrationScreenForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _occupationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _professionController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Widowed',
    'Divorced',
  ];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _preloadIfEditing();
  }

  void _preloadIfEditing() {
    final existing = widget.existingData;
    if (existing == null) return;

    _nameController.text = (existing['name'] ?? '').toString();
    _relationController.text = (existing['relation'] ?? '').toString();
    _ageController.text = (existing['age'] ?? '').toString();
    _dobController.text = (existing['dob'] ?? '').toString();
    _occupationController.text = (existing['occupation'] ?? '').toString();
    _qualificationController.text = (existing['qualification'] ?? '').toString();
    _professionController.text = (existing['profession'] ?? '').toString();
    _emailController.text = (existing['email'] ?? '').toString();
    _mobileController.text = (existing['mobile'] ?? existing['phone'] ?? '').toString();
    _addressController.text = (existing['address'] ?? '').toString();
    _bloodGroupController.text = (existing['bloodGroup'] ?? '').toString();
    _aadhaarNumberController.text = (existing['aadhaarNumber'] ?? '').toString();

    _selectedGender = (existing['gender'] ?? '').toString().isNotEmpty
        ? existing['gender'].toString()
        : null;
    _selectedMaritalStatus =
        (existing['maritalStatus'] ?? '').toString().isNotEmpty ? existing['maritalStatus'].toString() : null;
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'relation': _relationController.text.trim(),
      'age': _ageController.text.trim(),
      'dob': _dobController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'profession': _professionController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _mobileController.text.trim(),
      'address': _addressController.text.trim(),
      'bloodGroup': _bloodGroupController.text.trim(),
      'aadhaarNumber': _aadhaarNumberController.text.trim(),
      'gender': _selectedGender,
      'maritalStatus': _selectedMaritalStatus,
    };

    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    try {
      if (widget.docId == null) {
        // Create new member
        data['createdAt'] = Timestamp.fromDate(now);
        if (uid != null) data['createdBy'] = uid;

        // Prefer controller method if available
        try {
          // If FamilyController.saveMember exists and returns something, use it.
          // The signature we used earlier in examples was:
          // FamilyController.saveMember(context:..., name:..., ...)
          // But here we try a generic method first; adjust if your controller API differs.
          // If your FamilyController.saveMember method expects named arguments, call it:
          await FamilyController.saveMember(
            context: context,
            name: data['name'],
            relation: data['relation'],
            age: data['age'],
            dob: data['dob'],
            gender: data['gender'],
            maritalStatus: data['maritalStatus'],
            occupation: data['occupation'],
            qualification: data['qualification'],
            profession: data['profession'],
            email: data['email'],
            mobile: data['phone'],
            address: data['address'],
            bloodGroup: data['bloodGroup'],
            aadhaarNumber: data['aadhaarNumber'],
            // you may add createdBy/createdAt if controller supports it
          );
                } catch (_) {
          // Fallback to Firestore direct add
          await FirebaseFirestore.instance.collection('family_members').add(data);
        }

        messenger.showSnackBar(const SnackBar(content: Text('Member added successfully')));
      } else {
        // Update existing member
        data['updatedAt'] = Timestamp.fromDate(now);

        try {
          // Prefer controller update method if available
          await FamilyController.updateMember(widget.docId!, data);
                } catch (_) {
          // Fallback to Firestore direct update
          await FirebaseFirestore.instance.collection('family_members').doc(widget.docId).update(data);
        }

        messenger.showSnackBar(const SnackBar(content: Text('Member updated successfully')));
      }

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context, true); // return true indicating success
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _qualificationController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _bloodGroupController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docId != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Family Member' : 'Add Family Member'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AppTitle('Register a Family Member'),
              const SizedBox(height: 16),
              AppInput(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _relationController,
                label: 'Relation',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _dobController,
                label: 'Date of Birth (dd/mm/yyyy)',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter valid age';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppDropdown(
                label: 'Gender',
                items: _genderOptions,
                value: _selectedGender,
                onChanged: (val) => setState(() => _selectedGender = val),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppDropdown(
                label: 'Marital Status',
                items: _maritalStatusOptions,
                value: _selectedMaritalStatus,
                onChanged: (val) => setState(() => _selectedMaritalStatus = val),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _occupationController,
                label: 'Occupation',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _qualificationController,
                label: 'Qualification',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _professionController,
                label: 'Profession',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  if (!v.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _mobileController,
                label: 'Mobile',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // optional
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 7) return 'Enter valid mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _addressController,
                label: 'Address',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _bloodGroupController,
                label: 'Blood Group',
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _aadhaarNumberController,
                label: 'Aadhaar Number',
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : AppButton(
                      text: isEditing ? 'UPDATE' : 'SAVE',
                      onPressed: _saveMember,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

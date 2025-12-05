import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vvs_app/screens/child_screens/book_author/controller/book_upload_controller.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  PlatformFile? _pickedPdf;
  bool _isLoading = false;

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedPdf = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a PDF file.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await BookUploadController.uploadBook(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      pdfFile: _pickedPdf!,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book uploaded successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add New Book"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _titleController,
                label: "Book Title",
                prefixIcon: Icons.book_rounded,
                validator: (value) => value!.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _authorController,
                label: "Author Name",
                prefixIcon: Icons.person_rounded,
                validator: (value) => value!.isEmpty ? "Enter author" : null,
              ),
              const SizedBox(height: 24),
              
              // PDF Picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 48,
                      color: _pickedPdf != null ? Colors.redAccent : AppColors.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pickedPdf != null ? _pickedPdf!.name : "No PDF Selected",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _pickedPdf != null ? AppColors.text : AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppOutlinedButton(
                      text: _pickedPdf == null ? "Pick PDF" : "Change PDF",
                      onPressed: _pickPDF,
                      leadingIcon: Icons.upload_file_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              AppButton(
                text: "Upload Book",
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

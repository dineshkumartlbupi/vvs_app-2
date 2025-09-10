import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart'; // For AppTitle

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String developerName = "Rahul Verma";
    const String email = "rahul.verma@example.com";

    const List<String> skills = [
      "Flutter & Dart",
      "Firebase Integration",
      "REST API Development",
      "State Management (Provider, Riverpod)",
      "UI/UX Design"
    ];

    const List<String> tools = [
      "VS Code",
      "Android Studio",
      "Figma",
      "Postman",
      "Git & GitHub",
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Developer'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTitle('Developer Name'),
            const SizedBox(height: 8),
            Text(
              developerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),

            const AppTitle('Email'),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            const AppTitle('Skills'),
            const SizedBox(height: 8),
            ...skills.map((skill) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context).primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(skill,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),
            const AppTitle('Tools Used'),
            const SizedBox(height: 8),
            ...tools.map((tool) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.build,
                          color: Theme.of(context).primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tool,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

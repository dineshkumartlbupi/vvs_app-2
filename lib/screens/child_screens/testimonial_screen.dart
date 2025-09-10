import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
//import 'package:vvs_app/widgets/ui_components.dart'; // For AppTitle

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  final List<Map<String, String>> testimonials = const [
    {
      'name': 'Amit Varshney',
      'role': 'Community Member',
      'message':
          'VVS has truly brought our community closer. The support during emergencies and the events have been incredible.',
    },
    {
      'name': 'Pooja Varshney',
      'role': 'Donor & Volunteer',
      'message':
          'Proud to be part of a platform that values seva and unity. The initiatives are well-organized and impactful.',
    },
    {
      'name': 'Rahul Varshney',
      'role': 'Youth Member',
      'message':
          'As a young member, I’ve found guidance, opportunities, and a sense of belonging. VVS is more than just a network.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Testimonials'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: testimonials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testimonial['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  testimonial['role'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"${testimonial['message']}"',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

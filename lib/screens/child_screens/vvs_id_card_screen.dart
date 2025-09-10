  import 'package:flutter/material.dart';
import 'package:vvs_app/theme/app_colors.dart';
import 'package:vvs_app/widgets/ui_components.dart'; // For AppTitle

class VvsIdCardScreen extends StatelessWidget {
  const VvsIdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user data (replace with real values from backend or provider)
    const String memberName = "Rohit Sharma";
    const String registrationCode = "VVS20250904AB";
    const String vvsId = "VVS-012345";
    const String mobileNumber = "+91 9876543210";
    const String status = "Verified";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('VVS ID Card'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTitle('Member Name'),
            const SizedBox(height: 8),
            Text(
              memberName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),

            const AppTitle('Registration Code'),
            const SizedBox(height: 8),
            Text(
              registrationCode,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            const AppTitle('VVS ID'),
            const SizedBox(height: 8),
            Text(
              vvsId,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            const AppTitle('Mobile Number'),
            const SizedBox(height: 8),
            Text(
              mobileNumber,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            const AppTitle('Status'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  status == "Verified" ? Icons.verified : Icons.pending,
                  color: status == "Verified"
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    color: status == "Verified"
                        ? Colors.green
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SIMBARA - ADMIN",
            style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.admin,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 100, color: AppColors.admin),
            SizedBox(height: 20),
            Text(
              "Management Admin",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.admin),
            ),
            Text("Manajemen User & Log Aktivitas"),
          ],
        ),
      ),
    );
  }
}

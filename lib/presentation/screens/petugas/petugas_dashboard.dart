import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SIMBARA - PETUGAS",
            style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.petugas,
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
            Icon(Icons.engineering, size: 100, color: AppColors.petugas),
            SizedBox(height: 20),
            Text(
              "Dashboard Petugas",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petugas),
            ),
            Text("Verifikasi Peminjaman & Pengembalian"),
          ],
        ),
      ),
    );
  }
}

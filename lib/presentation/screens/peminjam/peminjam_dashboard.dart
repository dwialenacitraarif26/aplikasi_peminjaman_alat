import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class PeminjamDashboard extends StatelessWidget {
  const PeminjamDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SIMBARA - PEMINJAM",
            style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.peminjam,
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
            Icon(Icons.shopping_cart, size: 100, color: AppColors.peminjam),
            SizedBox(height: 20),
            Text(
              "Katalog Alat",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.peminjam),
            ),
            Text("Peminjaman Alat & Riwayat"),
          ],
        ),
      ),
    );
  }
}

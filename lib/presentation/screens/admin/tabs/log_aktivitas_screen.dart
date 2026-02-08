import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LogAktivitasScreen extends StatelessWidget {
  const LogAktivitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Aktivitas", style: TextStyle(color: AppColors.darkblue)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text("Halaman Log Aktivitas (Mentahan)"),
      ),
    );
  }
}
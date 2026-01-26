import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splasscreen.png',
            width: 160,
            fit: BoxFit.fitWidth,
          ),
          // Bungkus kedua teks ke dalam satu Transform agar keduanya naik bersamaan
          Transform.translate(
            offset: const Offset(0, 15), // Mengangkat seluruh grup teks ke atas
            child: const Column(
              children: [
                Text(
                  'SIMBARA',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Sekarang height: 0 atau kecil akan benar-benar terlihat rapat
                SizedBox(height: 0), 
                Text(
                  'Sistem Peminjaman Alat Brantas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
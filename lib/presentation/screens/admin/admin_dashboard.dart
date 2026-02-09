import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/alat_tab.dart';
import 'tabs/aktivitas_tab.dart';
import 'tabs/pengguna_tab.dart';
import 'tabs/pengaturan_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const AlatTab(),
    const AktivitasTab(),
    const PenggunaTab(),
    const PengaturanTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        // Shadow dan Dekorasi Container Navbar
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15), // Melengkung halus sesuai gambar
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2), // Bayangan halus ke atas
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.darkblue,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            elevation: 0, // Elevation 0 karena sudah pakai shadow container
            items: [
              _buildNavItem(Icons.home_filled, "Beranda", 0),
              _buildNavItem(Icons.home_work, "Alat", 1),
              _buildNavItem(Icons.timeline, "Aktivitas", 2),
              _buildNavItem(Icons.person, "Pengguna", 3),
              _buildNavItem(Icons.settings, "Pengaturan", 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          // Background biru muda oval pada ikon yang dipilih sesuai gambar
          color: isSelected ? AppColors.inputBg.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
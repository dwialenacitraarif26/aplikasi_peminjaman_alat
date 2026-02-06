import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/alat_tab.dart';
import 'tabs/aktivitas_tab.dart';
import 'tabs/pengguna_tab.dart';
import 'tabs/pengaturan_tab.dart'; // halaman yang mengautr navigasi agar bisa berpindah ke halaman lain

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Daftar file tab yang dipanggil
  final List<Widget> _pages = [
    const HomeTab(),
    const AlatTab(),
    const AktivitasTab(),
    const PenggunaTab(),
    const PengaturanTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.darkblue,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.home, "Beranda", 0),
            _buildNavItem(Icons.inventory, "Alat", 1),
            _buildNavItem(Icons.show_chart, "Aktivitas", 2),
            _buildNavItem(Icons.people, "Pengguna", 3),
            _buildNavItem(Icons.settings, "Pengaturan", 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color:
              _currentIndex == index ? AppColors.inputBg : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

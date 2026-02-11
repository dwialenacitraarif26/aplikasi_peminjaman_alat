import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../presentation/screens/admin/tabs/pengaturan_tab.dart';
import '../peminjam/tabs/alat_peminjam_tab.dart';
import '../peminjam/tabs/home_tab.dart';
import '../peminjam/tabs/riwayat_tab.dart';

class PeminjamDashboard extends StatefulWidget {
  const PeminjamDashboard({super.key});

  @override
  State<PeminjamDashboard> createState() => _PeminjamDashboardState();
}

class _PeminjamDashboardState extends State<PeminjamDashboard> {
  int _selectedIndex = 0;

  // Daftar halaman untuk Peminjam sesuai gambar
  final List<Widget> _pages = [
    const HomeTab(),
    const AlatPeminjamTab(),
    const RiwayatTab(),
    const PengaturanTab(), // UI Pengaturan sama untuk semua role
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Border radius landai hanya di pojok atas (sesuai gambar)
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Theme(
            data: ThemeData(
              useMaterial3: true,
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor:
                    const Color(0xFFD0E4FF), // Lingkaran biru muda saat aktif
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: AppColors.darkblue);
                  }
                  return const IconThemeData(color: Colors.grey);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                        color: AppColors.darkblue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12);
                  }
                  return const TextStyle(color: Colors.grey, fontSize: 12);
                }),
              ),
            ),
            child: NavigationBar(
              height: 65, // Tinggi ceper agar tidak terlalu keatas
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_work_outlined),
                  selectedIcon: Icon(Icons.home_work),
                  label: 'Alat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

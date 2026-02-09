import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../presentation/screens/admin/tabs/pengaturan_tab.dart';

class PetugasDashboard extends StatefulWidget {
  const PetugasDashboard({super.key});

  @override
  State<PetugasDashboard> createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends State<PetugasDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(
        child: Text("Beranda Petugas",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Halaman Persetujuan")),
    const Center(child: Text("Halaman Pengembalian")),
    const Center(child: Text("Halaman Laporan")),
    const PengaturanTab(),
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
          // Radius hanya di pojok kiri dan kanan atas agar landai
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                ..withOpacity(0.1), // Shadow tipis sesuai gambar
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
                    const Color(0xFFD0E4FF), // Lingkaran biru muda di gambar
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                        color: AppColors.darkblue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12);
                  }
                  return const TextStyle(color: Colors.grey, fontSize: 12);
                }),
                // Agar icon saat aktif berwarna darkblue
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: AppColors.darkblue);
                  }
                  return const IconThemeData(color: Colors.grey);
                }),
              ),
            ),
            child: NavigationBar(
              height: 65, // Tinggi diturunkan agar tidak terlalu keatas
              selectedIndex: _selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
                  icon: Icon(Icons.check_circle_outlined),
                  selectedIcon: Icon(Icons.check_circle),
                  label: 'Persetujuan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.replay_outlined),
                  selectedIcon: Icon(Icons.replay),
                  label: 'Pengembalian',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  selectedIcon: Icon(Icons.description),
                  label: 'Laporan',
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

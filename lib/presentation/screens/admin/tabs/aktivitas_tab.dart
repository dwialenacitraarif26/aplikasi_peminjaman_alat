import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';

class AktivitasTab extends StatelessWidget {
  const AktivitasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.inputBg,
                    child: Icon(Icons.person, color: AppColors.darkblue)),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Alena",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.darkblue)),
                    Text("Admin", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.darkblue),
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen())),
                )
              ],
            ),
            const SizedBox(height: 30),

            // Grafik Section
            _buildTitle("Grafik Peminjaman Alat Paling Banyak"),
            const SizedBox(height: 10),
            _buildChartMockup(),
            const SizedBox(height: 25),

            // Stats Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStockCard()),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(
                  children: [
                    _buildStatMiniCard("Total Alat Tersedia", "20",
                        Icons.inventory_2_outlined),
                    const SizedBox(height: 15),
                    _buildStatMiniCard(
                        "Total Alat Dipinjam", "15", Icons.handyman_outlined),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helpers
  Widget _buildTitle(String text) {
    return Row(children: [
      Container(width: 15, height: 15, color: AppColors.darkblue),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.darkblue)),
    ]);
  }

  Widget _buildChartMockup() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: AppColors.inputBg, borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(40, "Gitar"),
            _bar(80, "Monitor"),
            _bar(50, "Proyektor"),
            _bar(100, "Kamera"),
            _bar(70, "Laptop"),
          ],
        ),
      ),
    );
  }

  Widget _bar(double h, String l) =>
      Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
            width: 20,
            height: h,
            decoration: BoxDecoration(
                color: AppColors.darkblue,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 5),
        Text(l,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      ]);

  Widget _buildStockCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("List Alat Stok Menipis",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.darkblue)),
        const Divider(color: Colors.white),
        _stockItem("1. Monitor", "5"),
        _stockItem("2. Keyboard", "2"),
        _stockItem("3. Laptop", "3"),
      ]),
    );
  }

  Widget _stockItem(String n, String q) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(n, style: const TextStyle(fontSize: 10)),
          Text(q,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _buildStatMiniCard(String t, String v, IconData i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(i, size: 24, color: AppColors.darkblue),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          Text(v,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }
}

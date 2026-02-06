import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/login_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Instance supabase diambil dari inisialisasi di main.dart
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      // 1. Total Alat Tersedia (Menghitung baris di tabel 'alat')
      final alatRes = await supabase
          .from('alat')
          .select('id_alat');

      // 2. Total Alat Dipinjam (Berdasarkan status_transaksi di tabel 'peminjaman')
      // Sesuai skema: id_pinjam & status_transaksi
      final dipinjamRes = await supabase
          .from('peminjaman')
          .select('id_pinjam')
          .eq('status_transaksi', 'dipinjam'); // Pastikan string 'dipinjam' sesuai isi DB Anda

      // 3. List Alat Stok Menipis (Atribut: stok_total < 5)
      final stokMenipisRes = await supabase
          .from('alat')
          .select('nama_alat, stok_total')
          .lt('stok_total', 4)
          .order('stok_total', ascending: true)
          .limit(4);

      // 4. Data Grafik (Placeholder: Anda bisa menghubungkan ini ke view/statistik DB nanti)
      final grafikData = [
        {'label': 'Gitar', 'value': 10.0},
        {'label': 'Monitor', 'value': 15.0},
        {'label': 'Proyektor', 'value': 10.0},
        {'label': 'Kamera', 'value': 20.0},
        {'label': 'Laptop', 'value': 15.0},
      ];

      return {
        'tersedia': alatRes.length,
        'dipinjam': dipinjamRes.length,
        'stok_list': stokMenipisRes,
        'grafik': grafikData,
      };
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
      return {
        'tersedia': 0,
        'dipinjam': 0,
        'stok_list': [],
        'grafik': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {
          'tersedia': 0,
          'dipinjam': 0,
          'stok_list': [],
          'grafik': [],
        };

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 25),
                _buildSectionTitle("Grafik Peminjamann Alat Paling Banyak"),
                const SizedBox(height: 10),
                
                // Grafik dengan Garis Bantu Horizontal
                _buildChartContainer(data['grafik']),
                const SizedBox(height: 25),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sisi Kiri: List Stok Menipis (Menggunakan stok_total)
                    Expanded(
                      child: _buildInfoBox(
                        child: Column(
                          children: [
                            const Text("List Alat Stok\nMenipis", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkblue)),
                            const SizedBox(height: 10),
                            const Divider(color: Colors.white, thickness: 2),
                            if (data['stok_list'].isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Semua stok aman", style: TextStyle(fontSize: 10)),
                              )
                            else
                              ...List.generate(data['stok_list'].length, (index) {
                                final item = data['stok_list'][index];
                                return _buildStockRow("${index + 1}. ${item['nama_alat']}", "${item['stok_total']}");
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Sisi Kanan: Total Statistik
                    Expanded(
                      child: Column(
                        children: [
                          _buildStatCard("Total Alat\nTersedia", "${data['tersedia']}", Icons.inventory_2_outlined),
                          const SizedBox(height: 15),
                          _buildStatCard("Total Alat\nDipinjam", "${data['dipinjam']}", Icons.handyman_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildLogButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFD1E4F3),
          child: Icon(Icons.person_outline, color: AppColors.darkblue, size: 30),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alena", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkblue)),
            Text("Admin", style: TextStyle(fontSize: 12, color: AppColors.darkblue)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          icon: const Icon(Icons.logout, color: AppColors.darkblue),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 15, height: 15, color: AppColors.darkblue),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildChartContainer(List grafik) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E4F3),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Stack(
        children: [
          // Garis Horizontal & Label Angka (0 - 25 sesuai gambar terbaru)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [25, 20, 15, 10, 5, 0].map((val) {
              return Row(
                children: [
                  SizedBox(width: 20, child: Text("$val", style: const TextStyle(fontSize: 9, color: Colors.black54))),
                  const Expanded(child: Divider(color: Colors.black26, thickness: 0.5)),
                ],
              );
            }).toList(),
          ),
          // Batang Grafik
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: grafik.map<Widget>((g) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 25,
                      height: (g['value'] as double) * 6, // Scaling height
                      decoration: BoxDecoration(
                        color: AppColors.darkblue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(g['label'], style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E4F3),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildStockRow(String name, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              Text(qty, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            ],
          ),
          const Divider(color: Colors.white, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon) {
    return _buildInfoBox(
      child: Row(
        children: [
          Icon(icon, size: 30, color: AppColors.darkblue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkblue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E4F3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: const Row(
        children: [
          Text("Log Aktivitas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkblue)),
          Spacer(),
          Icon(Icons.chevron_right, color: AppColors.darkblue),
        ],
      ),
    );
  }
}
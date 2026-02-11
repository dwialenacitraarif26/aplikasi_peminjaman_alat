import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePetugasTab extends StatefulWidget {
  const HomePetugasTab({super.key});

  @override
  State<HomePetugasTab> createState() => _HomePetugasTabState();
}

class _HomePetugasTabState extends State<HomePetugasTab> {
  final supabase = Supabase.instance.client;

  // Fungsi mengambil ringkasan angka dari database
  Future<Map<String, int>> _getSummaryStats() async {
    try {
      // Ambil semua data peminjaman untuk dihitung manual agar lebih akurat
      final response = await supabase
          .from('peminjaman')
          .select('status_transaksi');

      final data = response as List;
      
      int permintaan = data.where((item) => item['status_transaksi'] == 'menunggu').length;
      int aktif = data.where((item) => item['status_transaksi'] == 'dipinjam').length;

      return {
        'permintaan': permintaan,
        'aktif': aktif,
      };
    } catch (e) {
      debugPrint("Error Summary Stats: $e");
      return {'permintaan': 0, 'aktif': 0};
    }
  }

  // 2. Ambil List Pinjaman Aktif (JOIN User & Detail Peminjaman)
  Future<List<Map<String, dynamic>>> _getActiveLoans() async {
    try {
      // Pastikan nama tabel relasi sesuai (users, detail_peminjaman, alat)
      final response = await supabase
          .from('peminjaman')
          .select('''
            id_pinjam,
            status_transaksi,
            tenggat,
            users (nama),
            detail_peminjaman (
              jumlah,
              alat (nama_alat)
            )
          ''')
          // Mengambil yang statusnya 'dipinjam' atau 'terlambat'
          .or('status_transaksi.eq.dipinjam,status_transaksi.eq.terlambat')
          .order('id_pinjam', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Cek error di Debug Console jika tabel/kolom tidak ditemukan
      debugPrint("Error Get Active Loans: $e");
      return [];
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),

                _buildSectionTitle("Ikhtisar Data"),
                const SizedBox(height: 15),
                
                // FutureBuilder untuk Statistik Angka
                FutureBuilder<Map<String, int>>(
                  future: _getSummaryStats(),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {'permintaan': 0, 'aktif': 0};
                    return Row(
                      children: [
                        Expanded(child: _buildStatCard("Permintaan", "${stats['permintaan']}", Icons.mail_outline, Colors.orange)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildStatCard("Pinjaman", "${stats['aktif']}", Icons.inventory_2_outlined, Colors.blue)),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                _buildSectionTitle("Alat Paling Sering Dipinjam"),
                const SizedBox(height: 15),
                _buildManualChart(),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle("Pinjaman Aktif"),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Lihat Detail", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                // FutureBuilder untuk Daftar Pinjaman Aktif
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getActiveLoans(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final loans = snapshot.data ?? [];
                    if (loans.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildActiveLoansList(loans);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Panel Petugas", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Pantau aktivitas inventaris hari ini", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: const Icon(Icons.dashboard_customize_rounded, color: Colors.blue),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)));
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildManualChart() {
    // Statis untuk sementara, bisa dikembangkan dengan query agregat
    final List<Map<String, dynamic>> tools = [
      {'name': 'Kamera DSLR', 'percent': 0.85, 'color': Colors.blue},
      {'name': 'Lensa Fix 50mm', 'percent': 0.65, 'color': Colors.indigo},
      {'name': 'Tripod Takara', 'percent': 0.40, 'color': Colors.cyan},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: tools.map((tool) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tool['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    Text("${(tool['percent'] * 100).toInt()}%", style: TextStyle(color: tool['color'], fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: tool['percent'],
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(tool['color']),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveLoansList(List<Map<String, dynamic>> loans) {
    return Column(
      children: loans.map((loan) {
        final status = loan['status_transaksi'].toString();
        final isLate = status == 'terlambat';
        final user = loan['users']?['nama'] ?? 'Unknown';
        final detail = loan['detail_peminjaman'] as List? ?? [];
        final alat = detail.isNotEmpty ? detail[0]['alat']['nama_alat'] : 'Alat';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isLate ? Colors.red.withOpacity(0.1) : Colors.transparent),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isLate ? Colors.red.shade50 : Colors.blue.shade50,
                child: Icon(isLate ? Icons.warning_rounded : Icons.person_outline, 
                           color: isLate ? Colors.red : Colors.blue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(alat, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isLate ? Colors.red : Colors.green.shade500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("Tidak ada pinjaman aktif", style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
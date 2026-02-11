import 'package:flutter/material.dart';
import 'package:peminjaman_alat/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RiwayatTab extends StatefulWidget {
  const RiwayatTab({super.key});

  @override
  State<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<RiwayatTab> {
  final supabase = Supabase.instance.client;

  // Query untuk mengambil data riwayat beserta relasi alat dan nama user
  Future<List<Map<String, dynamic>>> _getRiwayatTransaksi() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('peminjaman')
          .select('''
            id_pinjam, 
            pengambilan, 
            pengembalian, 
            tenggat, 
            status_transaksi,
            peminjam_id,
            users:peminjam_id(nama),
            detail_peminjaman(
              jumlah, 
              alat(nama_alat)
            )
          ''')
          .eq('peminjam_id', user.id)
          .filter('status_transaksi', 'in', '("selesai","terlambat")')
          .order('pengembalian', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Load Riwayat: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Text(
                "Riwayat Transaksi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getRiwayatTransaksi(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.history_rounded, size: 70, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text("Belum ada riwayat peminjaman", 
                                  style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return _buildRiwayatCard(data[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    final status = item['status_transaksi'].toString();
    final details = item['detail_peminjaman'] as List;
    final namaPeminjam = item['users']?['nama'] ?? "User";
    bool isTerlambat = status == 'terlambat';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Peminjam & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isTerlambat ? Colors.red.withOpacity(0.12) : AppColors.inputBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Color(0xFF0F172A)),
                const SizedBox(width: 8),
                Text(
                  namaPeminjam,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                _statusBadge(status, isTerlambat),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List Alat yang dipinjam
                ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(d['alat']['nama_alat'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text("${d['jumlah']} Unit", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                    ],
                  ),
                )).toList(),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                
                // Info Waktu: Grid Layout (Pinjam, Tenggat, Kembali)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _timeColumn("Pinjam", item['pengambilan']),
                    _timeColumn("Tenggat", item['tenggat']),
                    _timeColumn("Kembali", item['pengembalian'], isBold: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeColumn(String label, dynamic date, {bool isBold = false}) {
    String formatted = "-";
    if (date != null) {
      formatted = DateFormat('dd/MM/yy').format(DateTime.parse(date.toString()).toLocal());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          formatted, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? Colors.black : Colors.black87
          )
        ),
      ],
    );
  }

  Widget _statusBadge(String status, bool isTerlambat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTerlambat ? Colors.red : AppColors.darkblue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
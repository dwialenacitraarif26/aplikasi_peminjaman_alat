import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'detail_persetujuan_screen.dart';

class PersetujuanTab extends StatefulWidget {
  const PersetujuanTab({super.key});

  @override
  State<PersetujuanTab> createState() => _PersetujuanTabState();
}

class _PersetujuanTabState extends State<PersetujuanTab> {
  final supabase = Supabase.instance.client;
  bool _isProsesActive = true;

  Stream<List<Map<String, dynamic>>> persetujuanStream() {
    var query = supabase.from('peminjaman').stream(primaryKey: ['id_pinjam']);

    if (_isProsesActive) {
      return query
          .eq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
    } else {
      return query
          .neq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Daftar Persetujuan",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkblue),
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _tabButton("Proses", _isProsesActive, () => setState(() => _isProsesActive = true)),
                  const SizedBox(width: 10),
                  _tabButton("Riwayat", !_isProsesActive, () => setState(() => _isProsesActive = false)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: persetujuanStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(_isProsesActive ? "Tidak ada antrean" : "Riwayat kosong"));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data![index];
                        return _buildApprovalCard(data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPersetujuanScreen(loanData: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.darkblue, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _getNamaPeminjam(data['peminjam_id']?.toString()),
                const Text("Lihat detail >", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCol("Pengambilan", _formatTanggal(data['pengambilan']), subValue: _formatWaktu(data['pengambilan'])),
                _infoCol("Tenggat", _formatTanggal(data['tenggat']), subValue: _formatWaktu(data['tenggat'])),
                _infoCol("Alat", "", customChild: _getJumlahAlat(data['id_pinjam'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getJumlahAlat(dynamic idPinjam) {
    // PAKSA KONVERSI KE INT (int4 di Supabase)
    final cleanId = int.tryParse(idPinjam.toString()) ?? 0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('jumlah').eq('id_pinjam', cleanId),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) {
          for (var row in snapshot.data!) {
            total += (row['jumlah'] as int? ?? 0);
          }
        }
        return Text("$total", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkblue));
      },
    );
  }

  // ... (Gunakan fungsi format tanggal/waktu/tabButton/searchBar dari kode sebelumnya)
  Widget _tabButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isActive ? AppColors.darkblue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkblue),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.darkblue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkblue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.white),
          hintText: "Cari pengajuan...",
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _getNamaPeminjam(String? userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('users').select('nama').eq('id_user', userId ?? ''),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data![0]['nama']
            : "...";
        return Text(
          nama,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkblue),
        );
      },
    );
  }

  String _formatTanggal(String? dateStr) {
    if (dateStr == null) return "-";
    DateTime dt = DateTime.parse(dateStr);
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  String _formatWaktu(String? dateStr) {
    if (dateStr == null) return "-";
    DateTime dt = DateTime.parse(dateStr);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _infoCol(String label, String value, {String? subValue, Widget? customChild}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkblue, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        customChild ?? Text(value, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        if (subValue != null)
          Text(subValue, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
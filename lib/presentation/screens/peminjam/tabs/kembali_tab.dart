import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class PersetujuanPengembalianPetugas extends StatefulWidget {
  const PersetujuanPengembalianPetugas({super.key});

  @override
  State<PersetujuanPengembalianPetugas> createState() => _PersetujuanPengembalianPetugasState();
}

class _PersetujuanPengembalianPetugasState extends State<PersetujuanPengembalianPetugas> {
  final supabase = Supabase.instance.client;

  // Stream mengambil data dengan status 'kembali' (antrean pengembalian)
  Stream<List<Map<String, dynamic>>> _getAntreanKembali() {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .eq('status_transaksi', 'kembali')
        .order('pengembalian', ascending: false);
  }

  Future<void> _setujuiPengembalian(Map<String, dynamic> data) async {
    try {
      final int idPinjam = int.tryParse(data['id_pinjam'].toString()) ?? 0;
      final DateTime tenggat = DateTime.parse(data['tenggat']);
      final DateTime sekarang = DateTime.now();

      // Logika: Jika sekarang belum lewat tenggat, status langsung 'selesai'
      // Jika lewat, bisa diarahkan ke status 'terlambat' atau denda (opsional)
      String statusBaru = 'selesai';
      if (sekarang.isAfter(tenggat)) {
        statusBaru = 'selesai'; // Tetap selesai, tapi nanti bisa ditambah logika denda
      }

      await supabase.from('peminjaman').update({
        'status_transaksi': statusBaru,
        'pengembalian': sekarang.toIso8601String(),
        'petugas_id': supabase.auth.currentUser?.id,
      }).eq('id_pinjam', idPinjam);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Peminjaman #$idPinjam telah Selesai"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error Approval: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Persetujuan Kembali", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAntreanKembali(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada antrean pengembalian"));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildReturnCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.darkblue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fetchNamaUser(data['peminjam_id']),
              const Text("Status: Kembali", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          _buildAlatListDetail(int.tryParse(data['id_pinjam'].toString()) ?? 0),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { /* Logika Tolak/Cek Alat Rusak */ },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  child: const Text("Bermasalah", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _setujuiPengembalian(data),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue),
                  child: const Text("Setujui Selesai", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Widget mengambil nama user
  Widget _fetchNamaUser(String? userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('users').select('nama').eq('id_user', userId ?? ''),
      builder: (context, snapshot) {
        final nama = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data![0]['nama'] : "...";
        return Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue));
      },
    );
  }

  // Widget daftar alat
  Widget _buildAlatListDetail(int idPinjam) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('jumlah, alat(nama_alat)').eq('id_pinjam', idPinjam),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(
          children: snapshot.data!.map((d) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d['alat']['nama_alat'], style: const TextStyle(fontSize: 13)),
              Text("${d['jumlah']} Unit"),
            ],
          )).toList(),
        );
      },
    );
  }
}
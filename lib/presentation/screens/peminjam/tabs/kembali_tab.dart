import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class KembaliTab extends StatefulWidget {
  final int? selectedIdPinjam; 
  const KembaliTab({super.key, this.selectedIdPinjam});

  @override
  State<KembaliTab> createState() => _KembaliTabState();
}

class _KembaliTabState extends State<KembaliTab> {
  final supabase = Supabase.instance.client;

  void _backToHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      DefaultTabController.of(context).animateTo(0);
    }
  }

  Future<void> _prosesPengembalian(int idPinjam) async {
    try {
      await supabase.from('peminjaman').update({
        'status_transaksi': 'kembali' 
      }).eq('id_pinjam', idPinjam);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil diajukan! Menunggu persetujuan petugas."))
        );
        // LANGSUNG BALIK KE HALAMAN SEBELUMNYA
        Navigator.pop(context); 
      }
    } catch (e) {
      debugPrint("Gagal update: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedIdPinjam == null) {
      return const Scaffold(
        body: Center(child: Text("Pilih transaksi aktif terlebih dahulu")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
          onPressed: _backToHome,
        ),
        title: const Text(
          "Sedang Dipinjam",
          style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('peminjaman').stream(primaryKey: ['id_pinjam']).eq('id_pinjam', widget.selectedIdPinjam!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final data = snapshot.data![0];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlatList(data['id_pinjam']),
                const Divider(height: 40, thickness: 1),
                FutureBuilder<String>(
                  future: _getNamaPeminjam(data['peminjam_id']),
                  builder: (context, nameSnapshot) => 
                    _buildFieldGroup("Nama", nameSnapshot.data ?? "..."),
                ),
                _buildTotalJumlah(data['id_pinjam']),
                const Text("Pengambilan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkblue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildInputBox(_formatDate(data['pengambilan']), icon: Icons.calendar_month_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputBox(_formatTime(data['pengambilan']), icon: Icons.history)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("Tenggat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkblue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildInputBox(_formatDate(data['tenggat']), icon: Icons.calendar_month_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputBox(_formatTime(data['tenggat']), icon: Icons.history)),
                  ],
                ),
                const SizedBox(height: 35),
                if (data['status_transaksi'] == 'pinjam')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _prosesPengembalian(data['id_pinjam']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Ajukan Pengembalian", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange)
                    ),
                    child: const Text(
                      "Status: Menunggu Persetujuan",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlatList(int idPinjam) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('jumlah, alat(nama_alat, foto_url, kategori(nama_kategori))').eq('id_pinjam', idPinjam),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(
          children: snapshot.data!.map((item) {
            final alat = item['alat'] as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3F6FF), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(alat['foto_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alat['nama_alat'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 16)),
                        Text(alat['kategori']['nama_kategori'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("${item['jumlah']} Unit", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFieldGroup(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkblue)),
        const SizedBox(height: 8),
        _buildInputBox(value),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildInputBox(String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: AppColors.darkblue), const SizedBox(width: 10)],
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalJumlah(int idPinjam) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('jumlah').eq('id_pinjam', idPinjam),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) {
          for (var item in snapshot.data!) { total += (item['jumlah'] as num).toInt(); }
        }
        return _buildFieldGroup("Jumlah", total.toString());
      },
    );
  }

  Future<String> _getNamaPeminjam(String userId) async {
    final res = await supabase.from('users').select('nama').eq('id_user', userId).maybeSingle();
    return res?['nama'] ?? "User";
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "-";
    DateTime dt = DateTime.parse(dateStr.toString());
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return "-";
    DateTime dt = DateTime.parse(dateStr.toString());
    return "${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}";
  }
}
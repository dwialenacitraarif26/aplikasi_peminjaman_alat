import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class DetailAlatScreen extends StatelessWidget {
  final Map<String, dynamic> alat;
  const DetailAlatScreen({super.key, required this.alat});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Alat", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.darkblue)),
      ),
      body: SingleChildScrollView( // Tambahkan scroll agar aman di layar kecil
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Box Gambar (Sekarang Bersih Tanpa Kotak Biru)
            Container(
              height: 250,
              width: double.infinity,
              // Kita hapus BoxDecoration yang ada warnanya tadi
              child: (alat['foto_url'] != null && alat['foto_url'].toString().isNotEmpty)
                ? Image.network(
                    alat['foto_url'], 
                    fit: BoxFit.contain,
                  )
                : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            _infoRow("Nama", alat['nama_alat'] ?? "-"),
            _infoRow("Stok", "${alat['stok_total'] ?? 0}"),
            
            // Ambil nama kategori secara async berdasarkan id
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('kategori').select().eq('id_kategori', alat['kategori_id'] ?? 0),
              builder: (context, snapshot) {
                String namaKategori = (snapshot.hasData && snapshot.data!.isNotEmpty) 
                    ? snapshot.data![0]['nama_kategori'] 
                    : "Memuat...";
                return _infoRow("Kategori", namaKategori);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E4F3).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 16))),
          const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 16))),
        ],
      ),
    );
  }
}
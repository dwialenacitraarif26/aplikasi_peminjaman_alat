import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'detail_persetujuan_kembali.dart'; // Import halaman detail yang kita buat di bawah

class PengembalianPetugasTab extends StatefulWidget {
  const PengembalianPetugasTab({super.key});

  @override
  State<PengembalianPetugasTab> createState() => _PengembalianPetugasTabState();
}

class _PengembalianPetugasTabState extends State<PengembalianPetugasTab> {
  final supabase = Supabase.instance.client;
  String _activeTab = "Pengajuan"; 
  String _searchQuery = "";

  Stream<List<Map<String, dynamic>>> _getPengembalianStream() {
    String statusFilter = (_activeTab == "Pengajuan") ? 'kembali' : 'selesai';
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .eq('status_transaksi', statusFilter)
        .order('pengambilan', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("Daftar Pengembalian", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.darkblue, borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.white),
                    hintText: "search...",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // TAB FILTER (Warna Darkblue saat aktif + Garis Luar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton("Pengajuan")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildTabButton("Riwayat")),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIST CARD
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getPengembalianStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) return Center(child: Text("Tidak ada data $_activeTab"));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.length,
                    itemBuilder: (context, index) => _buildCard(data[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isActive = _activeTab == label;
    return SizedBox(
      height: 45,
      child: ElevatedButton(
        onPressed: () => setState(() => _activeTab = label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.darkblue : Colors.white,
          // Garis Luar Darkblue
          side: const BorderSide(color: AppColors.darkblue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: TextStyle(
          color: isActive ? Colors.white : AppColors.darkblue,
          fontWeight: FontWeight.bold
        )),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkblue.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigasi ke Halaman Input Tanggal (Detail)
          Navigator.push(context, MaterialPageRoute(builder: (context) => 
            DetailPersetujuanKembali(loan: loan)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<Map<String, dynamic>?>(
                    future: supabase.from('users').select('nama').eq('id_user', loan['peminjam_id']).maybeSingle(),
                    builder: (context, res) => Text(
                      res.data?['nama'] ?? "Loading...",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkblue),
                    ),
                  ),
                  const Text("Lihat detail >", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn("Pengambilan", _formatDateTime(loan['pengambilan'])),
                  _buildInfoColumn("Tenggat", _formatDateTime(loan['tenggat'])),
                  _buildInfoColumn("Alat", "...", idPinjam: loan['id_pinjam']),
                ],
              ),
              const SizedBox(height: 20),

              // STATUS BADGE (Bukan Tombol)
              if (_activeTab == "Pengajuan")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4D8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8B9433).withOpacity(0.5))
                  ),
                  child: const Text("Menunggu Pengembalian", 
                    style: TextStyle(color: Color(0xFF8B9433), fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8FF),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: const Text("Selesai", 
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {int? idPinjam}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkblue)),
        const SizedBox(height: 4),
        idPinjam != null 
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('detail_peminjaman').select('jumlah').eq('id_pinjam', idPinjam),
              builder: (context, snapshot) {
                int total = 0;
                if (snapshot.hasData) {
                  for (var i in snapshot.data!) { total += (i['jumlah'] as num).toInt(); }
                }
                return Text("$total", style: const TextStyle(fontSize: 12, color: AppColors.darkblue));
              },
            )
          : Text(value, style: const TextStyle(fontSize: 10, color: AppColors.darkblue)),
      ],
    );
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return "-";
    DateTime dt = DateTime.parse(dateStr.toString());
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
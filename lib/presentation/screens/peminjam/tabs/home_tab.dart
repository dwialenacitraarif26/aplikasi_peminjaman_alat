import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../tabs/kembali_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabPeminjamState();
}

class _HomeTabPeminjamState extends State<HomeTab> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  // 1. STREAM DATA (Realtime dari Supabase)
  Stream<List<Map<String, dynamic>>> myLoansStream() {
    final userId = supabase.auth.currentUser?.id;
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .eq('peminjam_id', userId ?? '')
        .order('pengambilan', ascending: false);
  }

  // 2. LOGIKA FILTER & SORTIR
  Future<List<Map<String, dynamic>>> _filterDanSortirData(List<Map<String, dynamic>> rawData) async {
    // Status yang dianggap masih aktif di halaman Home
    const statusAktif = ["pinjam", "kembali", "ditolak", "menunggu"];
    
    List<Map<String, dynamic>> filteredByStatus = rawData.where((loan) {
      return statusAktif.contains(loan['status_transaksi']);
    }).toList();

    if (_searchQuery.isEmpty) return filteredByStatus;

    final q = _searchQuery.toLowerCase();
    return filteredByStatus.where((loan) {
      String statusLabel = _mapStatusLabel(loan['status_transaksi'] ?? '');
      String tanggal = _formatTanggal(loan['tenggat']);
      return statusLabel.toLowerCase().contains(q) || tanggal.contains(q);
    }).toList();
  }

  // 3. DIALOG ALASAN PENOLAKAN
  void _showAlasanDialog(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text("Peminjaman Ditolak", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pesan dari Petugas:", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100)
              ),
              child: Text(
                loan['alasan_tolak'] ?? "Tidak ada alasan spesifik dari petugas.",
                style: TextStyle(fontSize: 14, color: Colors.red.shade900, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkblue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () async {
                  try {
                    // Update ke 'selesai' agar hilang dari Home & muncul di Riwayat
                    await supabase
                        .from('peminjaman')
                        .update({'status_transaksi': 'selesai'})
                        .eq('id_pinjam', loan['id_pinjam']);

                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Error update: $e");
                  }
                },
                child: const Text("SAYA MENGERTI", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 25),
              const Text("Pinjaman Aktif", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkblue)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: myLoansStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _filterDanSortirData(snapshot.data!),
                      builder: (context, filteredSnapshot) {
                        if (filteredSnapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                        
                        final listTampil = filteredSnapshot.data ?? [];
                        if (listTampil.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          itemCount: listTampil.length,
                          itemBuilder: (context, index) => _buildLoanCard(listTampil[index]),
                        );
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

  // --- UI WIDGETS ---

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    String status = loan['status_transaksi'] ?? 'menunggu';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: status == 'ditolak' ? Colors.red.shade100 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (status == 'ditolak') {
            _showAlasanDialog(loan);
          } else if (status == 'kembali') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menunggu persetujuan petugas"), backgroundColor: Colors.orange));
          } else if (status == 'pinjam') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => KembaliTab(selectedIdPinjam: loan['id_pinjam'])));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: status == 'ditolak' ? Colors.red : AppColors.darkblue, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getNamaUser(loan['peminjam_id']),
                    Text("Tenggat: ${_formatTanggal(loan['tenggat'])}", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              _statusBadge(status),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _mapStatusLabel(String status) {
    switch (status) {
      case 'pinjam': return "Dipinjam";
      case 'kembali': return "Kembali";
      case 'ditolak': return "Ditolak";
      default: return "Menunggu";
    }
  }

  Widget _statusBadge(String status) {
    Color bgColor; Color textColor;
    switch (status) {
      case 'pinjam': bgColor = const Color(0xFFE8F5E9); textColor = const Color(0xFF2E7D32); break;
      case 'ditolak': bgColor = Colors.red.shade50; textColor = Colors.red.shade900; break;
      case 'kembali': bgColor = const Color(0xFFFFF3E0); textColor = const Color(0xFFE65100); break;
      default: bgColor = const Color(0xFFF5F5F5); textColor = const Color(0xFF616161);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(_mapStatusLabel(status), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() => const Center(child: Padding(
    padding: EdgeInsets.only(top: 50),
    child: Text("Tidak ada aktivitas aktif", style: TextStyle(color: Colors.grey)),
  ));

  Widget _buildHeader() {
    final userId = supabase.auth.currentUser?.id;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('users').select('nama').eq('id_user', userId ?? '').limit(1),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data![0]['nama'] : "Peminjam";
        return Row(
          children: [
            const CircleAvatar(radius: 25, backgroundColor: AppColors.darkblue, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Halo, $nama", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Peminjam", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: "Cari pinjaman aktif...",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _getNamaUser(String? userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('users').select('nama').eq('id_user', userId ?? '').limit(1),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data![0]['nama'] : "...";
        return Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
      },
    );
  }

  String _formatTanggal(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) { return dateStr; }
  }
}
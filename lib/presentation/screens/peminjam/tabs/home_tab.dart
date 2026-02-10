import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabPeminjamState();
}

class _HomeTabPeminjamState extends State<HomeTab> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  // Stream utama untuk memantau peminjaman
  Stream<List<Map<String, dynamic>>> myLoansStream() {
    final userId = supabase.auth.currentUser?.id;
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .eq('peminjam_id', userId ?? '')
        .order('pengambilan', ascending: false);
  }

  // Fungsi sakti untuk mengambil data relasi (Nama User) secara async untuk filter
  Future<String> _getNamaSync(String id) async {
    final res = await supabase
        .from('users')
        .select('nama')
        .eq('id_user', id)
        .maybeSingle();
    return res?['nama'] ?? "";
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: myLoansStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text("Tidak ada aktivitas pinjaman"));
                    }

                    // Gunakan FutureBuilder di dalam Stream untuk filter berdasarkan Nama (Async)
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _filterData(snapshot.data!),
                      builder: (context, filteredSnapshot) {
                        if (!filteredSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final listTampil = filteredSnapshot.data!;

                        if (listTampil.isEmpty) {
                          return const Center(
                              child: Text("Data tidak ditemukan"));
                        }

                        return ListView.builder(
                          itemCount: listTampil.length,
                          itemBuilder: (context, index) =>
                              _buildLoanCard(listTampil[index]),
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

  // LOGIKA FILTER GLOBAL (Mencari di semua field)
  Future<List<Map<String, dynamic>>> _filterData(
      List<Map<String, dynamic>> rawData) async {
    if (_searchQuery.isEmpty) return rawData;

    List<Map<String, dynamic>> filtered = [];
    final q = _searchQuery.toLowerCase();

    for (var loan in rawData) {
      // 1. Ambil Nama User untuk dicek
      String namaPeminjam = await _getNamaSync(loan['peminjam_id']);

      // 2. Ambil Label Status
      String statusLabel = _mapStatusLabel(loan['status_transaksi'] ?? '');

      // 3. Ambil Tanggal
      String tanggal = _formatTanggal(loan['tenggat']);

      // Cek apakah query ada di Nama, Status, atau Tanggal
      if (namaPeminjam.toLowerCase().contains(q) ||
          statusLabel.toLowerCase().contains(q) ||
          tanggal.contains(q)) {
        filtered.add(loan);
      }
    }
    return filtered;
  }

  String _mapStatusLabel(String status) {
    switch (status) {
      case 'pinjam':
        return "Dipinjam";
      case 'ditolak':
        return "Ditolak";
      case 'kembali':
        return "Selesai";
      default:
        return "Menunggu";
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkblue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white70),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = "");
                  })
              : null,
          hintText: "search...",
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Widget pendukung lainnya (Header, Card, dll) tetap sama seperti sebelumnya
  Widget _getNamaUser(String? userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId ?? '')
          .limit(1),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data![0]['nama']
            : "...";
        return Text(nama,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
      },
    );
  }

  Widget _buildHeader() {
    final userId = supabase.auth.currentUser?.id;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId ?? '')
          .limit(1),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data![0]['nama']
            : "Peminjam";

        return Row(
          children: [
            // Avatar minimalis tanpa background
            const Icon(
              Icons.account_circle_outlined, // Icon outline yang bersih
              color: AppColors.darkblue, // Warna utama aplikasi kamu
              size: 55, // Ukuran pas untuk header
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "Peminjam",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    String status = loan['status_transaksi'] ?? 'menunggu';
    return GestureDetector(
      onTap: () {
        if (status == 'ditolak') {
          _showRejectReasonDialog(
              loan['alasan_penolakan'] ?? 'Tidak ada alasan spesifik.');
        } else if (status == 'pinjam') {
          // Navigasi ke Halaman Pengembalian
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: AppColors.darkblue, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getNamaUser(loan['peminjam_id']),
                  Text("Tenggat: ${_formatTanggal(loan['tenggat'])}",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            _statusBadge(status),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'pinjam':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'ditolak':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(_mapStatusLabel(status),
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showRejectReasonDialog(String alasan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon Penolakan yang mencolok
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, size: 50, color: Colors.red),
            ),
            const SizedBox(height: 15),

            // Judul Dialog
            const Text(
              "Pengajuan Ditolak",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),

            // Isi Alasan
            Text(
              alasan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 25),

            // Tombol Oke yang lebar dan memenuhi bawah
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkblue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Oke",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }
}

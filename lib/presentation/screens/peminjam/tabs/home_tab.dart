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

  Stream<List<Map<String, dynamic>>> myLoansStream() {
    final userId = supabase.auth.currentUser?.id;
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .eq('peminjam_id', userId ?? '')
        .order('pengambilan', ascending: false);
  }

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
                      return const Center(child: Text("Tidak ada aktivitas pinjaman"));
                    }

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _filterData(snapshot.data!),
                      builder: (context, filteredSnapshot) {
                        if (!filteredSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final listTampil = filteredSnapshot.data!;
                        if (listTampil.isEmpty) {
                          return const Center(child: Text("Data tidak ditemukan"));
                        }

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

  Future<List<Map<String, dynamic>>> _filterData(List<Map<String, dynamic>> rawData) async {
    if (_searchQuery.isEmpty) return rawData;
    List<Map<String, dynamic>> filtered = [];
    final q = _searchQuery.toLowerCase();

    for (var loan in rawData) {
      String namaPeminjam = await _getNamaSync(loan['peminjam_id']);
      String statusLabel = _mapStatusLabel(loan['status_transaksi'] ?? '');
      String tanggal = _formatTanggal(loan['tenggat']);

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
    case 'pinjam': return "Dipinjam";
    case 'kembali': return "Menunggu";
    case 'selesai': return "Selesai";
    case 'terlambat': return "Terlambat"; // Tambahkan ini
    case 'ditolak': return "Ditolak";
    default: return "Menunggu";
  }
}

// 2. Update Badge Warna untuk status 'terlambat' dan 'selesai'
Widget _statusBadge(String status) {
  Color bgColor;
  Color textColor;
  switch (status) {
    case 'pinjam':
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      break;
    case 'terlambat': // Tambahkan warna merah untuk terlambat
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      break;
    case 'ditolak':
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      break;
    case 'selesai': // Tambahkan warna biru/hijau untuk selesai
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1565C0);
      break;
    case 'kembali':
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      break;
    default:
      bgColor = const Color(0xFFF5F5F5);
      textColor = const Color(0xFF616161);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
    child: Text(_mapStatusLabel(status),
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// 3. Update Fungsi onTap pada Card agar bisa melihat alasan ditolak
Widget _buildLoanCard(Map<String, dynamic> loan) {
  String status = loan['status_transaksi'] ?? 'menunggu';
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: status == 'ditolak' ? Colors.red.shade100 : Colors.grey.shade200),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        if (status == 'ditolak') {
          // TAMPILKAN ALASAN PENOLAKAN
          _showAlasanDialog(loan['alasan_tolak'] ?? "Tidak ada alasan spesifik.");
        } else if (status == 'kembali') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menunggu persetujuan petugas untuk pengembalian ini"), backgroundColor: Colors.orange),
          );
        } else if (status == 'pinjam') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KembaliTab(selectedIdPinjam: loan['id_pinjam'])),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, 
                 color: status == 'terlambat' ? Colors.red : AppColors.darkblue, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getNamaUser(loan['peminjam_id']),
                  Text("Tenggat: ${_formatTanggal(loan['tenggat'])}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
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

// 4. Fungsi Dialog Alasan (Pindahkan dari kode sebelumnya)
void _showAlasanDialog(String alasan) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Peminjaman Ditolak", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text("Alasan: $alasan"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
      ],
    ),
  );
}

  Widget _buildHeader() {
    final userId = supabase.auth.currentUser?.id;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('users').select('nama').eq('id_user', userId ?? '').limit(1),
      builder: (context, snapshot) {
        String nama = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data![0]['nama'] : "Peminjam";
        return Row(
          children: [
            const Icon(Icons.account_circle_outlined, color: AppColors.darkblue, size: 55),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: AppColors.darkblue, borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white),
          hintText: "search...",
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.cancel, color: Colors.white70), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ""); }) 
            : null,
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
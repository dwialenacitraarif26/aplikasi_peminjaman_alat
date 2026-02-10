import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RincianDendaScreen extends StatefulWidget {
  const RincianDendaScreen({super.key});

  @override
  State<RincianDendaScreen> createState() => _RincianDendaScreenState();
}

class _RincianDendaScreenState extends State<RincianDendaScreen> {
  final supabase = Supabase.instance.client;
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  late String _selectedDayValue;

  @override
  void initState() {
    super.initState();
    // Default ke hari ini
    _selectedDayValue = _getNamaHari(DateTime.now());
  }

  String _getNamaHari(DateTime date) {
    const mapHari = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'};
    return mapHari[date.weekday] ?? '';
  }

  int _hitungKeterlambatan(dynamic tglKembali, dynamic tglTenggat) {
    if (tglKembali == null || tglTenggat == null) return 0;
    try {
      DateTime kembali = DateTime.parse(tglKembali.toString());
      DateTime tenggat = DateTime.parse(tglTenggat.toString());
      int selisih = kembali.difference(tenggat).inDays;
      return selisih > 0 ? selisih : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _getDendaData() async {
    try {
      final response = await supabase
          .from('denda')
          .select('''
            *,
            peminjaman:id_kembali (
              pengembalian,
              tenggat,
              users!peminjam_id (nama)
            )
          ''');

      final allData = List<Map<String, dynamic>>.from(response);
      
      DateTime sekarang = DateTime.now();
      // Cari tanggal Senin minggu ini
      DateTime seninMingguIni = sekarang.subtract(Duration(days: sekarang.weekday - 1));
      seninMingguIni = DateTime(seninMingguIni.year, seninMingguIni.month, seninMingguIni.day);

      // Filter: Hanya yang terjadi di MINGGU INI dan sesuai HARI yang dipilih
      return allData.where((item) {
        final pinjam = item['peminjaman'];
        if (pinjam == null || pinjam['pengembalian'] == null) return false;

        DateTime tglKembaliLocal = DateTime.parse(pinjam['pengembalian'].toString()).toLocal();
        
        // Syarat 1: Harus di minggu ini (mulai dari senin)
        bool isMingguIni = tglKembaliLocal.isAfter(seninMingguIni.subtract(const Duration(seconds: 1)));
        
        // Syarat 2: Harinya harus pas dengan tab yang diklik
        bool isHariYangSama = _getNamaHari(tglKembaliLocal) == _selectedDayValue;

        return isMingguIni && isHariYangSama;
      }).toList();
    } catch (e) {
      debugPrint("Kesalahan Database: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Denda Minggu Ini", 
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          // Filter Tab Hari (Hanya untuk minggu berjalan)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedDayValue == _days[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDayValue = _days[index]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300
                          ),
                        ),
                        child: Center(
                          child: Text(_days[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13
                            )),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getDendaData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? [];
                double totalDenda = data.fold(0, (sum, item) => sum + (double.tryParse(item['total_denda'].toString()) ?? 0));

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Tidak ada denda hari $_selectedDayValue\ndi minggu ini", 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final pinjam = item['peminjaman'];
                          final namaPeminjam = pinjam?['users']?['nama'] ?? "User #${item['id_kembali']}";
                          int hariTerlambat = _hitungKeterlambatan(pinjam?['pengembalian'], pinjam?['tenggat']);

                          return _buildCardDenda(namaPeminjam, hariTerlambat, item['total_denda']);
                        },
                      ),
                    ),
                    _buildTotalFooter(totalDenda),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDenda(String nama, int hari, dynamic nominal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : "?", 
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Terlambat $hari Hari", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(nominal ?? 0),
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Harian", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          Text(
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(total),
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
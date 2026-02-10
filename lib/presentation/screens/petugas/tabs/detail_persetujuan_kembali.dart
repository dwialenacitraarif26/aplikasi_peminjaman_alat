import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class DetailPersetujuanKembali extends StatefulWidget {
  final Map<String, dynamic> loan; 
  const DetailPersetujuanKembali({super.key, required this.loan});

  @override
  State<DetailPersetujuanKembali> createState() => _DetailPersetujuanKembaliState();
}

class _DetailPersetujuanKembaliState extends State<DetailPersetujuanKembali> {
  final supabase = Supabase.instance.client;
  
  DateTime _tglKembali = DateTime.now();
  TimeOfDay _jamKembali = TimeOfDay.now();
  int _totalDenda = 0;
  int _selisihHari = 0;
  int _tarifPerHari = 10000; // Sesuai dengan screenshot database kamu
  String _deskripsi = "Tepat waktu";
  bool _isLate = false;

  @override
  void initState() {
    super.initState();
    _hitungDenda();
  }

  void _hitungDenda() {
    DateTime tenggat = DateTime.parse(widget.loan['tenggat'].toString());
    
    // Bandingkan berdasarkan tanggal saja (Year, Month, Day)
    DateTime tglTenggatOnly = DateTime(tenggat.year, tenggat.month, tenggat.day);
    DateTime tglKembaliOnly = DateTime(_tglKembali.year, _tglKembali.month, _tglKembali.day);

    if (tglKembaliOnly.isAfter(tglTenggatOnly)) {
      _selisihHari = tglKembaliOnly.difference(tglTenggatOnly).inDays;
      setState(() {
        _isLate = true;
        _totalDenda = _selisihHari * _tarifPerHari;
        _deskripsi = "Terlambat $_selisihHari hari";
      });
    } else {
      setState(() {
        _selisihHari = 0;
        _isLate = false;
        _totalDenda = 0;
        _deskripsi = "Tepat waktu";
      });
    }
  }

  Future<void> _konfirmasiKembali() async {
  final DateTime finalDateTime = DateTime(
    _tglKembali.year, _tglKembali.month, _tglKembali.day,
    _jamKembali.hour, _jamKembali.minute,
  );

  // Pastikan logika denda dihitung ulang satu kali lagi sebelum simpan
  _hitungDenda(); 

  try {
    // 1. Tentukan status secara eksplisit
    String statusFinal = _isLate ? 'terlambat' : 'selesai';

    // 2. UPDATE TABEL PEMINJAMAN
    await supabase.from('peminjaman').update({
      'status_transaksi': statusFinal, // Menggunakan statusFinal (terlambat/selesai)
      'pengembalian': finalDateTime.toIso8601String(),
    }).eq('id_pinjam', widget.loan['id_pinjam']);

    // 3. INSERT KE TABEL DENDA (Hanya jika benar-benar terlambat)
    if (_isLate && _selisihHari > 0) {
      await supabase.from('denda').insert({
        'id_kembali': widget.loan['id_pinjam'],
        'tarif_per_hari': _tarifPerHari,
        'jumlah_terlambat': _selisihHari,
        // total_denda tidak perlu karena Generated Column
      });
    }

    if (mounted) _showSuccessPopup();
  } catch (e) {
    debugPrint("Error Konfirmasi: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }
}
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 70, color: AppColors.darkblue),
            const SizedBox(height: 20),
            const Text(
              "PENGEMBALIAN TELAH\nBERHASIL",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkblue),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke daftar
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkblue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Tutup", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengembalian", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlatPreview(widget.loan['id_pinjam']),
            const Divider(height: 40),
            Row(
              children: [
                Expanded(child: _buildStaticField("Nama", widget.loan['peminjam_id'], isUser: true)),
                const SizedBox(width: 15),
                Expanded(child: _buildStaticField("Jumlah", widget.loan['id_pinjam'], isTotal: true)),
              ],
            ),
            const SizedBox(height: 15),
            _buildDateTimeRow("Pengambilan", widget.loan['pengambilan']),
            const SizedBox(height: 15),
            _buildDateTimeRow("Tenggat", widget.loan['tenggat']),
            const SizedBox(height: 15),
            
            const Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _tglKembali,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _tglKembali = picked);
                        _hitungDenda();
                      }
                    },
                    child: _buildInputBox("${_tglKembali.day}/${_tglKembali.month}/${_tglKembali.year}", icon: Icons.calendar_month),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final timePicked = await showTimePicker(context: context, initialTime: _jamKembali);
                      if (timePicked != null) {
                        setState(() => _jamKembali = timePicked);
                        _hitungDenda();
                      }
                    },
                    child: _buildInputBox("${_jamKembali.hour.toString().padLeft(2, '0')}.${_jamKembali.minute.toString().padLeft(2, '0')}", icon: Icons.history),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStaticField("Total Denda", "Rp$_totalDenda"),
            const SizedBox(height: 15),
            _buildStaticField("Deskripsi", _deskripsi),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _konfirmasiKembali,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Konfirmasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helpers (Tetap Sama) ---
  Widget _buildStaticField(String label, dynamic value, {bool isUser = false, bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)),
          child: isUser 
            ? FutureBuilder<Map<String, dynamic>?>(
                future: supabase.from('users').select('nama').eq('id_user', value).maybeSingle(),
                builder: (context, s) => Text(s.data?['nama'] ?? "Loading...", style: const TextStyle(fontSize: 13)),
              )
            : isTotal
            ? FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('detail_peminjaman').select('jumlah').eq('id_pinjam', value),
                builder: (context, s) {
                  int t = 0; if(s.hasData) { for(var i in s.data!) { t += (i['jumlah'] as num).toInt(); } }
                  return Text("$t", style: const TextStyle(fontSize: 13));
                }
              )
            : Text(value.toString(), style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(String label, String dateStr) {
    DateTime dt = DateTime.parse(dateStr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildInputBox("${dt.day}/${dt.month}/${dt.year}", icon: Icons.calendar_month)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputBox("${dt.hour.toString().padLeft(2,'0')}.${dt.minute.toString().padLeft(2,'0')}", icon: Icons.history)),
          ],
        ),
      ],
    );
  }

  Widget _buildInputBox(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.darkblue), const SizedBox(width: 10)],
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAlatPreview(int idPinjam) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('jumlah, alat(nama_alat, foto_url)').eq('id_pinjam', idPinjam),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return Column(
          children: snapshot.data!.map((item) {
            final alat = item['alat'] as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF3F6FF), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Image.network(alat['foto_url'], width: 50, height: 50, fit: BoxFit.cover),
                  const SizedBox(width: 15),
                  Expanded(child: Text(alat['nama_alat'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue))),
                  Text("${item['jumlah']} Unit", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
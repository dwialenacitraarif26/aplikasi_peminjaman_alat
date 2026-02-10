import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class DetailPersetujuanScreen extends StatefulWidget {
  final Map<String, dynamic> loanData;
  const DetailPersetujuanScreen({super.key, required this.loanData});

  @override
  State<DetailPersetujuanScreen> createState() => _DetailPersetujuanScreenState();
}

class _DetailPersetujuanScreenState extends State<DetailPersetujuanScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _reasonCtrl = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    DateTime dt = DateTime.parse(widget.loanData['tenggat']);
    selectedDate = dt;
    selectedTime = TimeOfDay.fromDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    // KONVERSI ID PINJAM KE INT UNTUK SUPABASE INT4
    final int idPinjam = int.tryParse(widget.loanData['id_pinjam'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.darkblue), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlatList(idPinjam), // Masukkan ID yang sudah jadi INT
            const SizedBox(height: 25),
            const Text("Nama Peminjam", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            _buildNamaBox(),
            const SizedBox(height: 20),
            _buildWaktuInfoCard(),
            const SizedBox(height: 25),
            const Text("Update Tenggat", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPickerField("${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}", Icons.calendar_today_outlined, _pickDate)),
                const SizedBox(width: 15),
                Expanded(child: _buildPickerField(selectedTime!.format(context), Icons.history, _pickTime)),
              ],
            ),
            const SizedBox(height: 40),
            _actionButton("Simpan Perubahan", AppColors.darkblue, Colors.white, () => _processApproval('pinjam')),
            const SizedBox(height: 12),
            _actionButton("Tolak Pengajuan", Colors.white, Colors.red, _showRejectDialog, isBordered: true),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAlatList(int idPinjam) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('detail_peminjaman').select('''
          jumlah, 
          alat (
            nama_alat, 
            foto_url,
            kategori:kategori_id (nama_kategori)
          )
        ''').eq('id_pinjam', idPinjam), // Gunakan INT
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Data alat tidak ditemukan (int4 mismatch?)");

        return Column(
          children: snapshot.data!.map((item) {
            final alat = item['alat'] as Map<String, dynamic>?;
            final namaAlat = alat?['nama_alat'] ?? "Tanpa Nama";
            final kategori = alat?['kategori']?['nama_kategori'] ?? "Umum";
            final fotoUrl = alat?['foto_url'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE9EEF9), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: (fotoUrl != null) 
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(fotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.monitor))) 
                        : const Icon(Icons.monitor, color: AppColors.darkblue),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaAlat, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
                        Text(kategori, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("${item['jumlah']} Unit", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ... (Gunakan fungsi _pickDate, _pickTime, _processApproval, _buildNamaBox, dll dari kode sebelumnya)
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime!,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _processApproval(String status, {String? alasan}) async {
    try {
      final DateTime newTenggat = DateTime(
        selectedDate!.year, selectedDate!.month, selectedDate!.day,
        selectedTime!.hour, selectedTime!.minute,
      );

      await supabase.from('peminjaman').update({
        'status_transaksi': status,
        'tenggat': newTenggat.toIso8601String(),
        if (alasan != null) 'alasan_penolakan': alasan,
        'petugas_id': supabase.auth.currentUser?.id,
      }).eq('id_pinjam', widget.loanData['id_pinjam']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'pinjam' ? "Disetujui" : "Ditolak"),
            backgroundColor: status == 'pinjam' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Widget _buildNamaBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('users').select('nama').eq('id_user', widget.loanData['peminjam_id']),
        builder: (context, snapshot) {
          String nama = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data![0]['nama'] : "...";
          return Text(nama, style: const TextStyle(color: AppColors.darkblue));
        },
      ),
    );
  }

  Widget _buildWaktuInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue.withOpacity(0.5)), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _waktuItem("Pengambilan", _formatDate(widget.loanData['pengambilan'])),
          _waktuItem("Tenggat", _formatDate(widget.loanData['tenggat'])),
          _waktuItem("Pengembalian", "-"),
        ],
      ),
    );
  }

  Widget _waktuItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPickerField(String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: AppColors.darkblue),
            Text(value, style: const TextStyle(color: Colors.blueAccent)),
            const Icon(Icons.chevron_right, size: 20, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color text, VoidCallback onTap, {bool isBordered = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, elevation: 0,
          side: isBordered ? const BorderSide(color: Colors.red) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alasan Penolakan"),
        content: TextField(controller: _reasonCtrl, decoration: const InputDecoration(hintText: "Contoh: Stok alat kosong")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(onPressed: () => _processApproval('ditolak', alasan: _reasonCtrl.text), child: const Text("Tolak Sekarang", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    DateTime dt = DateTime.parse(date);
    return "${dt.day}/${dt.month}/${dt.year} | ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
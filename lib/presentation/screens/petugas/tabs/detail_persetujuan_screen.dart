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
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    DateTime dt = DateTime.parse(widget.loanData['tenggat']);
    selectedDate = dt;
    selectedTime = TimeOfDay.fromDateTime(dt);
  }

  Future<void> _simpanTenggat() async {
    try {
      final DateTime newTenggat = DateTime(
        selectedDate!.year, selectedDate!.month, selectedDate!.day,
        selectedTime!.hour, selectedTime!.minute,
      );

      await supabase.from('peminjaman').update({
        'tenggat': newTenggat.toIso8601String(),
      }).eq('id_pinjam', widget.loanData['id_pinjam']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tenggat waktu berhasil diperbarui"), 
            backgroundColor: AppColors.darkblue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: selectedDate!, 
      firstDate: DateTime.now(), 
      lastDate: DateTime(2100)
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: selectedTime!
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final int idPinjam = int.tryParse(widget.loanData['id_pinjam'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Persetujuan", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue), 
          onPressed: () => Navigator.pop(context)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildAlatList(idPinjam),
            const SizedBox(height: 25),
            const Text("Nama Peminjam", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            const SizedBox(height: 8),
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
            _actionButton("Simpan Perubahan", AppColors.darkblue, Colors.white, _simpanTenggat),
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
        ''').eq('id_pinjam', idPinjam),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Data alat tidak ditemukan");

        return Column(
          children: snapshot.data!.map((item) {
            final alat = item['alat'] as Map<String, dynamic>?;
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
                    child: (fotoUrl != null && fotoUrl.isNotEmpty) 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10), 
                            child: Image.network(fotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.monitor))
                          ) 
                        : const Icon(Icons.monitor, color: AppColors.darkblue),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alat?['nama_alat'] ?? "Alat", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
                        Text(alat?['kategori']?['nama_kategori'] ?? "Kategori", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildNamaBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue.withOpacity(0.3)), borderRadius: BorderRadius.circular(10)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('users').select('nama').eq('id_user', widget.loanData['peminjam_id']),
        builder: (context, snapshot) {
          String nama = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data![0]['nama'] : "...";
          return Text(nama, style: const TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.w500));
        },
      ),
    );
  }

  Widget _buildWaktuInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _waktuItem("Pengambilan", _formatDate(widget.loanData['pengambilan'])),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          _waktuItem("Tenggat Awal", _formatDate(widget.loanData['tenggat'])),
        ],
      ),
    );
  }

  Widget _waktuItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 10, color: Colors.black54)),
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
            Icon(icon, size: 18, color: AppColors.darkblue),
            Text(value, style: const TextStyle(color: AppColors.darkblue, fontSize: 13)),
            const Icon(Icons.edit, size: 14, color: AppColors.darkblue),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, 
      height: 50, 
      child: ElevatedButton(
        onPressed: onTap, 
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ), 
        child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16))
      )
    );
  }

  String _formatDate(String date) {
    DateTime dt = DateTime.parse(date);
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
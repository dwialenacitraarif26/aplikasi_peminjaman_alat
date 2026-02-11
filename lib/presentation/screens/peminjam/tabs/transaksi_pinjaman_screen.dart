import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tabs/cart_controller.dart';

class TransaksiPinjamanScreen extends StatefulWidget {
  const TransaksiPinjamanScreen({super.key});

  @override
  State<TransaksiPinjamanScreen> createState() =>
      _TransaksiPinjamanScreenState();
}

class _TransaksiPinjamanScreenState extends State<TransaksiPinjamanScreen> {
  final supabase = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  DateTime? _tglAmbil, _tglTenggat;
  TimeOfDay? _waktuAmbil, _waktuTenggat;
  bool _isLoading = false;

  Future<void> ajukanPeminjaman(List<Map<String, dynamic>> items) async {
    if (_tglAmbil == null || _tglTenggat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi tanggal pengambilan dan tenggat!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "Sesi berakhir, silahkan login kembali";

      final pengambilanFull = DateTime(_tglAmbil!.year, _tglAmbil!.month, _tglAmbil!.day, _waktuAmbil?.hour ?? 0, _waktuAmbil?.minute ?? 0);
      final tenggatFull = DateTime(_tglTenggat!.year, _tglTenggat!.month, _tglTenggat!.day, _waktuTenggat?.hour ?? 0, _waktuTenggat?.minute ?? 0);

      // 1. Insert ke tabel 'peminjaman' (Header)
      final res = await supabase
          .from('peminjaman')
          .insert({
            'peminjam_id': user.id,
            'pengambilan': pengambilanFull.toIso8601String(),
            'tenggat': tenggatFull.toIso8601String(),
            'status_transaksi': 'menunggu',
          })
          .select()
          .single();

      final newIdPinjam = res['id_pinjam'];

      // 2. Insert ke tabel 'detail_peminjaman' (Sesuai Skema Gambar)
      final List<Map<String, dynamic>> detailData = items.map((item) => {
        'id_pinjam': newIdPinjam,
        'id_alat': item['id_alat'],
        'jumlah': item['qty'],
      }).toList();

      await supabase.from('detail_peminjaman').insert(detailData);

      CartController.clear();
      if (mounted) _showVerificationDialog();
      
    } catch (e) {
      debugPrint("Error detail: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.history, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("Menunggu Persetujuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkblue)),
            const SizedBox(height: 10),
            const Text("Pengajuan Berhasil dikirim\nPantau terus persetujuan anda\ndi halaman dashboard.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Oke", style: TextStyle(color: Colors.white)),
              ),
            ),
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
        title: const Text("Transaksi", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkblue),
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppColors.darkblue))
      : ValueListenableBuilder(
        valueListenable: CartController.items,
        builder: (context, items, _) {
          if (items.isEmpty) return const Center(child: Text("Keranjang kosong"));
          int totalQty = items.fold(0, (sum, item) => sum + (item['qty'] as int));
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((alat) => _buildCartItem(alat)).toList(),
                const SizedBox(height: 10),
                _buildAddMoreButton(context),
                const SizedBox(height: 25),
                _label("Nama"),
                _textField(_nameCtrl, "Masukkan nama peminjam"),
                _label("Jumlah"),
                _textField(TextEditingController(text: totalQty.toString()), "", readOnly: true),
                _label("Pengambilan"),
                Row(
                  children: [
                    Expanded(child: _datePickerTile(_tglAmbil, (d) => setState(() => _tglAmbil = d))),
                    const SizedBox(width: 10),
                    Expanded(child: _timePickerTile(_waktuAmbil, (t) => setState(() => _waktuAmbil = t))),
                  ],
                ),
                _label("Tenggat"),
                Row(
                  children: [
                    Expanded(child: _datePickerTile(_tglTenggat, (d) => setState(() => _tglTenggat = d))),
                    const SizedBox(width: 10),
                    Expanded(child: _timePickerTile(_waktuTenggat, (t) => setState(() => _waktuTenggat = t))),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ajukanPeminjaman(items),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Ajukan Peminjaman", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---
  // --- Helper Widgets ---
  Widget _buildCartItem(Map<String, dynamic> alat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), 
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Foto Alat
          ClipRRect(
            borderRadius: BorderRadius.circular(10), 
            child: alat['foto_url'] != null 
              ? Image.network(alat['foto_url'], width: 60, height: 60, fit: BoxFit.cover) 
              : const Icon(Icons.image, size: 60),
          ),
          const SizedBox(width: 12),
          
          // Informasi Alat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  alat['nama_alat'], 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue),
                ), 
                const Text("Elektronik", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          
          // Kontrol Qty
          Row(
            children: [
              _qtyBtn(Icons.remove_circle_outline, () { 
                if (alat['qty'] > 1) CartController.updateQty(alat['id_alat'], -1); 
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10), 
                child: Text("${alat['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(Icons.add_circle_outline, () => CartController.updateQty(alat['id_alat'], 1)),
            ],
          ),
          
          // Divider Kecil
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          
          // TOMBOL HAPUS
          GestureDetector(
            onTap: () {
              // Panggil fungsi hapus dari controller
              CartController.removeItem(alat['id_alat']);
            },
            child: const Icon(
              Icons.delete, 
              color: AppColors.darkblue, 
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Icon(icon, color: AppColors.darkblue, size: 22));
  Widget _buildAddMoreButton(BuildContext context) => SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(backgroundColor: AppColors.darkblue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("+ Tambah Alat", style: TextStyle(color: Colors.white))));
  Widget _label(String text) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)));
  Widget _textField(TextEditingController ctrl, String hint, {bool readOnly = false}) => TextFormField(controller: ctrl, readOnly: readOnly, decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkblue)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkblue))));
  Widget _datePickerTile(DateTime? val, Function(DateTime) onPick) => GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030)); if (d != null) onPick(d); }, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.darkblue), const SizedBox(width: 8), Text(val == null ? "00/00/00" : "${val.day}/${val.month}/${val.year}", style: const TextStyle(fontSize: 13, color: AppColors.darkblue))])));
  Widget _timePickerTile(TimeOfDay? val, Function(TimeOfDay) onPick) => GestureDetector(onTap: () async { final t = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (t != null) onPick(t); }, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.darkblue), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.history_outlined, size: 18, color: AppColors.darkblue), const SizedBox(width: 8), Text(val == null ? "0:00" : val.format(context), style: const TextStyle(fontSize: 13, color: AppColors.darkblue))])));
}
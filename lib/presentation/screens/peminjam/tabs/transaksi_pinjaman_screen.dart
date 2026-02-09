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

  Future<void> ajukanPeminjaman(List<Map<String, dynamic>> items) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Simpan Header Transaksi
      final res = await supabase
          .from('peminjaman')
          .insert({
            'nama_peminjam': _nameCtrl.text,
            'tgl_ambil': _tglAmbil?.toIso8601String(),
            'tgl_kembali': _tglTenggat?.toIso8601String(),
            'status': 'Menunggu', // Status awal sesuai permintaan
            'peminjam_id': user.id,
          })
          .select()
          .single();

      // 2. Simpan Detail Alat (Jika ada tabel peminjaman_detail)
      for (var item in items) {
        await supabase.from('peminjaman_detail').insert({
          'peminjaman_id': res['id_peminjaman'],
          'alat_id': item['id_alat'],
          'qty': item['qty'],
        });
      }

      // 3. Munculkan Dialog Verifikasi (Mockup Gambar 4)
      _showVerificationDialog();

      // 4. Kosongkan Keranjang
      CartController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e")),
      );
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
            const Icon(Icons.history,
                size: 80, color: Colors.orange), // Ikon jam sesuai gambar
            const SizedBox(height: 20),
            const Text(
              "Menunggu Persetujuan",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.darkblue),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pengajuan Berhasil dikirim\nPantau terus persetujuan anda\ndi halaman dashboard.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  Navigator.pop(context); // Kembali ke Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkblue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
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
        title: const Text("Transaksi",
            style: TextStyle(
                color: AppColors.darkblue, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkblue),
      ),
      body: ValueListenableBuilder(
        valueListenable: CartController.items,
        builder: (context, items, _) {
          if (items.isEmpty)
            return const Center(child: Text("Keranjang kosong"));

          // Hitung total QTY dari semua item
          int totalQty =
              items.fold(0, (sum, item) => sum + (item['qty'] as int));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LIST ITEM (KERANJANG)
                ...items.map((alat) => _buildCartItem(alat)).toList(),

                const SizedBox(height: 10),
                _buildAddMoreButton(context),

                const SizedBox(height: 25),

                /// FORM INPUT
                _label("Nama"),
                _textField(_nameCtrl, "Masukkan nama peminjam"),

                _label("Jumlah"),
                _textField(TextEditingController(text: totalQty.toString()), "",
                    readOnly: true),

                _label("Pengambilan"),
                Row(
                  children: [
                    Expanded(
                        child: _datePickerTile(
                            _tglAmbil, (d) => setState(() => _tglAmbil = d))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _timePickerTile(_waktuAmbil,
                            (t) => setState(() => _waktuAmbil = t))),
                  ],
                ),

                _label("Tenggat"),
                Row(
                  children: [
                    Expanded(
                        child: _datePickerTile(_tglTenggat,
                            (d) => setState(() => _tglTenggat = d))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _timePickerTile(_waktuTenggat,
                            (t) => setState(() => _waktuTenggat = t))),
                  ],
                ),

                const SizedBox(height: 30),

                /// BUTTON SUBMIT
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logika Ajukan Peminjaman
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkblue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Ajukan Peminjaman",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
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

  /// CARD ITEM PER ALAT
  Widget _buildCartItem(Map<String, dynamic> alat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: alat['foto_url'] != null
                ? Image.network(alat['foto_url'],
                    width: 60, height: 60, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat['nama_alat'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkblue)),
                const Text("Elektronik",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              // Tombol Kurang
              _qtyBtn(Icons.remove_circle_outline, () {
                if (alat['qty'] > 1) {
                  CartController.updateQty(alat['id_alat'], -1);
                } else {
                  // Munculkan konfirmasi jika qty sisa 1 tapi tetap ditekan minus
                  _confirmDelete(context, alat);
                }
              }),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "${alat['qty']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkblue,
                  ),
                ),
              ),

              // Tombol Tambah
              _qtyBtn(Icons.add_circle_outline, () {
                if (alat['qty'] < (alat['stok_total'] ?? 0)) {
                  CartController.updateQty(alat['id_alat'], 1);
                }
              }),

              const SizedBox(width: 8),

              // Tombol Hapus Langsung
              IconButton(
                onPressed: () => _confirmDelete(context, alat),
                icon: const Icon(Icons.delete,
                    color: AppColors.darkblue, size: 22),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// FUNGSI KONFIRMASI HAPUS
  void _confirmDelete(BuildContext context, Map<String, dynamic> alat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Alat",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkblue,
          ),
        ),
        content: Text(
          "Yakin ingin menghapus ${alat['nama_alat']} dari daftar pinjaman?",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          /// TOMBOL BATAL (DENGAN GARIS LUAR)
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: AppColors.darkblue), // Garis luar darkblue
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              "Batal",
              style: TextStyle(
                color: AppColors.darkblue, // Teks juga darkblue agar serasi
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              CartController.removeItem(alat['id_alat']);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkblue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Hapus",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,q
        child: Icon(icon, color: AppColors.darkblue, size: 22),
      );

  Widget _buildAddMoreButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.darkblue,
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("+ Tambah Alat"),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.darkblue)),
      );

  Widget _textField(TextEditingController ctrl, String hint,
          {bool readOnly = false}) =>
      TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkblue)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkblue)),
        ),
      );

  Widget _datePickerTile(DateTime? val, Function(DateTime) onPick) =>
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors
                        .darkblue, // Warna header & lingkaran tanggal terpilih
                    onPrimary:
                        Colors.white, // Warna teks di dalam lingkaran terpilih
                    onSurface: AppColors.darkblue, // Warna teks tanggal
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppColors.darkblue, // Warna tombol Pilih & Batal
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (d != null) onPick(d);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.darkblue),
              borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 18, color: AppColors.darkblue),
              const SizedBox(width: 8),
              Text(
                  val == null
                      ? "00/00/00"
                      : "${val.day}/${val.month}/${val.year}",
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.darkblue)),
            ],
          ),
        ),
      );

  Widget _timePickerTile(TimeOfDay? val, Function(TimeOfDay) onPick) =>
      GestureDetector(
        onTap: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.darkblue,
                    onSurface: AppColors.darkblue,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (t != null) onPick(t);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.darkblue),
              borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.history_outlined,
                  size: 18, color: AppColors.darkblue),
              const SizedBox(width: 8),
              Text(val == null ? "0:00" : val.format(context),
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.darkblue)),
            ],
          ),
        ),
      );
}

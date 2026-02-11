import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPetugasTab extends StatefulWidget {
  const LaporanPetugasTab({super.key});

  @override
  State<LaporanPetugasTab> createState() => _LaporanPetugasTabState();
}

class _LaporanPetugasTabState extends State<LaporanPetugasTab> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Daftar bulan untuk ditampilkan (Bisa dibuat dinamis, tapi ini contoh untuk 6 bulan terakhir)
  List<DateTime> _getMonthsList() {
    DateTime now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - i, 1));
  }

  Future<void> _generatePDF(String title, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("LAPORAN PEMINJAMAN ALAT",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text("Periode: $title"),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Ringkasan Statistik:",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: "Total Transaksi: ${data['total_transaksi']}"),
              pw.Bullet(text: "Total Alat Keluar: ${data['total_alat']}"),
              pw.SizedBox(height: 20),
              pw.Text("Daftar Alat Terpopuler:",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                headers: ['Nama Alat', 'Jumlah Pinjam'],
                data: (data['alat_list'] as List)
                    .map((e) => [e.key, "${e.value} Unit"])
                    .toList(),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                    "Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"),
              ),
            ],
          );
        },
      ),
    );

    // Perintah untuk memunculkan dialog download/cetak di HP
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_$title.pdf',
    );
  }

  // Fungsi mengambil data rekap untuk bulan tertentu
  Future<Map<String, dynamic>> _getRekapBulanan(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    try {
      final response = await supabase
          .from('peminjaman')
          .select('''
            id_pinjam, 
            status_transaksi, 
            pengambilan,
            detail_peminjaman(
              jumlah,
              alat(nama_alat)
            )
          ''')
          .gte('pengambilan', firstDay.toIso8601String())
          .lte('pengambilan', lastDay.toIso8601String());

      final List data = response as List;

      if (data.isEmpty) return {'empty': true};

      // Hitung Total Transaksi & Alat
      int totalTransaksi = data.length;
      int totalAlat = 0;
      Map<String, int> alatTerpopuler = {};

      for (var item in data) {
        final details = item['detail_peminjaman'] as List;
        for (var d in details) {
          int jumlah = d['jumlah'] ?? 0;
          String namaAlat = d['alat']['nama_alat'];
          totalAlat += jumlah;
          alatTerpopuler[namaAlat] = (alatTerpopuler[namaAlat] ?? 0) + jumlah;
        }
      }

      // Urutkan alat terpopuler
      var sortedAlat = alatTerpopuler.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'empty': false,
        'total_transaksi': totalTransaksi,
        'total_alat': totalAlat,
        'alat_list': sortedAlat.take(3).toList(),
      };
    } catch (e) {
      debugPrint("Error Laporan: $e");
      return {'empty': true};
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = _getMonthsList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Laporan Bulanan",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  Text("Data rekapitulasi peminjaman alat",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final monthDate = months[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getRekapBulanan(monthDate),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      return _buildLaporanCard(
                          monthDate, data, snapshot.connectionState);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanCard(
      DateTime date, Map<String, dynamic>? data, ConnectionState state) {
    String monthName = DateFormat('MMMM yyyy').format(date);
    bool isEmpty = data?['empty'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEmpty ? Colors.grey.shade100 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_today,
              color: isEmpty ? Colors.grey : Colors.blue, size: 20),
        ),
        title: Text(monthName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: state == ConnectionState.waiting
            ? const Text("Memuat data...", style: TextStyle(fontSize: 12))
            : Text(
                isEmpty
                    ? "Tidak ada transaksi"
                    : "${data!['total_transaksi']} Transaksi",
                style: TextStyle(
                    color: isEmpty ? Colors.red.shade300 : Colors.green,
                    fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: isEmpty ? null : () => _showDetailLaporan(monthName, data!),
      ),
    );
  }

  void _showDetailLaporan(String title, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Detail $title",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Icon(Icons.insert_chart_outlined, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatBox("Transaksi", data['total_transaksi'].toString(),
                    Colors.blue),
                const SizedBox(width: 15),
                _buildStatBox(
                    "Total Alat", data['total_alat'].toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 25),
            const Text("Alat Paling Sering Dipinjam",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...(data['alat_list'] as List)
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key),
                          Text("${e.value} Unit",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {}, // Logika Cetak PDF
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("CETAK LAPORAN PDF",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

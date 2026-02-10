import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import 'rincian_denda_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final supabase = Supabase.instance.client;
  String _selectedLabel = "Total";
  String _selectedValue = "";
  DateTime? _selectedDate;

  // --- [LOGIC FUNCTIONS] ---
  Future<Map<String, dynamic>> _getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'nama': 'Guest', 'role': 'User'};
    try {
      return await supabase.from('users').select().eq('id_user', user.id).single();
    } catch (e) {
      return {'nama': user.email?.split('@')[0], 'role': 'Admin'};
    }
  }

  Future<List<Map<String, dynamic>>> _getPeminjamanAktif() async {
    try {
      var query = supabase.from('peminjaman').select('''
            id_pinjam, pengambilan, tenggat, status_transaksi,
            users!peminjaman_peminjam_id_fkey(nama), 
            detail_peminjaman(jumlah, alat(nama_alat))
          ''').eq('status_transaksi', 'pinjam');

      if (_selectedDate != null) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        query = query.gte('pengambilan', '$formattedDate 00:00:00')
                     .lte('pengambilan', '$formattedDate 23:59:59');
      }
      final response = await query.order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> _getAlatTerpopuler() async {
    try {
      final response = await supabase.from('detail_peminjaman').select('id_alat, alat(nama_alat)');
      if (response.isEmpty) return [];
      Map<String, int> counts = {};
      Map<String, String> names = {};
      for (var item in response) {
        if (item['alat'] != null) {
          String id = item['id_alat'].toString();
          counts[id] = (counts[id] ?? 0) + 1;
          names[id] = item['alat']['nama_alat'].toString();
        }
      }
      var sortedKeys = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      return sortedKeys.take(5).map((id) => {'nama': names[id], 'jumlah': counts[id]}).toList();
    } catch (e) { return []; }
  }

  Future<int> _getTotalAlatTersedia() async {
    try {
      final res = await supabase.from('alat').select('id_alat').gt('stok_total', 0);
      return (res as List).length;
    } catch (e) { return 0; }
  }

  // LOGIKA BARU: Filter Denda Hanya Minggu Ini
  Future<String> _getTotalDenda() async {
    try {
      final response = await supabase.from('denda').select('''
        total_denda,
        peminjaman:id_kembali (pengembalian)
      ''');

      double totalMingguIni = 0;
      DateTime sekarang = DateTime.now();
      
      // Cari hari Senin di minggu ini jam 00:00:00
      DateTime seninMingguIni = sekarang.subtract(Duration(days: sekarang.weekday - 1));
      seninMingguIni = DateTime(seninMingguIni.year, seninMingguIni.month, seninMingguIni.day);

      for (var item in response) {
        if (item['peminjaman'] != null && item['peminjaman']['pengembalian'] != null) {
          DateTime tglKembali = DateTime.parse(item['peminjaman']['pengembalian'].toString()).toLocal();
          
          // Validasi: Jika tanggal kembali >= Senin minggu ini, maka ikut dijumlahkan
          if (tglKembali.isAfter(seninMingguIni.subtract(const Duration(seconds: 1)))) {
            totalMingguIni += double.tryParse(item['total_denda'].toString()) ?? 0;
          }
        }
      }
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(totalMingguIni);
    } catch (e) { 
      return "Rp0"; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                _buildHeader(),
                const SizedBox(height: 30),
                _sectionTitle("Statistik Alat Terpopuler"),
                const SizedBox(height: 15),
                _buildDonutChartSection(),
                const SizedBox(height: 25),
                _buildStatsRow(),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle("Peminjaman Aktif"),
                    _buildCalendarButton(),
                  ],
                ),
                const SizedBox(height: 15),
                _buildListPeminjaman(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- [UI COMPONENTS] ---
  Widget _buildHeader() => FutureBuilder<Map<String, dynamic>>(
    future: _getUserProfile(),
    builder: (context, snapshot) {
      final name = snapshot.data?['nama'] ?? "Admin";
      final role = snapshot.data?['role'] ?? "Administrator";
      return Row(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: AppColors.darkblue, child: Icon(Icons.person, color: Colors.white, size: 30)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Halo, $name", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            Text(role, style: TextStyle(fontSize: 14, color: AppColors.darkblue.withOpacity(0.6))),
          ]),
        ],
      );
    },
  );

  Widget _buildDonutChartSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkblue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.darkblue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAlatTerpopuler(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox(height: 150, child: Center(child: Text("Data tidak tersedia", style: TextStyle(color: Colors.white70))));
          }
          final data = snapshot.data!;
          final total = data.fold<int>(0, (sum, item) => sum + (item['jumlah'] as int));
          if (_selectedValue == "") _selectedValue = "$total";

          return Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedLabel = "Total";
                  _selectedValue = "$total";
                }),
                child: SizedBox(
                  height: 130, width: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 95, height: 95, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1), width: 10))),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return CustomPaint(
                            size: const Size(130, 130),
                            painter: DonutChartPainter(data: data, total: total, selectedLabel: _selectedLabel, animationValue: value),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedValue, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                          Text(_selectedLabel == "Total" ? "Unit" : "Pinjam", style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 25),
              Expanded(child: _buildLegendList(data, total)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendList(List<Map<String, dynamic>> data, int total) {
    final colors = [Colors.white, Colors.orangeAccent, Colors.greenAccent, Colors.redAccent, Colors.cyanAccent];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_selectedLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
        const Divider(color: Colors.white24, height: 12),
        ...List.generate(data.length, (index) {
          bool isSelected = _selectedLabel == data[index]['nama'];
          return InkWell(
            onTap: () => setState(() { _selectedValue = "${data[index]['jumlah']}"; _selectedLabel = data[index]['nama']; }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 12 : 7, height: 7,
                    decoration: BoxDecoration(color: colors[index % colors.length], borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data[index]['nama'], style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: FutureBuilder<int>(future: _getTotalAlatTersedia(), builder: (context, snap) => _statCard(Icons.inventory_2_rounded, "Stok Tersedia", "${snap.data ?? 0}", Colors.blue.shade700, () {}))),
      const SizedBox(width: 15),
      Expanded(child: FutureBuilder<String>(future: _getTotalDenda(), builder: (context, snap) => _statCard(Icons.account_balance_wallet_rounded, "Denda Minggu Ini", snap.data ?? "Rp0", Colors.red.shade700, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RincianDendaScreen()))))),
    ]);
  }

  Widget _statCard(IconData icon, String label, String val, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        ]),
      ),
    );
  }

  Widget _buildListPeminjaman() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPeminjamanAktif(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada peminjaman aktif"));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final data = snapshot.data![index];
            final details = data['detail_peminjaman'] as List;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.darkblue,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(data['users']['nama'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...details.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['alat']['nama_alat'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text("${item['jumlah']} Unit", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
                            ],
                          ),
                        )).toList(),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Tgl Pinjam", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(DateFormat('dd MMM yyyy').format(DateTime.parse(data['pengambilan'])), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ])),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Tgl Tenggat", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(DateFormat('dd MMM yyyy').format(DateTime.parse(data['tenggat'])), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                            ])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkblue));
  Widget _buildCalendarButton() => IconButton(icon: const Icon(Icons.calendar_month), onPressed: () async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  });
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int total;
  final String selectedLabel;
  final double animationValue;

  DonutChartPainter({required this.data, required this.total, required this.selectedLabel, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.3;
    final colors = [Colors.white, Colors.orangeAccent, Colors.greenAccent, Colors.redAccent, Colors.cyanAccent];
    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i]['jumlah'] / total) * 2 * pi * animationValue;
      final isSelected = data[i]['nama'] == selectedLabel;
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(selectedLabel == "Total" || isSelected ? 1 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 16 : 10
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle + 0.04, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter old) => true;
}
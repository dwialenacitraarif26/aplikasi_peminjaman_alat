import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

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

  // --- LOGIC FUNCTIONS ---
  
  Future<Map<String, dynamic>> _getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'nama': 'Guest', 'role': 'User'};
    try {
      return await supabase.from('users').select().eq('id_user', user.id).single();
    } catch (e) {
      return {'nama': user.email?.split('@')[0], 'role': 'Error Load'};
    }
  }

  Future<List<Map<String, dynamic>>> _getPeminjamanAktif() async {
    try {
      var query = supabase
          .from('peminjaman')
          .select('''
            id_pinjam, 
            pengambilan, 
            tenggat,
            status_transaksi,
            users!peminjaman_peminjam_id_fkey(nama), 
            detail_peminjaman(
              jumlah, 
              alat(nama_alat)
            )
          ''');

      query = query.eq('status_transaksi', 'pinjam');

      if (_selectedDate != null) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        query = query.gte('pengambilan', '$formattedDate 00:00:00')
                     .lte('pengambilan', '$formattedDate 23:59:59');
      }

      final response = await query.order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Peminjaman Aktif: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getAlatTerpopuler() async {
    try {
      final List<dynamic> response = await supabase
          .from('detail_peminjaman')
          .select('id_alat, alat(nama_alat)');
      
      if (response.isEmpty) return [];
      Map<String, int> counts = {};
      Map<String, String> names = {};
      
      for (var item in response) {
        if (item['alat'] != null) {
          String id = item['id_alat'].toString();
          String name = item['alat']['nama_alat'].toString();
          counts[id] = (counts[id] ?? 0) + 1;
          names[id] = name;
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

  Future<String> _getTotalDenda() async {
    try {
      final response = await supabase.from('denda').select('total_denda');
      double totalDenda = 0;
      for (var item in response) {
        final val = item['total_denda'];
        if (val != null) {
          totalDenda += double.parse(val.toString());
        }
      }
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(totalDenda);
    } catch (e) { return "Rp0"; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _sectionTitle("Alat Paling Sering Dipinjam"),
              const SizedBox(height: 15),
              _buildChartSection(),
              const SizedBox(height: 25),
              _buildStatsRow(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle("Daftar Peminjaman Aktif"),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppColors.darkblue),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
              if (_selectedDate != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Chip(
                    label: Text(DateFormat('dd MMMM yyyy').format(_selectedDate!)),
                    onDeleted: () => setState(() => _selectedDate = null),
                  ),
                ),
              _buildListPeminjaman(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPeminjaman() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPeminjamanAktif(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: const Center(child: Text("Tidak ada peminjaman aktif")),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final data = snapshot.data![index];
            
            // AMBIL NAMA PEMINJAM DARI RELASI USERS
            final userData = data['users'];
            final String namaPeminjam = (userData != null && userData['nama'] != null) 
                ? userData['nama'] 
                : "Tanpa Nama";

            final detail = data['detail_peminjaman'] as List;

            String tglPinjam = data['pengambilan'] != null 
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(data['pengambilan'])) 
                : "-";
            String tglTenggat = data['tenggat'] != null 
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(data['tenggat'])) 
                : "-";

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.darkblue,
                            child: Text(
                              namaPeminjam.isNotEmpty ? namaPeminjam[0].toUpperCase() : "?", 
                              style: const TextStyle(color: Colors.white, fontSize: 12)
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            namaPeminjam, // <--- NAMA SUDAH DINAMIS
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkblue)
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Text("pinjam", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const Divider(height: 20),
                  ...detail.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.darkblue),
                        const SizedBox(width: 8),
                        Text("${d['alat']['nama_alat']}", style: const TextStyle(fontSize: 14)),
                        const Spacer(),
                        Text("${d['jumlah']} Unit", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoDate("Pengambilan", tglPinjam, Icons.calendar_today),
                      _infoDate("Tenggat", tglTenggat, Icons.event_busy, isDeadline: true),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UI HELPERS ---

  Widget _infoDate(String label, String date, IconData icon, {bool isDeadline = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDeadline ? Colors.red : Colors.grey),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDeadline ? Colors.red : AppColors.darkblue)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: _getTotalAlatTersedia(),
            builder: (context, snap) => _statBox(Icons.inventory_2_outlined, "Alat Tersedia", "${snap.data ?? 0}"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<String>(
            future: _getTotalDenda(),
            builder: (context, snap) => _statBox(Icons.payments_outlined, "Total Denda", snap.data ?? "Rp0", isDenda: true),
          ),
        ),
      ],
    );
  }

  Widget _statBox(IconData icon, String label, String val, {bool isDenda = false}) => Container(
    padding: const EdgeInsets.all(15),
    height: 100,
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Icon(icon, color: AppColors.darkblue, size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(val, style: TextStyle(fontSize: isDenda ? 20 : 28, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
              ),
            ],
          ),
        )
      ],
    ),
  );

  Widget _buildChartSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAlatTerpopuler(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyChart();
        final data = snapshot.data!;
        final totalOverall = data.fold<int>(0, (sum, item) => sum + (item['jumlah'] as int));
        final colors = [AppColors.darkblue, Colors.orange, Colors.green, Colors.red, Colors.purple];
        if (_selectedValue == "") _selectedValue = "$totalOverall";
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _buildDonutChart(data, totalOverall, colors),
              const SizedBox(width: 20),
              Expanded(child: _buildLegendList(data, colors)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonutChart(List<Map<String, dynamic>> data, int totalOverall, List<Color> colors) {
    return SizedBox(
      height: 140, width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(data.length, (index) {
            double currentSum = data.take(index).fold(0, (s, i) => s + (i['jumlah'] as int));
            bool isSelected = _selectedLabel == data[index]['nama'];
            return RotationTransition(
              turns: AlwaysStoppedAnimation(currentSum / totalOverall),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (_selectedLabel == data[index]['nama']) {
                    _selectedLabel = "Total"; _selectedValue = "$totalOverall";
                  } else {
                    _selectedLabel = data[index]['nama']; _selectedValue = "${data[index]['jumlah']}";
                  }
                }),
                child: SizedBox(
                  width: 110, height: 110,
                  child: CircularProgressIndicator(
                    value: (data[index]['jumlah'] as int) / totalOverall,
                    strokeWidth: isSelected ? 28 : 18,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(isSelected ? colors[index] : colors[index].withOpacity(0.5)),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => setState(() { _selectedLabel = "Total"; _selectedValue = "$totalOverall"; }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedValue, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
                SizedBox(width: 80, child: Text(_selectedLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendList(List<Map<String, dynamic>> data, List<Color> colors) {
    final totalOverall = data.fold<int>(0, (sum, item) => sum + (item['jumlah'] as int));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(data.length, (index) {
        bool isSelected = _selectedLabel == data[index]['nama'];
        return InkWell(
          onTap: () => setState(() {
            if (_selectedLabel == data[index]['nama']) {
              _selectedLabel = "Total"; _selectedValue = "$totalOverall";
            } else {
              _selectedLabel = data[index]['nama']; _selectedValue = "${data[index]['jumlah']}";
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index], shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(data[index]['nama'], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.darkblue : AppColors.darkblue.withOpacity(0.7)), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      }),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: const Color(0xFFD1E4F3),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
  );

  Widget _buildHeader() => FutureBuilder<Map<String, dynamic>>(
    future: _getUserProfile(),
    builder: (context, snapshot) {
      final name = snapshot.data?['nama'] ?? "...";
      final roleRaw = snapshot.data?['role']?.toString() ?? "...";
      final role = roleRaw.isNotEmpty ? roleRaw[0].toUpperCase() + roleRaw.substring(1).toLowerCase() : "...";
      return Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: AppColors.darkblue, child: Icon(Icons.person, color: Colors.white, size: 35)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            Text(role, style: const TextStyle(fontSize: 16, color: AppColors.darkblue)),
          ]),
        ],
      );
    },
  );

  Widget _sectionTitle(String t) => Row(
    children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.darkblue, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkblue)),
    ],
  );

  Widget _buildEmptyChart() => Container(
    height: 150, width: double.infinity,
    decoration: _cardDecoration(),
    child: const Center(child: Text("Data Peminjaman Kosong")),
  );
}
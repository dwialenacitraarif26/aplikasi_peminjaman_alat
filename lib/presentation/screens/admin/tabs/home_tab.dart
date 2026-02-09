import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'log_aktivitas_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final supabase = Supabase.instance.client;

  // --- LOGIC FUNCTIONS ---
  Future<Map<String, dynamic>> _getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'nama': 'Guest', 'role': 'User'};
    try {
      final data = await supabase.from('users').select().eq('id_user', user.id).single();
      return data;
    } catch (e) {
      return {'nama': user.email?.split('@')[0], 'role': 'Error Load'};
    }
  }

  Stream<List<Map<String, dynamic>>> _getStokMenipis() {
    return supabase
        .from('alat')
        .stream(primaryKey: ['id_alat'])
        .order('stok_total', ascending: true)
        .map((data) => data
            .where((e) => (e['stok_total'] as int) < 10 && (e['stok_total'] as int) > 0)
            .take(4)
            .toList());
  }

  Future<int> _getTotalTersedia() async {
    try {
      final response = await supabase.from('alat').select('id_alat').gt('stok_total', 0);
      return (response as List).length;
    } catch (e) { return 0; }
  }

  Future<int> _getTotalDipinjam() async {
    try {
      final response = await supabase.from('peminjaman').select('id_peminjaman').eq('status', 'dipinjam');
      return (response as List).length;
    } catch (e) { return 0; }
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
              
              /// --- HEADER ---
              FutureBuilder<Map<String, dynamic>>(
                future: _getUserProfile(),
                builder: (context, snapshot) {
                  final name = snapshot.data?['nama'] ?? "...";
                  final roleRaw = snapshot.data?['role']?.toString() ?? "...";
                  
                  // LOGIKA CAPITALIZE: Mengubah 'admin' menjadi 'Admin'
                  final role = roleRaw.isNotEmpty 
                      ? roleRaw[0].toUpperCase() + roleRaw.substring(1).toLowerCase() 
                      : "...";

                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.darkblue,
                        child: Icon(Icons.person, color: Colors.white, size: 35),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
                          // Hapus .toUpperCase() dan ganti dengan variabel role yang sudah diolah
                          Text(role, style: const TextStyle(fontSize: 16, color: AppColors.darkblue)),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              /// --- SECTION GRAFIK (FIXED BASELINE & PRECISION) ---
              _sectionTitle("Grafik Peminjamann Alat Paling Banyak"),
              
              Container(
                height: 250,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1E4F3),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Sumbu Y
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) => Text("${20 - (index * 5)}", 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54))),
                          ),
                          const SizedBox(width: 10),
                          // Area Batang & Grid
                          Expanded(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(5, (index) => Divider(
                                    color: index == 4 ? Colors.grey: Colors.grey,
                                    thickness: index == 4 ? 2 : 1, 
                                    height: 1
                                  )),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _barItemOnly(10/20),
                                      _barItemOnly(15/20),
                                      _barItemOnly(10/20),
                                      _barItemOnly(20/20),
                                      _barItemOnly(15/20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label Nama Alat
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _labelItem("Gitar"),
                          _labelItem("Monitor"),
                          _labelItem("Proyek."),
                          _labelItem("Kamera"),
                          _labelItem("Laptop"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// --- STATS ROW ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard("List Alat Stok Menipis", child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getStokMenipis(),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.isEmpty) return const Text("Stok Aman");
                        int i = 1;
                        return Column(
                          children: snap.data!.map((e) => _smallItem(i++, e['nama_alat'], e['stok_total'])).toList(),
                        );
                      }
                    )),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      children: [
                        FutureBuilder<int>(
                          future: _getTotalTersedia(),
                          builder: (context, snap) => _statBox(Icons.inventory_2_outlined, "Total Alat Tersedia", "${snap.data ?? 0}"),
                        ),
                        const SizedBox(height: 15),
                        FutureBuilder<int>(
                          future: _getTotalDipinjam(),
                          builder: (context, snap) => _statBox(Icons.handyman_outlined, "Total Alat Dipinjam", "${snap.data ?? 0}"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              _logAktivitasBtn(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _barItemOnly(double ratio) {
    return Container(
      width: 30,
      height: 170 * ratio, // Tinggi maksimal disesuaikan agar presisi dengan garis 20
      decoration: const BoxDecoration(
        color: AppColors.darkblue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }

  Widget _labelItem(String label) {
    return SizedBox(
      width: 40,
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Container(width: 18, height: 18, color: AppColors.darkblue),
        const SizedBox(width: 10),
        Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    ),
  );

  Widget _buildCard(String title, {required Widget child}) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFD1E4F3), 
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: Column(
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 14)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _statBox(IconData icon, String label, String val) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFD1E4F3), 
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black..withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.darkblue, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            ],
          ),
        )
      ],
    ),
  );

  Widget _smallItem(int index, String name, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("$index. $name", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 14)),
      ],
    ),
  );

  Widget _logAktivitasBtn(BuildContext context) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogAktivitasScreen())),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E4F3), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black..withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Log Aktivitas", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 18)),
          Icon(Icons.arrow_forward_ios, color: AppColors.darkblue, size: 20),
        ],
      ),
    ),
  );
}
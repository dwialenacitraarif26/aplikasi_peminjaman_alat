import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'category_screen.dart';
import 'add_alat_screen.dart';
import 'detail_alat_screen.dart';
import 'edit_alat_screen.dart';

class AlatTab extends StatefulWidget {
  const AlatTab({super.key});

  @override
  State<AlatTab> createState() => _AlatTabState();
}

class _AlatTabState extends State<AlatTab> {
  final supabase = Supabase.instance.client;
  String search = '';
  int? selectedCategory;

  Stream<List<Map<String, dynamic>>> alatStream() {
  var query = supabase.from('alat').stream(primaryKey: ['id_alat']);

  // Stream di Supabase tidak mendukung .eq() langsung, 
  // Jadi filter manual di .map sudah benar, TAPI pastikan data ID-nya pas.
  return query.order('nama_alat').map((data) {
    return data.where((alat) {
      final matchSearch = alat['nama_alat']
          .toString()
          .toLowerCase()
          .contains(search.toLowerCase());
      
      // Pastikan tipe data kategori_id sama (int dengan int)
      final matchCat = selectedCategory == null ||
          alat['kategori_id'] == selectedCategory;
          
      return matchSearch && matchCat;
    }).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daftar Alat",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkblue,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CategoryScreen())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Kategori"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkblue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkblue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => search = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.white),
                    hintText: "search...",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// FILTER KATEGORI
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('kategori')
                    .stream(primaryKey: ['id_kategori']).order('nama_kategori'),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip("All", null),
                        ...list.map(
                            (e) => _chip(e['nama_kategori'], e['id_kategori'])),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// GRID ALAT (RESPONSIVE)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: alatStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text("Tidak ada alat ditemukan"));
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Perhitungan rasio dinamis agar kartu tidak overflow
                        double cardWidth = (constraints.maxWidth - 16) / 2;
                        double cardHeight =
                            270; // Tinggi aman untuk semua device

                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: cardWidth / cardHeight,
                          ),
                          itemBuilder: (context, index) =>
                              _alatCard(snapshot.data![index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.darkblue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddAlatScreen())),
      ),
    );
  }

  Widget _alatCard(Map<String, dynamic> alat) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailAlatScreen(alat: alat))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD1E4F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            /// AREA GAMBAR
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: alat['foto_url'] != null &&
                          alat['foto_url'].toString().isNotEmpty
                      ? Image.network(alat['foto_url'], fit: BoxFit.contain)
                      : const Icon(Icons.image_outlined,
                          size: 40, color: Colors.grey),
                ),
              ),
            ),

            /// INFO ALAT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      alat['nama_alat'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkblue,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _getKategoriName(alat['kategori_id'])),
                      FittedBox(
                        child: Text(
                          "Stok ${alat['stok_total']}",
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// BUTTON ACTIONS
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _btn("Edit", AppColors.darkblue, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditAlatScreen(alat: alat)));
                  }),
                  const SizedBox(width: 6),
                  _btn("Hapus", const Color(0xFF3F51B5),
                      () => _confirmDelete(alat['id_alat'])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: FittedBox(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // Widget _chip & _getKategoriName tetap sama seperti kode Anda sebelumnya...
  Widget _chip(String label, int? id) {
    final active = selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => selectedCategory = id),
        selectedColor: AppColors.darkblue,
        backgroundColor: Colors.white,
        showCheckmark: false,
        labelStyle: TextStyle(
            color: active ? Colors.white : AppColors.darkblue, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.darkblue),
        ),
      ),
    );
  }

  Widget _getKategoriName(int? kategoriId) {
    if (kategoriId == null)
      return const Text("-", style: TextStyle(fontSize: 10));
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('kategori').select().eq('id_kategori', kategoriId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Text(snapshot.data![0]['nama_kategori'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54));
        }
        return const Text("...", style: TextStyle(fontSize: 10));
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text("Hapus",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah anda yakin ingin menghapus alat?",
            textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () async {
                await supabase.from('alat').delete().eq('id_alat', id);
                if (mounted) Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue),
              child: const Text("Iya", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

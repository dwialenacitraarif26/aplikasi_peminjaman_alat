import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'category_screen.dart';
import 'add_alat_screen.dart';

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
    return supabase
        .from('alat')
        .stream(primaryKey: ['id_alat'])
        .order('nama_alat')
        .map((data) {
      return data.where((alat) {
        final matchSearch = alat['nama_alat']
            .toString()
            .toLowerCase()
            .contains(search.toLowerCase());
        final matchCat =
            selectedCategory == null || alat['kategori_id'] == selectedCategory;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// BODY
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Kategori"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkblue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    .stream(primaryKey: ['id_kategori'])
                    .order('nama_kategori'),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip("All", null),
                        ...list.map(
                          (e) => _chip(
                            e['nama_kategori'],
                            e['id_kategori'],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              /// GRID ALAT
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: alatStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Tidak ada alat"),
                      );
                    }

                    return GridView.builder(
                      itemCount: snapshot.data!.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemBuilder: (context, index) {
                        return _alatCard(snapshot.data![index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      /// FAB TAMBAH ALAT
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.darkblue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAlatScreen()),
          );
        },
      ),
    );
  }

  /// CHIP FILTER
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
          color: active ? Colors.white : AppColors.darkblue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.darkblue),
        ),
      ),
    );
  }

  /// CARD ALAT
  Widget _alatCard(Map<String, dynamic> alat) {
    return GestureDetector(
      onTap: () {
        // nanti ke detail_alat_screen
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD1E4F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            /// GAMBAR
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: alat['foto_url'] != null
                      ? Image.network(
                          alat['foto_url'],
                          fit: BoxFit.contain,
                        )
                      : const Icon(Icons.image, size: 40),
                ),
              ),
            ),

            /// NAMA ALAT (RATA KIRI)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  alat['nama_alat'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkblue,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            /// KATEGORI & STOK
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _getKategoriName(alat['kategori_id']),
                  Text(
                    "Stok ${alat['stok_total']}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            /// BUTTON EDIT & HAPUS
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  _btn(
                    "Edit",
                    AppColors.darkblue,
                    () {
                      // ke edit_alat_screen
                    },
                  ),
                  const SizedBox(width: 8),
                  _btn(
                    "Hapus",
                    const Color(0xFF3F51B5),
                    () {
                      _confirmDelete(alat['id_alat']);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AMBIL NAMA KATEGORI DARI DATABASE
  Widget _getKategoriName(int? kategoriId) {
    if (kategoriId == null) {
      return const Text("-", style: TextStyle(fontSize: 11));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('kategori')
          .stream(primaryKey: ['id_kategori'])
          .eq('id_kategori', kategoriId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Text(
            snapshot.data![0]['nama_kategori'],
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          );
        }
        return const Text("-", style: TextStyle(fontSize: 11));
      },
    );
  }

  /// BUTTON
  Widget _btn(String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// DIALOG HAPUS
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Hapus",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Apakah anda yakin ingin menghapus alat?",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkblue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Batal",
                style: TextStyle(color: AppColors.darkblue),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () async {
                await supabase.from('alat').delete().eq('id_alat', id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Iya",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

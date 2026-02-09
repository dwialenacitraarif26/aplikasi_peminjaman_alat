import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../tabs/cart_controller.dart';
import '../../peminjam/tabs/transaksi_pinjaman_screen.dart';

class AlatPeminjamTab extends StatefulWidget {
  const AlatPeminjamTab({super.key});

  @override
  State<AlatPeminjamTab> createState() => _AlatPeminjamTabState();
}

class _AlatPeminjamTabState extends State<AlatPeminjamTab> {
  final supabase = Supabase.instance.client;
  String search = '';
  int? selectedCategory;

  Map<int, String> categoryMap = {};

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
              const SizedBox(height: 20),

              /// HEADER & KERANJANG
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daftar Alat",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkblue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransaksiPinjamanScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        const Icon(Icons.shopping_cart,
                            size: 26, color: AppColors.darkblue),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: ValueListenableBuilder(
                            valueListenable: CartController.items,
                            builder: (context, value, _) {
                              if (value.isEmpty) return const SizedBox();
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.bluesoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  value.length.toString(),
                                  style: const TextStyle(
                                    color: AppColors.darkblue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 12),

              /// FILTER KATEGORI (Horizontal)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('kategori')
                    .stream(primaryKey: ['id_kategori']).order('nama_kategori'),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];

                  // Sinkronisasi nama kategori ke Map agar Card bisa ambil secara instan
                  for (var cat in list) {
                    categoryMap[cat['id_kategori']] = cat['nama_kategori'];
                  }

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

              const SizedBox(height: 16),

              /// GRID DAFTAR ALAT
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: alatStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(child: Text("Tidak ada alat"));
                    }
                    return GridView.builder(
                      itemCount: snapshot.data!.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.76,
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
    );
  }

  Widget _alatCard(Map<String, dynamic> alat) {
    final bool tersedia = (alat['stok_total'] ?? 0) > 0;
    final String namaKategori = categoryMap[alat['kategori_id']] ?? "-";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// GAMBAR ALAT
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: alat['foto_url'] != null
                    ? Image.network(
                        alat['foto_url'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 36, color: Colors.grey),
                      )
                    : const Icon(Icons.image_outlined,
                        size: 36, color: Colors.grey),
              ),
            ),
          ),

          /// NAMA ALAT & TOMBOL TAMBAH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alat['nama_alat'] ?? "Tanpa Nama",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkblue,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: tersedia
                      ? () {
                          CartController.addItem(alat);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${alat['nama_alat']} ditambah"),
                              duration: const Duration(milliseconds: 700),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          tersedia ? AppColors.darkblue : Colors.grey.shade400,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          /// NAMA KATEGORI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              namaKategori,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),

          const SizedBox(height: 8),

          /// LABEL STATUS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tersedia ? AppColors.bluesoft : const Color(0xFFFFD6D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tersedia ? "Tersedia" : "Kosong",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tersedia ? Colors.white : const Color(0xFF86160E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}

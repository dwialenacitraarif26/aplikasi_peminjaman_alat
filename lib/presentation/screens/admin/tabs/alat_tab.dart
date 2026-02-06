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
  String searchQuery = '';
  int? selectedCategoryId;

  Stream<List<Map<String, dynamic>>> _getAlatStream() {
    return supabase
        .from('alat')
        .stream(primaryKey: ['id_alat'])
        .order('nama_alat', ascending: true)
        .map((maps) {
          return maps.where((alat) {
            final matchesSearch =
                alat['nama_alat'].toString().toLowerCase().contains(searchQuery.toLowerCase());
            final matchesCategory =
                selectedCategoryId == null || alat['kategori_id'] == selectedCategoryId;
            return matchesSearch && matchesCategory;
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
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Daftar Alat",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkblue),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Kategori"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 15),
              _buildCategoryFilter(),
              const SizedBox(height: 20),
              Expanded(child: _buildAlatGrid()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.darkblue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAlatScreen()));
          if (mounted) setState(() {}); 
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFF0D1B4E), borderRadius: BorderRadius.circular(30)),
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
            hintText: "search...",
            hintStyle: TextStyle(color: Colors.white70),
            icon: Icon(Icons.search, color: Colors.white),
            border: InputBorder.none),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']).order('nama_kategori'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final categories = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip("All", null),
              ...categories.map((cat) => _filterChip(cat['nama_kategori'], cat['id_kategori'])),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, int? id) {
    bool isSelected = selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => selectedCategoryId = id),
        selectedColor: AppColors.darkblue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.darkblue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.darkblue)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildAlatGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getAlatStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Tidak ada alat"));
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildAlatCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildAlatCard(Map<String, dynamic> alat) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFD1E4F3), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: alat['foto_url'] != null
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.network(alat['foto_url'], fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(alat['nama_alat'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menggunakan StreamBuilder agar label kategori juga real-time
                Flexible(child: _getCategoryLabelRealtime(alat['kategori_id'])),
                Text("Stok ${alat['stok_total']}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Row(
              children: [
                _actionBtn("Edit", AppColors.darkblue, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => AddAlatScreen(alat: alat)));
                  if (mounted) setState(() {}); 
                }),
                const SizedBox(width: 8),
                _actionBtn("Hapus", const Color(0xFF3F51B5), () => _confirmDelete(alat['id_alat'])),
              ],
            ),
          )
        ],
      ),
    );
  }

  // REKOMENDASI: Gunakan Stream agar label langsung berubah saat kategori dihapus/tambah
  Widget _getCategoryLabelRealtime(int? categoryId) {
    if (categoryId == null) return const Text("-", style: TextStyle(fontSize: 11));
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']).eq('id_kategori', categoryId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Text(
            snapshot.data![0]['nama_kategori'], 
            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          );
        }
        // Jika snapshot kosong, berarti kategori dengan ID tersebut sudah dihapus
        return const Text("-", style: TextStyle(fontSize: 11, color: Colors.redAccent));
      },
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah anda yakin ingin menghapus alat?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkblue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Batal", style: TextStyle(color: AppColors.darkblue)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () async {
                await supabase.from('alat').delete().eq('id_alat', id);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Iya", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
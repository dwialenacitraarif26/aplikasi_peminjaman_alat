import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daftar Kategori",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // DAFTAR KATEGORI (REALTIME STREAM)
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                // Menambahkan .order agar saat diedit posisi tidak berpindah-pindah
                stream: supabase
                    .from('kategori')
                    .stream(primaryKey: ['id_kategori'])
                    .order('id_kategori', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final categories = snapshot.data!;
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) => _categoryTile(categories[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            
            // FORM TAMBAH KATEGORI
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Nama Kategori",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.darkblue))),
            const SizedBox(height: 10),
            TextField(
              controller: _addController,
              decoration: InputDecoration(
                hintText: "Masukkan nama kategori",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkblue,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("Tambahkan",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain Item Kategori
  Widget _categoryTile(Map<String, dynamic> cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFD1E4F3), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cat['nama_kategori'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkblue)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.darkblue),
                onPressed: () => _showEditDialog(cat),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.darkblue),
                onPressed: () => _confirmDeleteCat(cat['id_kategori']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fungsi Tambah Data
  Future<void> _addCategory() async {
    if (_addController.text.isNotEmpty) {
      try {
        await supabase.from('kategori').insert({'nama_kategori': _addController.text});
        _addController.clear();
        if (mounted) FocusScope.of(context).unfocus();
      } catch (e) {
        debugPrint("Tambah gagal: $e");
      }
    }
  }

  // Pop-up Edit Kategori
  void _showEditDialog(Map<String, dynamic> cat) {
    _editController.text = cat['nama_kategori'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text("Edit Kategori",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
            ),
            GestureDetector(
                onTap: () => Navigator.pop(context), 
                child: const Icon(Icons.close)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await supabase.from('kategori').update(
                        {'nama_kategori': _editController.text}).eq(
                        'id_kategori', cat['id_kategori']);
                    
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Update gagal: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkblue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Pop-up Hapus
  void _confirmDeleteCat(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus",
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah anda yakin ingin menghapus kategori?",
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkblue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Batal", style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.from('kategori').delete().eq('id_kategori', id);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  debugPrint("Hapus gagal: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkblue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Iya", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
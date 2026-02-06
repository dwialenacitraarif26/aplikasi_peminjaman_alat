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
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daftar Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.darkblue), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('kategori').stream(primaryKey: ['id_kategori']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => _categoryTile(snapshot.data![index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const Align(alignment: Alignment.centerLeft, child: Text("Nama Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue))),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
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
                onPressed: () async {
                  if (_controller.text.isNotEmpty) {
                    await supabase.from('kategori').insert({'nama_kategori': _controller.text});
                    _controller.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Tambahkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(Map<String, dynamic> cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFD1E4F3), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cat['nama_kategori'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkblue)),
          IconButton(icon: const Icon(Icons.delete, color: AppColors.darkblue), onPressed: () => _confirmDeleteCat(cat['id_kategori'])),
        ],
      ),
    );
  }

  void _confirmDeleteCat(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah anda yakin ingin menghapus kategori?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.black))),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('kategori').delete().eq('id_kategori', id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkblue),
            child: const Text("Iya", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
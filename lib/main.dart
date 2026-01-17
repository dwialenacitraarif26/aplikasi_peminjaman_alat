import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // 1. Inisialisasi binding Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hubungkan ke Supabase (Ganti dengan URL & Key milikmu)
  await Supabase.initialize(
    url: 'https://adfupekolkxqkfhacymw.supabase.co',
    anonKey: 'sb_publishable_VoGiNPpbp-IwnM_nutff2w_dni3aFA9',
  );

  runApp(const MyApp());
}

// Shortcut untuk memanggil Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestKoneksiPage(),
    );
  }
}

class TestKoneksiPage extends StatelessWidget {
  const TestKoneksiPage({super.key});

  // Fungsi untuk mengambil data mentah dari tabel alat
  Future<List<Map<String, dynamic>>> fetchAlat() async {
    final data = await supabase.from('alat').select('*');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SIMBARA - Tes Koneksi"),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAlat(),
        builder: (context, snapshot) {
          // Kondisi saat sedang loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Kondisi jika terjadi error (URL salah, Tabel belum ada, atau RLS aktif)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
              ),
            );
          }

          // Kondisi jika data berhasil diambil
          final dataAlat = snapshot.data ?? [];

          if (dataAlat.isEmpty) {
            return const Center(child: Text("Koneksi Sukses!\nTapi tabel 'alat' masih kosong."));
          }

          return ListView.builder(
            itemCount: dataAlat.length,
            itemBuilder: (context, index) {
              final item = dataAlat[index];
              return ListTile(
                leading: const Icon(Icons.inventory, color: Colors.blue),
                title: Text(item['nama_alat'] ?? 'Tanpa Nama'),
                subtitle: Text("Stok: ${item['stok_total']}"),
              );
            },
          );
        },
      ),
    );
  }
}
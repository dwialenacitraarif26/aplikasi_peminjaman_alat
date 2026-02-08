import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'add_pengguna_screen.dart';
import 'edit_pengguna_screen.dart';

class PenggunaTab extends StatefulWidget {
  const PenggunaTab({super.key});

  @override
  State<PenggunaTab> createState() => _PenggunaTabState();
}

class _PenggunaTabState extends State<PenggunaTab> {
  final supabase = Supabase.instance.client;
  String _selectedRole = 'Admin'; // Default filter sesuai gambar
  String _searchQuery = '';

  // Stream untuk mendapatkan data user secara real-time berdasarkan role
  Stream<List<Map<String, dynamic>>> _getUsersStream() {
  // Gunakan stream langsung ke tabel
  return supabase
      .from('users')
      .stream(primaryKey: ['id_user']) // Pastikan ini nama kolom primary key di DB
      .order('nama', ascending: true)
      .map((data) {
        // Filter di sisi client
        return data.where((user) {
          final matchesRole = user['role'].toString().toLowerCase() == _selectedRole.toLowerCase();
          final matchesSearch = user['nama'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesRole && matchesSearch;
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
            children: [
              const SizedBox(height: 20),
              const Text(
                "Manajemen Pengguna",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkblue,
                ),
              ),
              const SizedBox(height: 20),

              /// --- SEARCH BAR ---
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkblue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "search...",
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// --- ROLE FILTER (Admin, Petugas, Peminjam) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roleFilterBtn("Admin"),
                  _roleFilterBtn("Petugas"),
                  _roleFilterBtn("Peminjam"),
                ],
              ),
              const SizedBox(height: 20),

              /// --- LIST USER ---
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Tidak ada pengguna ditemukan"));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _userCard(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      /// --- FLOATING ACTION BUTTON (TAMBAH USER) ---
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPenggunaScreen()),
          );
        },
        backgroundColor: AppColors.darkblue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  /// --- WIDGET HELPER: ROLE FILTER BUTTON ---
  Widget _roleFilterBtn(String role) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkblue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkblue),
        ),
        child: Text(
          role,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkblue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// --- WIDGET HELPER: USER CARD ---
  Widget _userCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.darkblue, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined, size: 45, color: AppColors.darkblue),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              user['nama'] ?? "Tanpa Nama",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkblue,
              ),
            ),
          ),
          // --- BAGIAN YANG DIUBAH: TOMBOL EDIT ---
        IconButton(
          icon: const Icon(Icons.edit, color: AppColors.darkblue),
          onPressed: () {
            // Navigasi ke halaman Edit dengan membawa data 'user'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPenggunaScreen(user: user),
              ),
            );
          },
        ),
        
        IconButton(
          icon: const Icon(Icons.delete, color: AppColors.darkblue),
          onPressed: () => _confirmDelete(user['id_user'], user['nama']),
        ),
      ],
    ),
  );
}

  /// --- LOGIKA DELETE (Disesuaikan dengan Desain Gambar) ---
  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Hapus",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkblue,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Apakah anda yakin ingin\nmenghapus pengguna?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkblue,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tombol Batal (Outline)
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkblue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    child: const Text(
                      "Batal",
                      style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Tombol Iya (Filled)
                  ElevatedButton(
                    onPressed: () async {
                      await supabase.from('users').delete().eq('id_user', id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkblue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    ),
                    child: const Text(
                      "Iya",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
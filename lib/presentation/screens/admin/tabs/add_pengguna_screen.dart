import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class AddPenggunaScreen extends StatefulWidget {
  const AddPenggunaScreen({super.key});

  @override
  State<AddPenggunaScreen> createState() => _AddPenggunaScreenState();
}

class _AddPenggunaScreenState extends State<AddPenggunaScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  String? _selectedRole; 
  bool _obscureText = true;
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'petugas', 'peminjam'];

Future<void> _handleTambah() async {
  // Validasi awal agar tidak ada field kosong
  if (!_formKey.currentState!.validate() || _selectedRole == null) return;

  setState(() => _isLoading = true);

  try {
    // LANGKAH 1: Daftarkan User ke Authentication (Akun Login)
    final AuthResponse res = await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
    );

    if (res.user != null) {
      // LANGKAH 2: Simpan Data ke Tabel 'users' secara manual
      // Karena trigger database sudah dihapus, bagian ini WAJIB ada
      await supabase.from('users').insert({
        'id_user': res.user!.id,               // Mengambil ID dari akun yang baru dibuat
        'email': _emailController.text.trim(),
        'nama': _namaController.text.trim(),
        'role': _selectedRole!.toLowerCase(),  // Mengambil role dari pilihan dropdown
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengguna berhasil ditambahkan!")),
        );
        Navigator.pop(context); // Kembali ke halaman daftar
      }
    }
  } on AuthException catch (e) {
    // Menangkap error jika email sudah terdaftar atau password terlalu lemah
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal: ${e.message}"), backgroundColor: Colors.red),
    );
  } catch (e) {
    debugPrint("Error: $e");
    // Penanganan jika terjadi error duplikat atau koneksi
    if (e.toString().contains('23505') && mounted) {
      Navigator.pop(context);
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Pengguna",
          style: TextStyle(color: AppColors.darkblue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Ikon profil tanpa latar belakang (outlined)
              const Center(
                child: Icon(
                  Icons.account_circle_outlined, 
                  size: 130, 
                  color: AppColors.darkblue
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Nama"),
              _buildTextField(_namaController, "Masukkan nama pengguna"),

              const SizedBox(height: 15),
              _buildLabel("Email"),
              _buildTextField(_emailController, "Masukkan email pengguna", isEmail: true),

              const SizedBox(height: 15),
              _buildLabel("Password"),
              _buildPasswordField(),

              const SizedBox(height: 15),
              _buildLabel("Sebagai"),
              _buildDropdownField(),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTambah,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Tambahkan", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkblue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(hint),
      // Validasi langsung di field
      validator: (val) => val == null || val.isEmpty ? "wajib diisi" : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passController,
      obscureText: _obscureText,
      decoration: _inputDecoration("Masukkan password").copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.darkblue),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Password wajib diisi";
        if (val.length < 6) return "Minimal 6 karakter";
        return null;
      },
    );
  }

Widget _buildDropdownField() {
  return DropdownButtonFormField<String>(
    value: _selectedRole,
    hint: const Text("--- Pilih Sebagai ---", style: TextStyle(fontSize: 14)),
    
    // INI YANG MEMBUAT KOTAK BIRU MUNCUL LAGI
    decoration: _inputDecoration(""), 
    
    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3F51B5)), // Warna biru tombol
    items: _roles.map((r) => DropdownMenuItem(
      value: r,
      child: Text(r[0].toUpperCase() + r.substring(1)), // Contoh: 'admin' jadi 'Admin'
    )).toList(),
    onChanged: (val) {
      setState(() {
        _selectedRole = val;
      });
    },
    validator: (val) => val == null ? "Silakan pilih role" : null,
  );
}
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkblue, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkblue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
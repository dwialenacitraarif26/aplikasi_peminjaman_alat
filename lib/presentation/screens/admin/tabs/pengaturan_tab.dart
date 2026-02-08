import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class PengaturanTab extends StatefulWidget {
  const PengaturanTab({super.key});

  @override
  State<PengaturanTab> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanTab> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _obscurePassword = true; // State untuk kontrol mata password

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fungsi mengambil data user asli dari tabel public.users
  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('users')
            .select()
            .eq('id_user', user.id)
            .single();
        
        setState(() {
          userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Logout",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue),
        ),
        content: const Text("Apakah anda yakin ingin keluar aplikasi?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.darkblue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Tidak", style: TextStyle(color: AppColors.darkblue)),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkblue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Ya", style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              "Pengaturan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkblue),
            ),
            const SizedBox(height: 30),
            const Center(child: Icon(Icons.account_circle_outlined, size: 100, color: AppColors.darkblue)),
            const SizedBox(height: 30),

            // DATA DIAMBIL DARI DATABASE (userData)
            _buildInfoField("Nama", userData?['nama'] ?? "-"),
            const SizedBox(height: 15),
            _buildInfoField("Email", userData?['email'] ?? "-"),
            const SizedBox(height: 15),
            
            // PASSWORD DENGAN FITUR TOGGLE MATA
            _buildPasswordField("Password", "********"), // Supabase Auth tidak mengembalikan password plain teks demi keamanan
            
            const SizedBox(height: 15),
            _buildInfoField("Sebagai", userData?['role']?.toString().toUpperCase() ?? "-"),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, color: AppColors.white),
                label: const Text("Logout", style: TextStyle(color: AppColors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Field Biasa (Nama, Email, Role)
  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            fillColor: AppColors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkblue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Khusus Field Password agar Icon Mata berfungsi
  Widget _buildPasswordField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkblue)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            fillColor: AppColors.white,
            filled: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.darkblue,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkblue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
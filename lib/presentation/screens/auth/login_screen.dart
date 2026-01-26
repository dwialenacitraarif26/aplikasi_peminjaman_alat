import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authLogic = AuthController();
  bool _isObscure = true;
  bool _isLoading = false;

  // Fungsi untuk menangani proses login
  void _handleLogin() async {
    // 1. Validasi input kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Email dan Password tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // 2. Memanggil logika AuthController (Mengambil Role dari Database)
    final result = await _authLogic.signIn(
      _emailController.text.trim(), 
      _passwordController.text.trim()
    );

    setState(() => _isLoading = false);

    if (result == null) return;

    if (result.startsWith('error:')) {
      // Jika terjadi error dari Supabase
      _showSnackBar(result.split(':')[1], isError: true);
    } else {
      // Jika sukses, result berisi nama role ('admin', 'petugas', atau 'peminjam')
      _navigateToDashboard(result);
    }
  }

  // Fungsi navigasi berdasarkan role
  void _navigateToDashboard(String role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("SIMBARA - ${role.toUpperCase()}"),
            backgroundColor: AppColors.primary,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role == 'admin' ? Icons.admin_panel_settings : 
                  role == 'petugas' ? Icons.engineering : Icons.person,
                  size: 100, 
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  "Selamat Datang di Halaman $role",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                  child: const Text("Logout"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), 

              // Logo Login
              Center(
                child: Image.asset(
                  'assets/images/login.png',
                  width: 150, 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.image, size: 50, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 50), 
              const Text(
                'Haii!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Welcome to SIMBARA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 35),

              // Input E-mail
              _buildInput(
                hint: "E-mail",
                icon: Icons.email,
                controller: _emailController,
              ),
              const SizedBox(height: 30),

              // Input Password
              _buildInput(
                hint: "Password",
                icon: Icons.lock,
                controller: _passwordController,
                isPass: true,
              ),

              const SizedBox(height: 45),

              // Button Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0), // Tidak ada radius
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPass = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.inputBg, // Warna D0E4FF
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _isObscure : false,
        style: const TextStyle(color: AppColors.darkblue, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.primary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_controller.dart';
import '../admin/admin_dashboard.dart';
import '../petugas/petugas_dashboard.dart';
import '../peminjam/peminjam_dashboard.dart';

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
  String? _emailError;

  void _handleLogin() async {
    setState(() {
      _emailError = null;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Email dan Password tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authLogic.signIn(
        _emailController.text.trim(), _passwordController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) return;

    if (result.startsWith('error:')) {
      setState(() {
        _emailError = "Email atau Password salah";
      });
    } else {
      // Navigasi ke dashboard jika sukses
      _navigateToDashboard(result);
    }
  }

  void _navigateToDashboard(String role) {
    Widget page;

    // Menentukan halaman tujuan berdasarkan role
    switch (role.toLowerCase()) {
      case 'admin':
        page = const AdminDashboard();
        break;
      case 'petugas':
        page = const PetugasDashboard();
        break;
      case 'peminjam':
        page = const PeminjamDashboard();
        break;
      default:
        _showSnackBar("Role tidak dikenali", isError: true);
        return;
    }

    // PERBAIKAN: Menambahkan Navigator agar benar-benar berpindah halaman
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
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
              Center(
                child: Image.asset(
                  'assets/images/login.png',
                  width: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image,
                      size: 50,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 50),
              const Text('Haii!',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
              const Text('Welcome to SIMBARA',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
              const SizedBox(height: 35),
              _buildInput(
                hint: "E-mail",
                icon: Icons.email,
                controller: _emailController,
                errorText: _emailError,
              ),
              const SizedBox(height: 30),
              _buildInput(
                hint: "Password",
                icon: Icons.lock,
                controller: _passwordController,
                isPass: true,
              ),
              const SizedBox(height: 45),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
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
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          // PERBAIKAN: Menghilangkan border merah, hanya warna background saja
          decoration: const BoxDecoration(
            color: AppColors.inputBg,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPass ? _isObscure : false,
            style: const TextStyle(color: AppColors.primary, fontSize: 15),
            onChanged: (value) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.primary),
              prefixIcon: Icon(icon, color: AppColors.primary),
              suffixIcon: isPass
                  ? IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.primary),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Text(
              errorText,
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

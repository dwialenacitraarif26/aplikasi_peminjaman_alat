import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Library kunci untuk Native Pop-up
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

  // ================= GOOGLE LOGIN NATIVE (FIXED) =================
  // Fungsi ini akan memunculkan pop-up akun Google langsung di HP/Simulator
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. Konfigurasi Google Sign-In
      // GANTI 'YOUR_WEB_CLIENT_ID' dengan Client ID dari Google Cloud Console / Firebase Settings
      const webClientId = 'MASUKKAN_WEB_CLIENT_ID_KAMU_DISINI.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      // 2. Trigger Pop-up Native
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User membatalkan pilihan akun
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw 'ID Token tidak ditemukan!';

      // 3. Daftarkan kredensial ke Supabase
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        _showSnackBar("Login Berhasil!");
        // Redirect ke dashboard peminjam sebagai default
        _navigateToDashboard("peminjam");
      }
    } catch (e) {
      print("Error Detail: $e");
      _showSnackBar("Gagal memunculkan pop-up login: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ==============================================================

  void _handleLogin() async {
    setState(() => _emailError = null);

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
      setState(() => _emailError = "Email atau Password salah");
    } else {
      _navigateToDashboard(result);
    }
  }

  void _navigateToDashboard(String role) {
    Widget page;
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
              const SizedBox(height: 110),
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

              // TOMBOL LOGIN MANUAL
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // TOMBOL GOOGLE (NATIVE POP-UP)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.login, color: Colors.red),
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
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
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: AppColors.inputBg,
          ),
          child: TextField(
            controller: controller,
            obscureText: isPass ? _isObscure : false,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              suffixIcon: isPass 
                ? IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  )
                : null,
              border: InputBorder.none,
              errorText: errorText,
            ),
          ),
        ),
      ],
    );
  }
}
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
  
  // Variabel untuk menampung pesan error validasi field
  String? _emailError; 

  void _handleLogin() async {
    // Reset error setiap kali tombol ditekan
    setState(() {
      _emailError = null;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Email dan Password tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authLogic.signIn(
      _emailController.text.trim(), 
      _passwordController.text.trim()
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) return;

    if (result.startsWith('error:')) {
      // SET ERROR PADA FIELD EMAIL
      setState(() {
        _emailError = "Email atau Password salah";
      });
    } else {
      _navigateToDashboard(result);
    }
  }

  // ... (Fungsi _navigateToDashboard dan _showSnackBar tetap sama)

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
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.image, size: 50, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 50), 
              const Text('Haii!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const Text('Welcome to SIMBARA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
              
              const SizedBox(height: 35),

              // INPUT EMAIL DENGAN VALIDASI ERROR
              _buildInput(
                hint: "E-mail",
                icon: Icons.email,
                controller: _emailController,
                errorText: _emailError, // Masukkan variabel error di sini
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
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
    String? errorText, // Tambahkan parameter errorText
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.inputBg,
            
          ),
          child: TextField(
            controller: controller,
            obscureText: isPass ? _isObscure : false,
            style: const TextStyle(color: AppColors.primary, fontSize: 15),
            onChanged: (value) {
              // Menghapus pesan error saat user mulai mengetik ulang
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.primary.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: AppColors.primary),
              suffixIcon: isPass
                  ? IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.primary),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        // Tampilkan teks error jika ada
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // Fungsi navigasi dan snackbar (Gunakan versi yang sudah ada sebelumnya)
  void _navigateToDashboard(String role) { /* ... sama seperti kode sebelumnya ... */ }
  void _showSnackBar(String message, {bool isError = false}) { /* ... sama seperti kode sebelumnya ... */ }
}
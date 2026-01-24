import 'package:flutter/material.dart';
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

  void _handleLogin() async {
    final result = await _authLogic.signIn(_emailController.text, _passwordController.text);

    if (result!.startsWith('error:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.split(':')[1]), backgroundColor: Colors.red),
      );
    } else {
      // Navigasi Berdasarkan Role
      Widget destination;
      if (result == 'admin') {
        destination = const Scaffold(body: Center(child: Text('HALAMAN ADMIN', style: TextStyle(fontSize: 24))));
      } else if (result == 'petugas') {
        destination = const Scaffold(body: Center(child: Text('HALAMAN PETUGAS', style: TextStyle(fontSize: 24))));
      } else {
        destination = const Scaffold(body: Center(child: Text('HALAMAN PEMINJAM', style: TextStyle(fontSize: 24))));
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => destination));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo Login
              Center(
                child: Image.asset('assets/images/login.png', width: 140),
              ),
              const SizedBox(height: 40),
              const Text(
                'Haii!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3B59B6)),
              ),
              const Text(
                'Welcome to SIMBARA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF3B59B6)),
              ),
              const SizedBox(height: 30),
              
              // Input E-mail
              _buildInputLabel("E-mail", Icons.email_outlined, _emailController),
              const SizedBox(height: 15),
              
              // Input Password
              _buildInputLabel(
                "Password", 
                Icons.lock_outline, 
                _passwordController, 
                isPass: true
              ),
              
              const SizedBox(height: 40),
              
              // Tombol Login (Biru Tua)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B59B6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 4,
                  ),
                  child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String hint, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDE7FF), // Warna Biru Muda sesuai gambar
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF3B59B6)),
          suffixIcon: isPass 
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF3B59B6)),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
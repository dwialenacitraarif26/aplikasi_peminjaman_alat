import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final _client = Supabase.instance.client;

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Logika sederhana: Cek domain email atau field role di database
        // Di sini kita gunakan contoh pengecekan teks email sesuai permintaanmu
        if (email.contains('admin')) return 'admin';
        if (email.contains('petugas')) return 'petugas';
        return 'peminjam'; 
      }
    } on AuthException catch (e) {
      return 'error:${e.message}';
    }
    return 'error:Gagal Login';
  }
}
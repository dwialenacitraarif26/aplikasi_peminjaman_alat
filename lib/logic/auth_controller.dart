import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final _client = Supabase.instance.client;

  // Fungsi Login dan Ambil Role
  Future<String?> signIn(String email, String password) async {
    try {
      // 1. Login ke Auth Supabase
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // 2. Ambil data role dari tabel 'users' di public schema
        final data = await _client
            .from('users')
            .select('role')
            .eq('id_user', res.user!.id)
            .single();

        return data['role']; // Mengembalikan 'admin', 'petugas', atau 'peminjam'
      }
    } on AuthException catch (e) {
      return 'error:${e.message}';
    } catch (e) {
      return 'error:Terjadi kesalahan sistem';
    }
    return null;
  }
}
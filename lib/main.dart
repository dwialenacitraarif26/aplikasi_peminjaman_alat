import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'presentation/screens/auth/splas_screen.dart'; // Import splash screen

void main() async {
  // 1. Pastikan binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Koneksi ke Supabase
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMBARA',
      // 3. Tentukan halaman awal aplikasi
      home: const SplashScreen(), 
    );
  }
}
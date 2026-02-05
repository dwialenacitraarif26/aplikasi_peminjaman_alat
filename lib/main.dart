import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/supabase_constants.dart';
import 'presentation/screens/auth/splas_screen.dart'; 
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMBARA',
      theme:  ThemeData(
        // Ini akan mengubah semua teks di aplikasi menjadi Poppins
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      // halaman awal displash
      home: const SplashScreen(), 
    );
  }
}
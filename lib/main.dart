import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/supabase_constants.dart';
import 'presentation/screens/auth/splas_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      
      // Rute statis untuk perpindahan halaman besar
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
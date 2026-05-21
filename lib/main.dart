import 'package:flutter/material.dart';
import 'package:busguide/core/theme/app_theme.dart';
import 'package:busguide/user/supabase/supabase_config.dart';

// Import Screens
import 'package:busguide/user/screens/splash_screen.dart';
import 'package:busguide/user/screens/login.dart';
import 'package:busguide/user/screens/register.dart';
import 'package:busguide/user/screens/halte.dart';
import 'package:busguide/user/screens/home.dart';
import 'package:busguide/user/screens/perizinan.dart';
import 'package:busguide/user/screens/profil.dart';
import 'package:busguide/user/screens/rekomendasi.dart';
import 'package:busguide/user/screens/detail_wisata.dart';
import 'package:busguide/user/screens/detail_po_bus.dart';
import 'package:busguide/user/templates/bottom_navbar.dart';

// Placeholder Admin Dashboard
class AdminDashboardPlaceholder extends StatelessWidget {
  const AdminDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Halaman Admin Dashboard')));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize(); // Supabase Initialization
  } catch (e) {
    debugPrint('Gagal inisialisasi Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // ─── PENGATURAN ROUTER TERPUSAT ───
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/perizinan': (context) => const PerizinanPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/user': (context) =>
            const MainScreen(), // Menggunakan MainScreen agar BottomNavbar tetap ada
        '/admin': (context) => const AdminDashboardPlaceholder(),
      },
      onGenerateRoute: (settings) {
        // Menangani rute yang membawa argumen (parameter ID)
        if (settings.name == '/detail-wisata') {
          final idWisata = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DetailWisataScreen(idWisata: idWisata),
          );
        }
        if (settings.name == '/detail-po-bus') {
          final idPoBus = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DetailPoBusScreen(idPoBus: idPoBus),
          );
        }
        return null; // Kembalikan null jika rute tidak cocok
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HalteScreen(),
    const Scaffold(body: Center(child: Text('Navigasi'))),
    const RekomendasiScreen(),
    const ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busguide/core/theme/app_theme.dart';
import 'package:busguide/models/supabase_config.dart';

// Import Screens
import 'package:busguide/views/splash_screen.dart';
import 'package:busguide/views/login.dart';
import 'package:busguide/views/register.dart';
import 'package:busguide/views/halte.dart';
import 'package:busguide/views/navigasi.dart';
import 'package:busguide/views/navigasi_aktif.dart';
import 'package:busguide/views/home.dart';
import 'package:busguide/views/perizinan.dart';
import 'package:busguide/views/profil.dart';
import 'package:busguide/views/rekomendasi.dart';
import 'package:busguide/views/detail_wisata.dart';
import 'package:busguide/views/detail_po_bus.dart';
import 'package:busguide/views/riwayat_perjalanan.dart';
import 'package:busguide/templates/bottom_navbar.dart';

// Import Controllers (MVC Layer)
import 'package:busguide/controllers/auth_controller.dart';
import 'package:busguide/controllers/home_controller.dart';
import 'package:busguide/controllers/halte_controller.dart';
import 'package:busguide/controllers/navigasi_controller.dart';
import 'package:busguide/controllers/navigasi_aktif_controller.dart';
import 'package:busguide/controllers/rekomendasi_controller.dart';
import 'package:busguide/controllers/profil_controller.dart';
import 'package:busguide/controllers/riwayat_controller.dart';
import 'package:busguide/controllers/detail_wisata_controller.dart';
import 'package:busguide/controllers/detail_po_bus_controller.dart';

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
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Gagal inisialisasi Supabase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => HalteController()),
        ChangeNotifierProvider(create: (_) => NavigasiController()),
        ChangeNotifierProvider(create: (_) => NavigasiAktifController()),
        ChangeNotifierProvider(create: (_) => RekomendasiController()),
        ChangeNotifierProvider(create: (_) => ProfilController()),
        ChangeNotifierProvider(create: (_) => RiwayatController()),
        ChangeNotifierProvider(create: (_) => DetailWisataController()),
        ChangeNotifierProvider(create: (_) => DetailPoBusController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/perizinan': (context) => const PerizinanPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/navigasi': (context) => const NavigasiScreen(),
        '/navigasi_aktif': (context) => const NavigasiAktifScreen(),
        '/riwayat': (context) => const RiwayatPerjalananScreen(),
        '/user': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialIndex = args is int ? args : 0;
          return MainScreen(initialIndex: initialIndex);
        },
        '/admin': (context) => const AdminDashboardPlaceholder(),
      },
      onGenerateRoute: (settings) {
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
        return null;
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // TabSwitcher di-wrap di sini agar semua child screen bisa akses
    return TabSwitcher( 
      switchTab: _switchTab,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            HalteScreen(),
            NavigasiScreen(),
            RekomendasiScreen(),
            ProfilScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavbar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
        ),
      ),
    );
  }
}
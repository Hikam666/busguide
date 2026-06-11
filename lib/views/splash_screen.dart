import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/auth_service.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin { // Mixin ini wajib untuk menjalankan animasi (vsync)
  late AnimationController _controller; // Controller untuk mengatur durasi dan status animasi
  late Animation<double> _fadeAnimation;  // Animasi untuk efek memudar (muncul perlahan)
  late Animation<double> _scaleAnimation; // Animasi untuk efek membesar (zoom in)

  final _authService = AuthService();  // Membuat instance/objek dari AuthService

  @override
  void initState() {
    super.initState(); // Memanggil initState bawaan Flutter

    // Membuat controller animasi dengan durasi 1.2 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animasi transisi memudar (tembus pandang ke terlihat jelas)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),  // Animasi dimainkan pada 60% waktu pertama
      ),
    );

    // Animasi skala/zoom in (dari kecil ke ukuran asli)
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Cek session setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 2000), _cekPerizinanDanSession);
  }

  Future<void> _cekPerizinanDanSession() async {
    // 1. Cek izin lokasi GPS saat ini
      // BARIS 1: Meminta plugin Geolocator untuk mengecek status izin GPS saat ini di HP pengguna.
    // Hasilnya bisa berupa: always (selalu), whileInUse (saat aplikasi dipakai), denied (ditolak), dll.
    LocationPermission permission = await Geolocator.checkPermission();
    // Mencegah error jika widget keburu ditutup sebelum proses selesai
    if (!mounted) return;
    // BARIS 3: Cek apakah izin "ditolak" (belum pernah ditanya/ditolak sekali) 
    // ATAU "ditolak permanen" (pengguna menceklis 'jangan tanya lagi').
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Jika belum ada izin -> paksa ke halaman perizinan secara permanen
      Navigator.pushReplacementNamed(context, '/perizinan');
      return;
    }

    // 2. Jika sudah ada izin, cek apakah user punya sesi login yang masih aktif
    final session = await _authService.getActiveSession();
    if (!mounted) return;

    if (session == null) {
      // Jika session null (belum login), arahkan ke halaman Login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Jika sudah login, baca role untuk menentukan dashboard
      final role = session['role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151E2D),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LogoApp(),
              const SizedBox(height: 24),
              const _NamaApp(),
              const SizedBox(height: 8),
              const _SloganApp(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG (DI FILE YANG SAMA)
// ==========================================

class _LogoApp extends StatelessWidget {
  const _LogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9EF5).withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset('assets/img/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _NamaApp extends StatelessWidget {
  const _NamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'BusGuide',
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _SloganApp extends StatelessWidget {
  const _SloganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Navigasi bus yang mudah',
      style: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 14,
        color: const Color(0xFF7A8FA6),
      ),
    );
  }
}
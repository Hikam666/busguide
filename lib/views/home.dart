import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:busguide/core/theme/app_colors.dart';
import 'package:busguide/controllers/home_controller.dart';
import 'package:busguide/controllers/navigasi_controller.dart';
import 'package:busguide/controllers/navigasi_aktif_controller.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/wisata.dart';
import '../templates/notification_sheet.dart';

// ==========================================
// INHERITED WIDGET — tab switcher dari MainScreen
// ==========================================
class TabSwitcher extends InheritedWidget {
  final void Function(int index) switchTab;

  const TabSwitcher({
    super.key,
    required this.switchTab,
    required super.child,
  });

  static TabSwitcher? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSwitcher>();

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark, // iOS
        ),
        child: Consumer<HomeController>(
          builder: (context, ctrl, _) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroHeader(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _QuickActions(),
                      const SizedBox(height: 28),
                      
                      // Active Trip Activity Card
                      if (ctrl.adaPerjalananAktif) ...[
                        _ActiveTripCard(perjalanan: ctrl.perjalananAktif!),
                        const SizedBox(height: 28),
                      ],
                      
                      // Riwayat Perjalanan
                      _SectionHeader(
                        title: 'Riwayat perjalanan',
                        actionLabel: 'Lihat Semua',
                        onAction: () => Navigator.pushNamed(context, '/riwayat'),
                      ),
                      const SizedBox(height: 12),

                      if (ctrl.isLoading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator()))
                      else if (ctrl.riwayatList.isEmpty)
                        const Text('Belum ada riwayat perjalanan.',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...ctrl.riwayatList.map((riwayat) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TripCard(perjalanan: riwayat),
                            )),
                      const SizedBox(height: 28),

                      // Rekomendasi Wisata
                      const Text(
                        'Rekomendasi untukmu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (ctrl.isLoading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator()))
                      else
                        _RekomendasiList(data: ctrl.rekomendasiList),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

// ── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final greeting = _getGreetingText();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F3E8C), // Royal blue
            Color(0xFF005EA4), // Accent blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Notification Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BusGuide',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showNotificationBottomSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: hasUnreadNotifications,
                      builder: (context, hasUnread, child) {
                        return Stack(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Greeting Text
          Text(
            greeting.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            greeting.subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 20),
          // Integrated Search Bar inside Hero Header
          const _SearchBar(),
        ],
      ),
    );
  }
}

class _GreetingData {
  final String title;
  final String subtitle;

  const _GreetingData({required this.title, required this.subtitle});
}

_GreetingData _getGreetingText() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) {
    return const _GreetingData(
      title: 'Selamat Pagi!',
      subtitle: 'Siap menjelajah kota dengan bus pagi ini?',
    );
  } else if (hour >= 11 && hour < 15) {
    return const _GreetingData(
      title: 'Selamat Siang!',
      subtitle: 'Mau bepergian kemana di hari yang ini?',
    );
  } else if (hour >= 15 && hour < 19) {
    return const _GreetingData(
      title: 'Selamat Sore! ',
      subtitle: 'Nikmati suasana sore kota Malang bersama BusGuide.',
    );
  } else {
    return const _GreetingData(
      title: 'Selamat Malam!',
      subtitle: 'Pastikan perjalanan pulang Anda aman malam ini.',
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan lokasi tujuan')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    final homeCtrl = context.read<HomeController>();
    final navCtrl = context.read<NavigasiController>();
    final switcher = TabSwitcher.maybeOf(context);

    try {
      final result = await homeCtrl.setupNavigasi(query);

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(homeCtrl.searchError)),
        );
        setState(() => _isSearching = false);
        return;
      }

      navCtrl.pilihHalteAsal(result.halteAsal);
      navCtrl.pilihHalteTujuan(result.halteTujuan);

      _controller.clear();
      setState(() => _isSearching = false);

      if (switcher != null) {
        switcher.switchTab(2); // Tab 2 = NavigasiScreen
      } else {
        Navigator.pushNamed(context, '/user', arguments: 2);
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Color(0xFF334155), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _handleSearch(),
              enabled: !_isSearching,
              decoration: const InputDecoration(
                hintText: 'ketik tujuan mu disini',
                hintStyle: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final switcher = TabSwitcher.maybeOf(context);

    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.location_on_rounded,
          label: 'Halte Terdekat',
          onTap: () {
            if (switcher != null) {
              switcher.switchTab(1);
            } else {
              Navigator.pushNamed(context, '/halte');
            }
          },
        ),
        const SizedBox(width: 12),
        _QuickActionCard(
          icon: Icons.swap_calls_rounded,
          label: 'Cari Rute',
          onTap: () {
            if (switcher != null) {
              switcher.switchTab(2);
            } else {
              Navigator.pushNamed(context, '/user', arguments: 2);
            }
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Live Trip Card — Pelacakan Aktif dengan Background Map Asli ────────────────
class _ActiveTripCard extends StatefulWidget {
  final Perjalanan perjalanan;

  const _ActiveTripCard({required this.perjalanan});

  @override
  State<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends State<_ActiveTripCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _mapController = MapController();
  LatLng? _lastCenteredLoc;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navAktif = context.read<NavigasiAktifController>();
      if (navAktif.perjalananAktif == null) {
        navAktif.loadDataAktif();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.perjalanan.halteAsal?.nama ?? '-';
    final to = widget.perjalanan.halteTujuan?.nama ?? '-';
    final routeCode = widget.perjalanan.rute?.kode ?? '-';
    
    // Watch navigasi aktif controller
    final navAktif = context.watch<NavigasiAktifController>();
    final userLoc = navAktif.lokasiSaatIni;

    // Move map to center on user location if it changes
    if (_lastCenteredLoc != userLoc) {
      _lastCenteredLoc = userLoc;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(userLoc, 15.2);
        } catch (_) {}
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10203B).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Map Area Background
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLoc,
                      initialZoom: 15.2,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.busguide.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLoc,
                            width: 50,
                            height: 50,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.2 * _pulseController.value),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.5 * _pulseController.value),
                                            blurRadius: 8,
                                            spreadRadius: 3 * _pulseController.value,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Dark shadow overlay for map readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  // Bus Route Badge Overlay
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            routeCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pulsing Live Badge Overlay
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.6 * _pulseController.value),
                                      blurRadius: 6,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Area Below Map
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HALTE ASAL',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              from,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 16),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'HALTE TUJUAN',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              to,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/navigasi_aktif');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'buka peta',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip Card — Data Riwayat Perjalanan (Warna Biru untuk Selesai) ────────────
class _TripCard extends StatelessWidget {
  final Perjalanan perjalanan;

  const _TripCard({required this.perjalanan});

  ({String label, Color color, Color bg}) get _statusInfo {
    switch (perjalanan.status) {
      case 'aktif':
        return (
          label: 'Sedang Berlangsung',
          color: AppColors.primary,
          bg: AppColors.surfaceVariant,
        );
      case 'dibatalkan':
        return (
          label: 'Dibatalkan',
          color: AppColors.error,
          bg: const Color(0xFFFFEEEE),
        );
      default: // 'selesai' -> Tetap menggunakan biru seperti sebelumnya
        return (
          label: 'Selesai',
          color: AppColors.primary,
          bg: AppColors.surfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo;
    final isActive = perjalanan.status == 'aktif';

    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.pushNamed(context, '/navigasi_aktif');
        } else {
          Navigator.pushNamed(context, '/riwayat');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (perjalanan.status == 'dibatalkan'
                          ? AppColors.error
                          : AppColors.primary),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _BusBadge(
                            code: perjalanan.rute?.kode ?? '-',
                            isActive: isActive,
                          ),
                          Text(
                            perjalanan.waktuMulaiFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _RouteStops(
                        from: perjalanan.halteAsal?.nama ?? '-',
                        to: perjalanan.halteTujuan?.nama ?? '-',
                        isActive: isActive,
                        isCancelled: perjalanan.status == 'dibatalkan',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (perjalanan.durasiLabel != null) ...[
                                const Icon(Icons.timer_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  perjalanan.durasiLabel!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (perjalanan.riwayat.isNotEmpty)
                                  const Text('  •  ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                              ],
                              if (perjalanan.riwayat.isNotEmpty)
                                Text(
                                  '📍 ${perjalanan.riwayat.length} halte',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusBadge extends StatelessWidget {
  final String code;
  final bool isActive;

  const _BusBadge({required this.code, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_rounded,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStops extends StatelessWidget {
  final String from;
  final String to;
  final bool isActive;
  final bool isCancelled;

  const _RouteStops({
    required this.from,
    required this.to,
    required this.isActive,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive
        ? AppColors.primary
        : (isCancelled ? AppColors.error : AppColors.primary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor,
                  width: 2,
                ),
                color: Colors.white,
              ),
            ),
            Container(
              width: 2,
              height: 20,
              color: activeColor.withValues(alpha: 0.3),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                to,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Rekomendasi List ──────────────────────────────────────────────────────────
class _RekomendasiList extends StatelessWidget {
  final List<Wisata> data;

  const _RekomendasiList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Belum ada rekomendasi.',
          style: TextStyle(color: AppColors.textSecondary));
    }

    return SizedBox(
      height: 258,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _RekomendasiCard(item: data[index]),
      ),
    );
  }
}

class _RekomendasiCard extends StatelessWidget {
  final Wisata item;

  const _RekomendasiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.64;
    final fotoUrl = item.fotoUrl;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/detail-wisata', arguments: item.id),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: fotoUrl != null
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.border, size: 40),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.border, size: 40),
                        ),
                ),
                // Rating wisata di home dihapus sesuai request
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.deskripsi ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.tarif == 0 || item.tarif == null
                              ? 'Gratis'
                              : 'Rp ${item.tarifFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (item.tarif == 0 || item.tarif == null)
                                ? const Color(0xFF2E7D32)
                                : AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Lihat Detail →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
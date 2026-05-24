import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busguide/core/theme/app_colors.dart';
import 'package:busguide/templates/header.dart';
import 'package:busguide/controllers/home_controller.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/wisata.dart';

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
      appBar: AppHeader(
        title: 'BusGuide',
        showNotification: true,
        hasUnreadNotification: true,
        onNotificationTap: () {},
      ),
      body: Consumer<HomeController>(
        builder: (context, ctrl, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(),
              const SizedBox(height: 20),
              _QuickActions(),
              const SizedBox(height: 20),
                if (ctrl.adaPerjalananAktif) ...[
                  _TripCard(perjalanan: ctrl.perjalananAktif!),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 28),

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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

// ── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Buka layar navigasi (tab index 2) dan tampilkan search fokus
        final switcher = TabSwitcher.maybeOf(context);
        if (switcher != null) {
          // Jika ada TabSwitcher (pakai MainScreen), pindah ke tab Navigasi
          switcher.switchTab(2);
        } else {
          // Fallback: push route langsung
          Navigator.pushNamed(context, '/navigasi');
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Mau ke mana hari ini?',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cari Rute',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final switcher = TabSwitcher.maybeOf(context);

    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.location_on_rounded,
          label: 'Halte Terdekat',
          onTap: () {
            // Tab index 1 = HalteScreen
            if (switcher != null) {
              switcher.switchTab(1);
            } else {
              Navigator.pushNamed(context, '/halte');
            }
          },
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.swap_calls_rounded,
          label: 'Cari Rute',
          onTap: () {
            // Tab index 2 = NavigasiScreen
            if (switcher != null) {
              switcher.switchTab(2);
            } else {
              Navigator.pushNamed(context, '/navigasi');
            }
          },
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.navigation_rounded,
          label: 'Navigasi',
          onTap: () {
            // Navigasi aktif bisa dari luar MainScreen
            Navigator.pushNamed(context, '/navigasi_aktif');
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Traffic banner removed

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

// ── Trip Card — data langsung dari model Perjalanan ───────────────────────────
class _TripCard extends StatelessWidget {
  final Perjalanan perjalanan;

  const _TripCard({required this.perjalanan});

  // Status → label, warna, ikon
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
      default: // 'selesai'
        return (
          label: 'Selesai',
          color: AppColors.textSecondary,
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
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar — biru jika aktif, abu jika tidak
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bus badge + waktu
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Route stops
                      _RouteStops(
                        from: perjalanan.halteAsal?.nama ?? '-',
                        to: perjalanan.halteTujuan?.nama ?? '-',
                        isActive: isActive,
                      ),
                      const SizedBox(height: 12),
                      // Status badge — dinamis dari DB
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Jumlah halte yang dilewati jika ada
                          if (perjalanan.riwayat.isNotEmpty)
                            Text(
                              '📍 ${perjalanan.riwayat.length} halte dilewati',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

  const _RouteStops(
      {required this.from, required this.to, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: Colors.white,
              ),
            ),
            Container(
                width: 2,
                height: 18,
                color: isActive ? AppColors.primary : AppColors.border),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(from,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(to,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
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
    if (data.isEmpty)
      return const Text('Belum ada rekomendasi.',
          style: TextStyle(color: AppColors.textSecondary));

    return SizedBox(
      height: 250,
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
    final cardWidth = MediaQuery.of(context).size.width * 0.62;
    final fotoUrl = item.fotoUrl;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/detail-wisata', arguments: item.id),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.deskripsi ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Lihat Detail →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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
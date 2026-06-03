import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../controllers/detail_wisata_controller.dart';
import '../models/wisata.dart';
import '../models/rute.dart';
import '../models/rute_service.dart';
import '../models/osrm_routes_service.dart';
import '../templates/bottom_navbar.dart';

class DetailWisataScreen extends StatefulWidget {
  final int idWisata;
  const DetailWisataScreen({super.key, required this.idWisata});

  @override
  State<DetailWisataScreen> createState() => _DetailWisataScreenState();
}

class _DetailWisataScreenState extends State<DetailWisataScreen> {
  Rute? _selectedRute;
  List<LatLng> _selectedRutePoints = [];
  bool _isLoadingMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailWisataController>().loadData(widget.idWisata);
    });
  }

  Future<void> _selectRute(Rute rute) async {
    if (_selectedRute?.id == rute.id) {
      setState(() {
        _selectedRute = null;
        _selectedRutePoints = [];
      });
      return;
    }

    setState(() {
      _selectedRute = rute;
      _isLoadingMap = true;
    });

    try {
      final service = RuteService();
      final titik = await service.getTitikRute(rute.id);
      
      List<LatLng> points = titik.map((t) => LatLng(t.latitude, t.longitude)).toList();
      
      // If no database points (or just 2 endpoints), use OSRM to find the road-following path
      if (points.length < 3) {
        List<LatLng> waypoints = [];
        if (points.length == 2) {
          waypoints = points;
        } else if (rute.terminalAwal != null && rute.terminalAkhir != null) {
          waypoints = [
            LatLng(rute.terminalAwal!.latitude, rute.terminalAwal!.longitude),
            LatLng(rute.terminalAkhir!.latitude, rute.terminalAkhir!.longitude),
          ];
        } else {
          waypoints = [
            const LatLng(-7.9797, 112.6304), // Alun-alun Malang
            const LatLng(-7.9325, 112.6442), // Terminal Arjosari
          ];
        }

        final osrm = OsrmRoutesService();
        final routeData = await osrm.getRoute(waypoints);
        if (routeData != null && routeData.polyline.isNotEmpty) {
          points = routeData.polyline;
        } else if (points.isEmpty) {
          points = waypoints;
        }
      }

      if (!mounted) return;

      setState(() {
        _selectedRutePoints = points;
        _isLoadingMap = false;
      });
    } catch (e) {
      debugPrint('Error loading points: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 3,
        onTap: _onTapBottomNav,
      ),
      body: Consumer<DetailWisataController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (ctrl.error != null) {
            return _BagianError(
              pesan: ctrl.error!,
              onRetry: () => ctrl.loadData(widget.idWisata),
            );
          }
          if (ctrl.wisata == null) {
            return _BagianError(
              pesan: 'Data wisata tidak ditemukan.',
              onRetry: () => ctrl.loadData(widget.idWisata),
            );
          }
          return _buildContent(ctrl.wisata!, ctrl.ruteList);
        },
      ),
    );
  }

  void _onTapBottomNav(int index) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/user',
      (route) => false,
      arguments: index,
    );
  }

  Widget _buildContent(Wisata w, List<Rute> ruteList) {
    return CustomScrollView(
      slivers: [
        _SliverFotoHeader(
          fotoUrl: w.fotoUrl,
          nama: w.nama,
          kota: w.kota,
          rating: w.rating,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deskripsi
                if (w.deskripsi != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    w.deskripsi!,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Alamat lengkap
                if (w.alamat != null && w.alamat!.isNotEmpty) ...[
                  const Text(
                    'Alamat',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF6B7280), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.alamat!,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Tarif masuk — full width card
                if (w.tarif != null) ...[
                  _TarifCard(
                    tarif: w.tarifFormatted,
                    isGratis: w.tarif == 0,
                  ),
                  const SizedBox(height: 12),
                ],

                // Jam buka & Jam tutup — 2 kolom
                if (w.jamBuka != null || w.jamTutup != null) ...[
                  Row(
                    children: [
                      if (w.jamBuka != null)
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.access_time_rounded,
                            label: 'Jam buka',
                            value: w.jamBuka!,
                          ),
                        ),
                      if (w.jamBuka != null && w.jamTutup != null)
                        const SizedBox(width: 12),
                      if (w.jamTutup != null)
                        Expanded(
                          child: _InfoBox(
                            icon: Icons.access_time_filled_rounded,
                            label: 'Jam tutup',
                            value: w.jamTutup!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                // Rute bus
                if (ruteList.isNotEmpty) ...[
                  const Text(
                    'Rute bus menuju sini',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ruteList.map((rute) {
                    final isSelected = _selectedRute?.id == rute.id;
                    return GestureDetector(
                      onTap: () => _selectRute(rute),
                      child: _RuteListItem(
                        rute: rute,
                        isSelected: isSelected,
                      ),
                    );
                  }),
                  if (_selectedRute != null) ...[
                    const SizedBox(height: 16),
                    _InteractiveRuteMap(
                      rute: _selectedRute!,
                      points: _selectedRutePoints,
                      isLoading: _isLoadingMap,
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  const _StateInfo(
                    message: 'Belum ada rute bus yang tersedia untuk lokasi ini.',
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Sliver Header dengan overlay nama + lokasi + rating (bookmark completely removed)
// ──────────────────────────────────────────────
class _SliverFotoHeader extends StatelessWidget {
  final String? fotoUrl;
  final String nama;
  final String? kota;
  final double? rating;

  const _SliverFotoHeader({
    this.fotoUrl,
    required this.nama,
    this.kota,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'BusGuide',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      centerTitle: true,
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: const EdgeInsets.all(8),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary, size: 20),
            tooltip: 'Kembali',
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Foto
            fotoUrl != null
                ? Image.network(
                    fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FotoPlaceholder(),
                  )
                : const _FotoPlaceholder(),

            // Gradient gelap di bawah untuk teks overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x80000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Teks nama + lokasi + rating di atas foto
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (kota != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                kota!,
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Badge rating
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

// ──────────────────────────────────────────────
// Card tarif masuk — full width, ikon kotak gelap (gratis styled in green)
// ──────────────────────────────────────────────
class _TarifCard extends StatelessWidget {
  final String tarif;
  final bool isGratis;

  const _TarifCard({
    required this.tarif,
    this.isGratis = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isGratis ? const Color(0xFF2E7D32) : const Color(0xFF1A1A2E);
    final bgColor = isGratis ? const Color(0xFFE8F5E9) : Colors.white;
    final borderColor = isGratis ? const Color(0xFFC8E6C9) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_activity_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tarif masuk',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isGratis ? 'Gratis' : 'Rp $tarif',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Info box — jam buka & operasional
// ──────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Rute list item — chip baris (mirip di screenshot)
// ──────────────────────────────────────────────
class _RuteListItem extends StatelessWidget {
  final Rute rute;
  final bool isSelected;
  const _RuteListItem({
    required this.rute,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Circle avatar biru dengan kode rute
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rute.kode,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rute.nama,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (rute.terminalAwal?.nama != null ||
                    rute.terminalAkhir?.nama != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(rute),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isSelected ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
            color: const Color(0xFF9CA3AF),
            size: 18,
          ),
        ],
      ),
    );
  }

  String _subtitle(Rute rute) {
    final origin = rute.terminalAwal?.nama;
    final dest = rute.terminalAkhir?.nama;
    if (origin != null && dest != null) {
      return 'Naik di $origin, turun di $dest';
    }
    if (origin != null) return 'Naik di $origin';
    if (dest != null) return 'Tujuan $dest';
    return '';
  }
}

// ──────────────────────────────────────────────
// Map interaktif rute bus & lintasan asli / fallback
// ──────────────────────────────────────────────
class _InteractiveRuteMap extends StatelessWidget {
  final Rute rute;
  final List<LatLng> points;
  final bool isLoading;

  const _InteractiveRuteMap({
    required this.rute,
    required this.points,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final center = points.isNotEmpty 
        ? points[points.length ~/ 2] 
        : const LatLng(-7.9797, 112.6304);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rute.kode,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rute.nama,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Peta lintasan rute bus & titik koordinat',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.busguide.app',
                  ),
                  if (points.isNotEmpty) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4.5,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: points.first,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Marker(
                          point: points.last,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFC62828),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widget pendukung
// ──────────────────────────────────────────────
class _FotoPlaceholder extends StatelessWidget {
  const _FotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Color(0xFF9CA3AF), size: 48),
      ),
    );
  }
}

class _BagianError extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _BagianError({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFF6B7280), size: 40),
          const SizedBox(height: 12),
          Text(pesan,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi',
                style: TextStyle(color: Color(0xFF0D6EFD))),
          ),
        ],
      ),
    );
  }
}

class _StateInfo extends StatelessWidget {
  final String message;
  const _StateInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
    );
  }
}
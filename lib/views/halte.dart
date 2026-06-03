import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';
import '../controllers/halte_controller.dart';
import '../controllers/navigasi_controller.dart';
import '../models/halte.dart';
import '../models/osrm_routes_service.dart';
import '../templates/header.dart';
import 'home.dart';

class HalteScreen extends StatefulWidget {
  const HalteScreen({super.key});

  @override
  State<HalteScreen> createState() => _HalteScreenState();
}

class _HalteScreenState extends State<HalteScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedHalteId;
  final Map<int, GlobalKey> _cardKeys = {};

  bool _isNavigatingDirectly = false;
  List<LatLng> _routePolyline = [];
  double _distanceKm = 0.0;
  int _durationMin = 0;
  String _targetHalteNama = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<HalteController>();
      ctrl.muatData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHalte(int id) {
    final key = _cardKeys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(begin: startCenter.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: startCenter.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _navigasiKeHalte(Halte halte) async {
    final navCtrl = context.read<NavigasiController>();
    final userLoc = navCtrl.lokasiSaatIni;

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2563EB)),
                SizedBox(height: 18),
                Text(
                  'Mencari rute...',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final routeService = OsrmRoutesService();
      final routeData = await routeService.getRoute([
        userLoc,
        LatLng(halte.latitude, halte.longitude),
      ]);

      if (mounted) Navigator.pop(context); // Tutup dialog loading

      if (routeData != null) {
        setState(() {
          _routePolyline = routeData.polyline;
          _distanceKm = routeData.distanceMeters / 1000.0;
          _durationMin = (routeData.durationSeconds / 60.0).ceil();
          _targetHalteNama = halte.nama;
          _isNavigatingDirectly = true;
        });

        // Fit kamera peta ke rute
        _fitRoute(userLoc, LatLng(halte.latitude, halte.longitude));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan rute navigasi dari server.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup dialog loading jika error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fitRoute(LatLng p1, LatLng p2) {
    final centerLat = (p1.latitude + p2.latitude) / 2;
    final centerLng = (p1.longitude + p2.longitude) / 2;
    final distance = Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
    double zoom = 14.5;
    if (distance > 5000) {
      zoom = 11.5;
    } else if (distance > 3000) {
      zoom = 12.5;
    } else if (distance > 1500) {
      zoom = 13.5;
    } else if (distance > 800) {
      zoom = 14.0;
    }
    _animatedMapMove(LatLng(centerLat, centerLng), zoom);
  }

  Widget _buildMapStack(HalteController ctrl) {
    return Stack(
      children: [
        // 1. Peta Latar Belakang
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.9797, 112.6304), // Default stable center
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                ctrl.setTitikPusat(point);
                _animatedMapMove(point, 14.5);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.busguide.app',
              ),
              if (_isNavigatingDirectly && _routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      color: AppColors.primary,
                      strokeWidth: 4.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ...ctrl.semuaHalte.map((h) {
                    final isSelected = h.id == _selectedHalteId;
                    return Marker(
                      point: LatLng(h.latitude, h.longitude),
                      width: isSelected ? 48 : 40,
                      height: isSelected ? 48 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHalteId = h.id;
                          });
                          _animatedMapMove(LatLng(h.latitude, h.longitude), 15.0);
                          ctrl.setTitikPusatTanpaHitung(
                            LatLng(h.latitude, h.longitude),
                            label: h.nama,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToHalte(h.id);
                          });
                        },
                        child: Icon(
                          Icons.location_on_rounded,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                          size: isSelected ? 40 : 32,
                        ),
                      ),
                    );
                  }),
                  // Penunjuk lokasi pusat aktif (titikPusat)
                  Marker(
                    point: ctrl.titikPusat,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF2563EB), // Pin sasaran biru untuk lokasi aktif
                      size: 30,
                    ),
                  ),
                  if (_isNavigatingDirectly)
                    Marker(
                      point: context.read<NavigasiController>().lokasiSaatIni,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 2. Floating Search Bar
        if (!_isNavigatingDirectly)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 18, right: 12),
                    child: Icon(Icons.search, color: Color(0xFF64748B), size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (val) {
                        ctrl.cariLokasi(val).then((_) {
                          if (ctrl.titikPusat != const LatLng(0, 0)) {
                            _animatedMapMove(ctrl.titikPusat, 14.5);
                          }
                        });
                      },
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        hintText: 'ketik tujuan mu disini',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

        // 3. Floating Glassmorphism Location Label (Status)
        if (!_isNavigatingDirectly)
          Positioned(
            top: 76,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ctrl.labelLokasi,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 4. Floating Circular GPS Button
        if (!_isNavigatingDirectly)
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: ctrl.isLoadingLokasi
                  ? null
                  : () async {
                      await ctrl.dapatkanLokasi();
                      _animatedMapMove(ctrl.titikPusat, 14.5);
                    },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ctrl.pakaiGps ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: ctrl.pakaiGps ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ctrl.isLoadingLokasi
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: ctrl.pakaiGps ? Colors.white : AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.my_location_rounded,
                        color: ctrl.pakaiGps ? Colors.white : const Color(0xFF64748B),
                        size: 22,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavigasiDirectPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rute Navigasi Aktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Menuju $_targetHalteNama',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Waktu Estimasi
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                          Text(
                            '$_durationMin Menit',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Jarak Sisa
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jarak',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                          Text(
                            '${_distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isNavigatingDirectly = false;
                  _routePolyline = [];
                });
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Selesai Perjalanan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: const AppHeader(
        title: 'BusGuide',
        showBack: false,
        showNotification: true,
        hasUnreadNotification: true,
      ),
      body: Consumer<HalteController>(
        builder: (context, ctrl, child) {
          return Column(
            children: [
              // ── Peta & Search Bar Melayang (Stack) ──
              _isNavigatingDirectly
                  ? Expanded(child: _buildMapStack(ctrl))
                  : SizedBox(
                      height: 280,
                      child: _buildMapStack(ctrl),
                    ),

              // ── Panel Bawah ───────────────────────────
              if (_isNavigatingDirectly)
                _buildNavigasiDirectPanel()
              else ...[
                // ── Drag handle ───────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 10, bottom: 0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // ── Header List Halte ──────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Halte Disekitar Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (!ctrl.isLoading)
                        Text(
                          '${ctrl.halteTerdekat.length} halte',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),

                // ── Konten Utama ───────────────────────────────
                Expanded(
                  child: ctrl.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ctrl.errorMessage.isNotEmpty
                          ? _buildErrorState(ctrl)
                          : ctrl.halteTerdekat.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  controller: _scrollController,
                                  cacheExtent: 1000,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: ctrl.halteTerdekat.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final halte = ctrl.halteTerdekat[index];
                                    final jarakMeter = halte.jarakMeter ?? 0;

                                    // Tentukan warna badge waktu berdasarkan jarak
                                    // Dekat (≤5 menit) = biru, jauh = abu
                                    final estimasiMenit =
                                        (jarakMeter / 83.3).ceil();
                                    final badgeColor = estimasiMenit <= 5
                                        ? const Color(0xFF1565C0)
                                        : const Color(0xFF9CA3AF);

                                    final key = _cardKeys.putIfAbsent(halte.id, () => GlobalKey());

                                    return _HalteCard(
                                      key: key,
                                      nama: halte.nama,
                                      alamat: halte.alamat ?? '',
                                      jarakLabel: ctrl.formatJarak(jarakMeter),
                                      waktuLabel:
                                          ctrl.estimasiWaktu(jarakMeter),
                                      badgeColor: badgeColor,
                                      tipeList: ctrl.parseTipe(halte.id, halte.tipe),
                                      warnaChip: ctrl.warnaChip,
                                      onNavigasi: () => _navigasiKeHalte(halte),
                                      foto: halte.foto,
                                      fasilitas: halte.fasilitas,
                                      isSelected: halte.id == _selectedHalteId,
                                      onTap: () {
                                        setState(() {
                                          _selectedHalteId = halte.id;
                                        });
                                        _animatedMapMove(LatLng(halte.latitude, halte.longitude), 15.0);
                                        ctrl.setTitikPusatTanpaHitung(
                                          LatLng(halte.latitude, halte.longitude),
                                          label: halte.nama,
                                        );
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _scrollToHalte(halte.id);
                                        });
                                      },
                                    );
                                  },
                                ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(HalteController ctrl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(ctrl.errorMessage,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: ctrl.muatData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada halte ditemukan',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Kartu Halte ──────────────────────────────────────
class _HalteCard extends StatelessWidget {
  const _HalteCard({
    super.key,
    required this.nama,
    required this.alamat,
    required this.jarakLabel,
    required this.waktuLabel,
    required this.badgeColor,
    required this.tipeList,
    required this.warnaChip,
    required this.onNavigasi,
    required this.onTap,
    this.foto,
    this.fasilitas,
    this.isSelected = false,
  });

  final String nama;
  final String alamat;
  final String jarakLabel;
  final String waktuLabel;
  final Color badgeColor;
  final List<String> tipeList;
  final Color Function(String) warnaChip;
  final VoidCallback onNavigasi;
  final VoidCallback onTap;
  final String? foto;
  final String? fasilitas;
  final bool isSelected;

  Widget _getFacilityIcon(String name) {
    IconData iconData;
    switch (name.toLowerCase()) {
      case 'wifi':
        iconData = Icons.wifi;
        break;
      case 'ac':
        iconData = Icons.ac_unit;
        break;
      case 'toilet':
        iconData = Icons.wc;
        break;
      case 'mushola':
        iconData = Icons.place;
        break;
      case 'ruang tunggu':
        iconData = Icons.weekend;
        break;
      case 'charger port':
        iconData = Icons.power;
        break;
      case 'toko retail':
        iconData = Icons.storefront;
        break;
      default:
        iconData = Icons.check_circle_outline_rounded;
    }
    return Icon(iconData, size: 11, color: const Color(0xFF64748B));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for Thumbnail + Text Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (foto != null && foto!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      foto!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        width: 76,
                        height: 76,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else ...[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus, color: Color(0xFF1D4ED8), size: 28),
                  ),
                  const SizedBox(width: 14),
                ],
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              nama,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              waktuLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$jarakLabel • $alamat',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Facilities & Route Badges
            if ((fasilitas != null && fasilitas!.isNotEmpty) || tipeList.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              
              // Bus Route Chips
              if (tipeList.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Rute:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tipeList
                            .map((t) => _BusChip(label: t, warna: warnaChip(t)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                if (fasilitas != null && fasilitas!.isNotEmpty) const SizedBox(height: 8),
              ],

              // Facilities Row
              if (fasilitas != null && fasilitas!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Fasilitas:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: fasilitas!.split(',').map((f) {
                          final name = f.trim();
                          if (name.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _getFacilityIcon(name),
                                const SizedBox(width: 4),
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 14),

            // Navigation Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onNavigasi,
                icon: const Icon(Icons.navigation_outlined, size: 16, color: Color(0xFF1565C0)),
                label: const Text(
                  'Navigasi ke sini',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1565C0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 0),
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

// ── Widget: Chip Bus ─────────────────────────────────────────
class _BusChip extends StatelessWidget {
  const _BusChip({required this.label, required this.warna});

  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
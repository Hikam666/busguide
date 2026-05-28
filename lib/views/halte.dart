import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../controllers/halte_controller.dart';
import '../controllers/navigasi_controller.dart';
import '../models/halte.dart';
import '../templates/header.dart';
import 'home.dart';

class HalteScreen extends StatefulWidget {
  const HalteScreen({super.key});

  @override
  State<HalteScreen> createState() => _HalteScreenState();
}

class _HalteScreenState extends State<HalteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HalteController>().muatData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigasiKeHalte(Halte halte) {
    final navCtrl = context.read<NavigasiController>();
    final lokasiSaatIni = Halte.lokasiSaatIni(
      navCtrl.lokasiSaatIni.latitude,
      navCtrl.lokasiSaatIni.longitude,
    );
    navCtrl.pilihHalteAsal(lokasiSaatIni);
    navCtrl.pilihHalteTujuan(halte);
    final switcher = TabSwitcher.maybeOf(context);
    if (switcher != null) {
      switcher.switchTab(2);
    } else {
      Navigator.pushNamed(context, '/navigasi');
    }
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
              // ── Search Bar ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3), 
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Input Search & Tombol GPS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          // Field Input Search dengan Border
                          Expanded(
                            child: Container(
                              height: 48, 
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onSubmitted: (val) {
                                        ctrl.cariLokasi(val).then((_) {
                                          if (ctrl.titikPusat != const LatLng(0, 0)) {
                                            _mapController.move(ctrl.titikPusat, 14);
                                          }
                                        });
                                      },
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                                      decoration: const InputDecoration(
                                        hintText: 'Cari halte...',
                                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      textInputAction: TextInputAction.search,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Tombol GPS
                          GestureDetector(
                            onTap: ctrl.isLoadingLokasi
                                ? null
                                : () async {
                                    await ctrl.dapatkanLokasi();
                                    _mapController.move(ctrl.titikPusat, 14);
                                  },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ctrl.pakaiGps
                                    ? const Color(0xFF1565C0) 
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12), 
                              ),
                              child: ctrl.isLoadingLokasi
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.my_location_rounded,
                                      color: ctrl.pakaiGps ? Colors.white : const Color(0xFF6B7280),
                                      size: 22,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Label Lokasi Saat Ini
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF1565C0)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ctrl.labelLokasi,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Peta ─────────────────────────
              SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: ctrl.titikPusat,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.busguide.app',
                    ),
                    MarkerLayer(
                      markers: [
                        ...ctrl.semuaHalte.map((h) {
                          return Marker(
                            point: LatLng(h.latitude, h.longitude),
                            width: 32,
                            height: 32,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1565C0),
                              size: 28,
                            ),
                          );
                        }),
                        // User/Center Marker
                        Marker(
                          point: ctrl.titikPusat,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF1565C0),
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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

                                  return _HalteCard(
                                    nama: halte.nama,
                                    alamat: halte.alamat ?? '',
                                    jarakLabel: ctrl.formatJarak(jarakMeter),
                                    waktuLabel:
                                        ctrl.estimasiWaktu(jarakMeter),
                                    badgeColor: badgeColor,
                                    tipeList: ctrl.parseTipe(halte.tipe),
                                    warnaChip: ctrl.warnaChip,
                                    onNavigasi: () => _navigasiKeHalte(halte),
                                  );
                                },
                              ),
              ),
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
    required this.nama,
    required this.alamat,
    required this.jarakLabel,
    required this.waktuLabel,
    required this.badgeColor,
    required this.tipeList,
    required this.warnaChip,
    required this.onNavigasi,
  });

  final String nama;
  final String alamat;
  final String jarakLabel;
  final String waktuLabel;
  final Color badgeColor;
  final List<String> tipeList;
  final Color Function(String) warnaChip;
  final VoidCallback onNavigasi;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris judul & badge waktu ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge waktu - warna dinamis 
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
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

            const SizedBox(height: 4),

            // ── Jarak & alamat ─────────────────────────
            Text(
              '$jarakLabel • $alamat',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // ── Chip tipe bus ──────────────────────────
            if (tipeList.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tipeList
                    .map((t) => _BusChip(label: t, warna: warnaChip(t)))
                    .toList(),
              ),

            const SizedBox(height: 12),

            // ── Tombol Navigasi ────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNavigasi,
                icon: const Icon(Icons.navigation_outlined,
                    size: 16, color: Color(0xFF1565C0)),
                label: const Text(
                  'Navigasi ke sini',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
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
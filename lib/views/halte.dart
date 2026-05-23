import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../controllers/halte_controller.dart';
import '../templates/header.dart';

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

  Future<void> _navigasiKeHalte(double lat, double lon) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=walking');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
              // ── Search Bar & Label Lokasi (satu container) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris search input + tombol lokasi
                      Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Icon(Icons.search_rounded,
                                color: Color(0xFF9CA3AF), size: 20),
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
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF1A1A2E)),
                              decoration: const InputDecoration(
                                hintText: 'Cari halte...',
                                hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          GestureDetector(
                            onTap: ctrl.isLoadingLokasi
                                ? null
                                : () async {
                                    await ctrl.dapatkanLokasi();
                                    _mapController.move(ctrl.titikPusat, 14);
                                  },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: ctrl.pakaiGps
                                    ? AppColors.primary
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ctrl.isLoadingLokasi
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(Icons.my_location_rounded,
                                      color: ctrl.pakaiGps
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      size: 18),
                            ),
                          ),
                        ],
                      ),

                      // Garis pemisah tipis
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

                      // Label lokasi saat ini
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ctrl.labelLokasi,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Peta ─────────────────────────
              Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1E9F6)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            );
                          }),
                          // User/Center Marker
                          Marker(
                            point: ctrl.titikPusat,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFFDC2626),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Header List Halte ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Halte Disekitar Anda',
                      style: TextStyle(
                        fontSize: 20,
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

              const SizedBox(height: 12),

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
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: ctrl.halteTerdekat.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final halte = ctrl.halteTerdekat[index];
                                  return _HalteCard(
                                    nama: halte.nama,
                                    alamat: halte.alamat ?? '',
                                    jarakLabel: ctrl
                                        .formatJarak(halte.jarakMeter ?? 0),
                                    waktuLabel: ctrl
                                        .estimasiWaktu(halte.jarakMeter ?? 0),
                                    tipeList: ctrl.parseTipe(halte.tipe),
                                    warnaChip: ctrl.warnaChip,
                                    onNavigasi: () => _navigasiKeHalte(
                                        halte.latitude, halte.longitude),
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
              backgroundColor: AppColors.primary,
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
    required this.tipeList,
    required this.warnaChip,
    required this.onNavigasi,
  });

  final String nama;
  final String alamat;
  final String jarakLabel;
  final String waktuLabel;
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
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
                icon: Icon(Icons.navigation_outlined,
                    size: 16, color: AppColors.primary),
                label: Text(
                  'Navigasi ke sini',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
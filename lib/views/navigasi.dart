import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../templates/header.dart';
import '../controllers/navigasi_controller.dart';
import '../controllers/home_controller.dart';
import '../models/halte.dart';
import '../models/rute.dart';
import 'map_picker.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

class _NavigasiScreenState extends State<NavigasiScreen> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NavigasiController>();
      ctrl.initData().then((_) {
        if (ctrl.adaPerjalananAktif && mounted) {
          Navigator.pushNamed(context, '/navigasi_aktif').then((_) {
            ctrl.resetState();
          });
        }
      });
    });
  }

  void _bukaPilihHalte(NavigasiController ctrl, {required bool isAsal}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Text(isAsal ? 'Pilih Halte Asal' : 'Pilih Halte Tujuan',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Pilih Lokasi dari Peta (Custom)'),
              onTap: () async {
                Navigator.pop(ctx);
                final selectedLatLng = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPickerScreen(
                      initialCenter: ctrl.lokasiSaatIni,
                    ),
                  ),
                );
                
                if (selectedLatLng != null && selectedLatLng is LatLng) {
                  final h = Halte(
                    id: -1, 
                    nama: 'Lokasi Peta (${selectedLatLng.latitude.toStringAsFixed(3)}, ${selectedLatLng.longitude.toStringAsFixed(3)})', 
                    tipe: 'custom', 
                    latitude: selectedLatLng.latitude, 
                    longitude: selectedLatLng.longitude,
                  );
                  if (isAsal) ctrl.pilihHalteAsal(h);
                  else ctrl.pilihHalteTujuan(h);
                }
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.semuaHalte.length,
                itemBuilder: (context, index) {
                  final h = ctrl.semuaHalte[index];
                  return ListTile(
                    leading: Icon(Icons.location_on,
                        color: isAsal ? AppColors.primary : Colors.red),
                    title: Text(h.nama),
                    subtitle: Text(h.alamat ?? ''),
                    onTap: () {
                      if (isAsal) {
                        ctrl.pilihHalteAsal(h);
                      } else {
                        ctrl.pilihHalteTujuan(h);
                      }
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }



  Future<void> _handleCariRute(NavigasiController ctrl) async {
    final error = await ctrl.cariRute();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else if (ctrl.titikPolyline.isNotEmpty) {
      _mapController.move(ctrl.titikPolyline.first, 15);
    }
  }

  Future<void> _handleMulaiNavigasi(NavigasiController ctrl, Rute rute) async {
    final error = await ctrl.mulaiNavigasi(rute);
    if (!mounted) return;
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      // Refresh HomeController so Home shows the active perjalanan immediately
      try {
        await context.read<HomeController>().loadData();
      } catch (_) {}
      Navigator.pushNamed(context, '/navigasi_aktif').then((_) {
        ctrl.resetState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<NavigasiController>(
          builder: (context, ctrl, _) => _buildScreenSearch(ctrl),
        ),
      ),
    );
  }

  // ==========================================
  // BUILDER LAYAR 1: SEARCH
  // ==========================================
  Widget _buildScreenSearch(NavigasiController ctrl) {
    return Column(
      children: [
        // Header
        const AppHeader(
          title: 'BusGuide',
          showBack: false,
          showNotification: true,
          hasUnreadNotification: true,
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Card Form Pencarian
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Ikon Kiri (Timeline)
                          Column(
                            children: [
                              const Icon(Icons.circle,
                                  color: AppColors.primary, size: 14),
                              Container(
                                  width: 2,
                                  height: 32,
                                  color: const Color(0xFFE5E7EB)),
                              const Icon(Icons.location_on,
                                  color: Colors.red, size: 18),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Input Asal & Tujuan
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _bukaPilihHalte(ctrl, isAsal: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ctrl.halteAsal?.nama ??
                                          'Pilih halte asal...',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: ctrl.halteAsal != null
                                              ? AppColors.textPrimary
                                              : Colors.grey),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                GestureDetector(
                                  onTap: () =>
                                      _bukaPilihHalte(ctrl, isAsal: false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ctrl.halteTujuan?.nama ??
                                          'Pilih halte tujuan...',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: ctrl.halteTujuan != null
                                              ? AppColors.textPrimary
                                              : Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Swap
                          IconButton(
                            icon: const Icon(Icons.swap_vert,
                                color: Colors.grey),
                            onPressed: () {
                              ctrl.tukarHalte();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Alarm Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Aktifkan alarm halte tujuan',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          Switch(
                            value: ctrl.alarmAktif,
                            activeColor: AppColors.primary,
                            onChanged: (val) => ctrl.setAlarm(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tombol Cari Rute
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading
                              ? null
                              : () => _handleCariRute(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: ctrl.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Cari Rute',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Peta Mini
                Container(
                  height: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                              initialCenter: ctrl.lokasiSaatIni,
                              initialZoom: 13),
                          children: [
                            TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.busguide.app'),
                            if (ctrl.titikPolyline.isNotEmpty)
                              PolylineLayer(polylines: [
                                Polyline(
                                    points: ctrl.titikPolyline,
                                    color: AppColors.primary,
                                    strokeWidth: 4),
                              ]),
                            MarkerLayer(markers: [
                              if (ctrl.halteRute.isNotEmpty)
                                ...ctrl.halteRute.map((rh) {
                                  return Marker(
                                    point: LatLng(rh.halte.latitude,
                                        rh.halte.longitude),
                                    width: 16,
                                    height: 16,
                                    child: const Icon(Icons.circle,
                                        color: Colors.orange, size: 12),
                                  );
                                }),
                              Marker(
                                point: ctrl.lokasiSaatIni,
                                child: const Icon(Icons.my_location,
                                    color: AppColors.primary, size: 24),
                              ),
                            ]),
                          ],
                        ),
                        if (ctrl.isMapLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),

                // Section Rute Tersedia
                if (ctrl.ruteTersedia.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Rute Tersedia',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ctrl.ruteTersedia.length,
                    itemBuilder: (context, index) {
                      final rute = ctrl.ruteTersedia[index];
                      return _RuteTersediaCard(
                        rute: rute,
                        halteAsal: ctrl.halteAsal!.nama,
                        halteTujuan: ctrl.halteTujuan!.nama,
                        onMulai: () => _handleMulaiNavigasi(ctrl, rute),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

class _RuteTersediaCard extends StatelessWidget {
  final Rute rute;
  final String halteAsal;
  final String halteTujuan;
  final VoidCallback onMulai;

  const _RuteTersediaCard({
    required this.rute,
    required this.halteAsal,
    required this.halteTujuan,
    required this.onMulai,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rute
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(rute.kode,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rute.nama,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (rute.estimasiMenit != null)
                Text('~${rute.estimasiMenit} mnt',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle,
                      color: AppColors.primary, size: 14),
                  Container(
                      width: 2, height: 24, color: const Color(0xFFE5E7EB)),
                  const Icon(Icons.circle, color: Colors.red, size: 14),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(halteAsal,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Text(halteTujuan,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tombol Mulai
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onMulai,
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Mulai Navigasi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
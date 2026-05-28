import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../controllers/navigasi_aktif_controller.dart';
import '../controllers/home_controller.dart';

class NavigasiAktifScreen extends StatefulWidget {
  const NavigasiAktifScreen({super.key});

  @override
  State<NavigasiAktifScreen> createState() => _NavigasiAktifScreenState();
}

class _NavigasiAktifScreenState extends State<NavigasiAktifScreen> {
  final _mapController = MapController();

  LatLng? _lastMapCenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NavigasiAktifController>();
      
      // Auto-center map ketika lokasi berubah
      ctrl.addListener(() {
        if (!mounted) return;
        final currentLoc = ctrl.lokasiSaatIni;
        final currentHeading = ctrl.headingSaatIni;
        if (_lastMapCenter != currentLoc) {
          _lastMapCenter = currentLoc;
          try {
            // Putar peta secara otomatis agar menghadap arah jalan
            _mapController.moveAndRotate(currentLoc, 17.5, currentHeading);
          } catch (_) {} // Abaikan jika map belum siap
        }
      });

      ctrl.loadDataAktif().then((_) {
        if (ctrl.perjalananAktif == null && mounted) {
          Navigator.pop(context);
        }
      });
    });
  }

  Future<void> _selesaikan(NavigasiAktifController ctrl) async {
    final success = await ctrl.selesaikanPerjalanan();
    if (success) {
      // Refresh home so active trip is removed immediately
      try {
        await context.read<HomeController>().loadData();
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _batalkan(NavigasiAktifController ctrl) async {
    final success = await ctrl.batalkanPerjalanan();
    if (success) {
      try {
        await context.read<HomeController>().loadData();
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<NavigasiAktifController>(
          builder: (context, ctrl, _) {
            if (ctrl.isLoading || ctrl.perjalananAktif == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final chipBgColor = ctrl.isAlmostThere
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFECFDF5);
            final chipTextColor = ctrl.isAlmostThere
                ? const Color(0xFFD97706)
                : const Color(0xFF059669);
            final chipIconColor = ctrl.isAlmostThere
                ? const Color(0xFFD97706)
                : const Color(0xFF10B981);
            final chipText = ctrl.isAlmostThere
                ? 'Hampir Sampai'
                : 'Navigasi Aktif';

            final ruteNama = ctrl.perjalananAktif!.rute?.kode ?? 'Bus';
            final namaTujuan = ctrl.perjalananAktif!.halteTujuan?.nama ?? '-';
            final isAlarmActive = ctrl.perjalananAktif!.alarmAktif;

            return Column(
              children: [
                // Custom Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                                color: chipBgColor,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    ctrl.isAlmostThere
                                        ? Icons.wifi_tethering
                                        : Icons.circle,
                                    color: chipIconColor,
                                    size: 14),
                                const SizedBox(width: 6),
                                Text(chipText,
                                    style: TextStyle(
                                        color: chipTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ),

                // Peta Penuh & Panel Bawah
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                            initialCenter: ctrl.lokasiSaatIni,
                            initialZoom: 17.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                            )),
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
                                  strokeWidth: 5)
                            ]),
                          MarkerLayer(markers: [
                            if (ctrl.halteRute.isNotEmpty)
                              ...ctrl.halteRute.map((rh) => Marker(
                                    point: LatLng(rh.halte.latitude,
                                        rh.halte.longitude),
                                    width: 20,
                                    height: 20,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.orange,
                                                width: 3))),
                                  )),
                            Marker(
                              point: ctrl.lokasiSaatIni,
                              width: 60,
                              height: 60,
                              child: Transform.rotate(
                                angle: ctrl.headingSaatIni * (3.14159 / 180), // Derajat ke radian
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.navigation,
                                        color: AppColors.primary, size: 30),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),

                      // Panel Bawah
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5))
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.directions_bus,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Naik bus $ruteNama',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Arah $namaTujuan',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              const Text('Halte Berikutnya',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(
                                                  ctrl.halteBerikutnya?.nama ??
                                                      namaTujuan,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ])),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_filled,
                                            color: Colors.orange, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              const Text('Estimasi Tiba',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Row(children: [
                                                Text(
                                                    '~${ctrl.sisaMenitTiba} mnt',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                    onTap: ctrl.toggleAlarm,
                                                    child: Icon(
                                                        isAlarmActive
                                                            ? Icons
                                                                .notifications_active
                                                            : Icons
                                                                .notifications_off,
                                                        size: 16,
                                                        color: isAlarmActive
                                                            ? Colors.green
                                                            : Colors.grey)),
                                              ]),
                                            ])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                      child: OutlinedButton.icon(
                                          onPressed: () => _batalkan(ctrl),
                                          icon: const Icon(Icons.cancel,
                                              size: 18),
                                          label: const Text('Batalkan'),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                  color: Colors.red),
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10))))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: ElevatedButton.icon(
                                          onPressed: () => _selesaikan(ctrl),
                                          icon: const Icon(Icons.check_circle,
                                              size: 18),
                                          label: const Text('Selesai'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10))))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
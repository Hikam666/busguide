import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../controllers/navigasi_aktif_controller.dart';
import '../controllers/home_controller.dart';
import 'package:geolocator/geolocator.dart';

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
        if (ctrl.userBelumDiHalteAsal) {
          // Biarkan user bebas melihat rute saat jalan kaki
          return;
        }
        final currentLoc = ctrl.lokasiSaatIni;
        final currentHeading = ctrl.headingSaatIni;
        if (_lastMapCenter != currentLoc) {
          _lastMapCenter = currentLoc;
          try {
            // Putar peta secara otomatis agar menghadap arah jalan
            _mapController.moveAndRotate(currentLoc, 16.5, currentHeading);
          } catch (_) {} // Abaikan jika map belum siap
        }
      });

      ctrl.loadDataAktif().then((_) {
        if (ctrl.perjalananAktif == null && mounted) {
          Navigator.pop(context);
          return;
        }
        if (mounted) {
          _fitRouteBounds();

          if (ctrl.perjalananAktif?.halteAsal != null) {
            final startHalt = ctrl.perjalananAktif!.halteAsal!;
            final distToAsal = Geolocator.distanceBetween(
              ctrl.lokasiSaatIni.latitude,
              ctrl.lokasiSaatIni.longitude,
              startHalt.latitude,
              startHalt.longitude,
            );

            if (distToAsal > 100) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lokasi Anda jauh dari halte awal (${startHalt.nama}). Silakan menuju ke halte tersebut.',
                          style: const TextStyle(fontFamily: 'DMSans', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFD97706),
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        }
      });
    });
  }

  void _fitRouteBounds() {
    if (!mounted) return;
    final ctrl = context.read<NavigasiAktifController>();
    if (ctrl.titikPolyline.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(ctrl.titikPolyline);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
        ),
      );
    }
  }

  Future<void> _selesaikan(NavigasiAktifController ctrl) async {
    final success = await ctrl.selesaikanPerjalanan();
    if (success) {
      // Refresh home so active trip is removed immediately
      try {
        if (mounted) {
          await context.read<HomeController>().loadData();
        }
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _batalkan(NavigasiAktifController ctrl) async {
    final success = await ctrl.batalkanPerjalanan();
    if (success) {
      try {
        if (mounted) {
          await context.read<HomeController>().loadData();
        }
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

            final startHaltName = ctrl.perjalananAktif!.halteAsal?.nama ?? 'Halte Asal';
            final headerIcon = ctrl.userBelumDiHalteAsal ? Icons.directions_walk : Icons.directions_bus;
            final headerIconBgColor = ctrl.userBelumDiHalteAsal ? const Color(0xFFFEF3C7) : AppColors.surfaceVariant;
            final headerIconColor = ctrl.userBelumDiHalteAsal ? const Color(0xFFD97706) : AppColors.primary;
            final headerTitle = ctrl.userBelumDiHalteAsal ? 'Menuju Halte $startHaltName' : 'Naik bus $ruteNama';
            final headerSubtitle = ctrl.userBelumDiHalteAsal ? 'Lanjut naik bus $ruteNama' : 'Arah $namaTujuan';
            final nextHaltTitle = ctrl.userBelumDiHalteAsal ? 'Halte Keberangkatan' : 'Halte Berikutnya';
            final nextHaltName = ctrl.userBelumDiHalteAsal ? startHaltName : (ctrl.halteBerikutnya?.nama ?? namaTujuan);

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
                            if (ctrl.userBelumDiHalteAsal) ...[
                              if (ctrl.perjalananAktif?.halteAsal != null)
                                Marker(
                                  point: LatLng(ctrl.perjalananAktif!.halteAsal!.latitude,
                                      ctrl.perjalananAktif!.halteAsal!.longitude),
                                  width: 24,
                                  height: 24,
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.red,
                                              width: 3.5))),
                                ),
                            ] else ...[
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
                            ],
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
                                        color: headerIconBgColor,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(headerIcon,
                                        color: headerIconColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          headerTitle,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          headerSubtitle,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tombol Toggle Alarm
                                  if (ctrl.perjalananAktif != null)
                                    IconButton(
                                      icon: Icon(
                                        ctrl.perjalananAktif!.alarmAktif
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: ctrl.perjalananAktif!.alarmAktif
                                            ? AppColors.primary
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        ctrl.toggleAlarm();
                                      },
                                      tooltip: 'Aktifkan/Matikan Alarm',
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
                                              Text(nextHaltTitle,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                              Text(
                                                  nextHaltName,
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
                              if (!ctrl.userBelumDiHalteAsal) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB), // Soft yellow/amber background
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE68A)), // Soft border
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.directions_bus_rounded, color: Color(0xFFD97706), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Perkiraan bus tiba di halte awal: ${ctrl.estimasiBusTibaJam} (~${ctrl.estimasiBusTibaMenit} mnt)',
                                          style: const TextStyle(
                                            fontFamily: 'DMSans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
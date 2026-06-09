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

class _NavigasiAktifScreenState extends State<NavigasiAktifScreen> with SingleTickerProviderStateMixin {
  final _mapController = MapController();

  // Animasi GPS tracking agar pergerakan penanda dan kamera peta sangat mulus
  late AnimationController _animationController;
  LatLng? _currentAnimatedLocation;
  double _currentAnimatedHeading = 0.0;
  LatLng _startLocation = const LatLng(0, 0);
  LatLng _targetLocation = const LatLng(0, 0);
  double _startHeading = 0.0;
  double _targetHeading = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950), // Interpolasi 950ms agar tumpang tindih secara mulus
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<NavigasiAktifController>();
      
      // Menggerakkan marker & kamera secara mulus via listener
      ctrl.addListener(() {
        if (!mounted) return;
        final newLoc = ctrl.lokasiSaatIni;
        final newHeading = ctrl.headingSaatIni;

        if (_currentAnimatedLocation == null) {
          setState(() {
            _currentAnimatedLocation = newLoc;
            _currentAnimatedHeading = newHeading;
          });
          return;
        }

        _startLocation = _currentAnimatedLocation!;
        _targetLocation = newLoc;
        _startHeading = _currentAnimatedHeading;

        // Cegah putaran berlebih jika melewati sudut 360/0 derajat
        double diff = newHeading - _startHeading;
        if (diff > 180) {
          _targetHeading = newHeading - 360;
        } else if (diff < -180) {
          _targetHeading = newHeading + 360;
        } else {
          _targetHeading = newHeading;
        }

        _animationController.stop();
        _animationController.reset();

        final Animation<double> curve = CurvedAnimation(
          parent: _animationController,
          curve: Curves.linear, // Pergerakan konstan/linear terasa paling alami untuk navigasi kendaraan
        );

        _animationController.addListener(() {
          if (!mounted) return;
          final t = curve.value;

          final lat = _startLocation.latitude + (_targetLocation.latitude - _startLocation.latitude) * t;
          final lng = _startLocation.longitude + (_targetLocation.longitude - _startLocation.longitude) * t;
          
          setState(() {
            _currentAnimatedLocation = LatLng(lat, lng);
            double heading = _startHeading + (_targetHeading - _startHeading) * t;
            _currentAnimatedHeading = (heading + 360) % 360;
          });

          // Pindahkan & putar peta secara otomatis agar sinkron dengan laju motor
          if (!ctrl.userBelumDiHalteAsal) {
            try {
              _mapController.moveAndRotate(_currentAnimatedLocation!, 16.5, _currentAnimatedHeading);
            } catch (_) {}
          }
        });

        _animationController.forward();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

            // Cek apakah ini perjalanan mandiri (tanpa bus)
            final isBebasOrMandiri = ctrl.perjalananAktif!.rute?.id == 0 ||
                ctrl.perjalananAktif!.rute?.kode == 'BEBAS' ||
                ctrl.perjalananAktif!.rute?.kode == 'LOKAL' ||
                ctrl.perjalananAktif!.id == -999;

            final startHaltName = ctrl.perjalananAktif!.halteAsal?.nama ?? 'Halte Asal';
            
            final IconData headerIcon;
            final Color headerIconBgColor;
            final Color headerIconColor;
            final String headerTitle;
            final String headerSubtitle;
            final String nextHaltTitle;
            final String nextHaltName;

            if (isBebasOrMandiri) {
              headerIcon = Icons.motorcycle;
              headerIconBgColor = const Color(0xFFE0F2FE); // Soft blue background
              headerIconColor = const Color(0xFF0284C7); // Sky blue icon
              headerTitle = 'Navigasi ke $namaTujuan';
              headerSubtitle = 'Rute Mandiri (Tanpa Bus)';
              nextHaltTitle = 'Tujuan Akhir';
              nextHaltName = namaTujuan;
            } else {
              headerIcon = ctrl.userBelumDiHalteAsal ? Icons.directions_walk : Icons.directions_bus;
              headerIconBgColor = ctrl.userBelumDiHalteAsal ? const Color(0xFFFEF3C7) : AppColors.surfaceVariant;
              headerIconColor = ctrl.userBelumDiHalteAsal ? const Color(0xFFD97706) : AppColors.primary;
              headerTitle = ctrl.userBelumDiHalteAsal ? 'Menuju Halte $startHaltName' : 'Naik bus $ruteNama';
              headerSubtitle = ctrl.userBelumDiHalteAsal ? 'Lanjut naik bus $ruteNama' : 'Arah $namaTujuan';
              nextHaltTitle = ctrl.userBelumDiHalteAsal ? 'Halte Keberangkatan' : 'Halte Berikutnya';
              nextHaltName = ctrl.userBelumDiHalteAsal ? startHaltName : (ctrl.halteBerikutnya?.nama ?? namaTujuan);
            }

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
                            initialCenter: _currentAnimatedLocation ?? ctrl.lokasiSaatIni,
                            initialZoom: 17.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                            )),
                        children: [
                          TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.busguide.app'),
                          PolylineLayer(polylines: [
                            if (ctrl.firstPartPolyline.isNotEmpty)
                              Polyline(
                                  points: ctrl.firstPartPolyline,
                                  color: const Color(0xFF10B981),
                                  strokeWidth: 5.5),
                            if (ctrl.secondPartPolyline.isNotEmpty)
                              Polyline(
                                  points: ctrl.secondPartPolyline,
                                  color: const Color(0xFF007AFF),
                                  strokeWidth: 5.5),
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
                              point: _currentAnimatedLocation ?? ctrl.lokasiSaatIni,
                              width: 60,
                              height: 60,
                              child: Transform.rotate(
                                angle: (_currentAnimatedLocation != null ? _currentAnimatedHeading : ctrl.headingSaatIni) * (3.14159 / 180), // Derajat ke radian
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
                              if (!ctrl.userBelumDiHalteAsal && !isBebasOrMandiri) ...[
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
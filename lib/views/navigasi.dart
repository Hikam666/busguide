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
                  if (isAsal) {
                    ctrl.pilihHalteAsal(h);
                  } else {
                    ctrl.pilihHalteTujuan(h);
                  }
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
    if (ctrl.isLoading) return;

    // Check if the route has departures today
    final schedules = ctrl.jadwalRuteMap[rute.id] ?? [];
    bool hasDeparturesToday = false;
    String earliestTime = '08:00';

    if (schedules.isNotEmpty) {
      final now = DateTime.now();
      final weekdayNamesEn = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final weekdayNamesId = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final todayEn = weekdayNamesEn[now.weekday].toLowerCase();
      final todayId = weekdayNamesId[now.weekday].toLowerCase();

      final schedulesToday = schedules.where((s) {
        final h = s['hari'];
        List<String> listHari = [];
        if (h is List) {
          listHari = h.map((e) => e.toString().toLowerCase()).toList();
        } else if (h is String) {
          listHari = [h.toLowerCase()];
        }
        if (listHari.isEmpty) return true;
        return listHari.any((day) =>
          day == 'setiap hari' ||
          day == 'daily' ||
          day == todayEn ||
          day == todayId
        );
      }).toList();

      DateTime? nextDeparture;
      if (schedulesToday.isNotEmpty) {
        int minDiff = 999999;
        for (final s in schedulesToday) {
          final jam = s['jam_berangkat']?.toString();
          if (jam == null || !jam.contains(':')) continue;
          final parts = jam.split(':');
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          final depTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
          final diff = depTimeToday.difference(now).inMinutes;

          if (diff > 0 && diff < minDiff) {
            minDiff = diff;
            nextDeparture = depTimeToday;
          }
        }
      }

      if (nextDeparture != null) {
        hasDeparturesToday = true;
      } else {
        int minHour = 24;
        int minMinute = 60;
        for (final s in schedules) {
          final jam = s['jam_berangkat']?.toString();
          if (jam == null || !jam.contains(':')) continue;
          final parts = jam.split(':');
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          if (hour < minHour || (hour == minHour && minute < minMinute)) {
            minHour = hour;
            minMinute = minute;
            earliestTime = jam;
          }
        }
      }
    }

    // JANGAN SIMPAN RIWAYAT JIKA:
    // 1. Rute ID == 0 (BEBAS atau LOKAL)
    // 2. Custom coordinates (halteAsal.id == -1 atau halteTujuan.id == -1)
    // 3. Tidak ada jadwal keberangkatan bus yang aktif saat ini
    final isCustomLocation = (ctrl.halteAsal?.id == -1 || ctrl.halteTujuan?.id == -1);
    final isBebasOrLokal = (rute.id == 0);
    final shouldWriteToDb = !isBebasOrLokal && !isCustomLocation && hasDeparturesToday;

    final error = await ctrl.mulaiNavigasi(rute, writeToDb: shouldWriteToDb);
    if (!mounted) return;
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      if (!shouldWriteToDb && !isBebasOrLokal && !isCustomLocation) {
        // Hanya beri tahu jika itu rute bus yang sebenarnya tidak beroperasi saat ini
        String formattedTime = earliestTime;
        if (earliestTime.contains(':')) {
          final parts = earliestTime.split(':');
          if (parts.length >= 2) {
            formattedTime = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Memulai Navigasi Mandiri. Bus tidak aktif saat ini (kembali beroperasi besok jam $formattedTime WIB).',
                    style: const TextStyle(fontFamily: 'DMSans', fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Refresh HomeController so Home shows the active perjalanan immediately if written to DB
      if (shouldWriteToDb) {
        try {
          await context.read<HomeController>().loadData();
        } catch (_) {}
      }
      if (!mounted) return;
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
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Dotted Line Icons Timeline
                          Column(
                            children: [
                              const Icon(Icons.radio_button_checked_rounded,
                                  color: Color(0xFF4B5563), size: 20),
                              CustomPaint(
                                size: const Size(2, 36),
                                painter: DottedLinePainter(),
                              ),
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.primary, size: 20),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Middle: Form Fields
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _bukaPilihHalte(ctrl, isAsal: true),
                                  child: Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFD5E0F2)),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ctrl.halteAsal?.nama ?? 'Pilih halte asal...',
                                      style: TextStyle(
                                        fontFamily: 'DMSans',
                                        fontSize: 14,
                                        color: ctrl.halteAsal != null
                                            ? AppColors.textPrimary
                                            : Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _bukaPilihHalte(ctrl, isAsal: false),
                                  child: Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFD5E0F2)),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ctrl.halteTujuan?.nama ?? 'Lokasi tujuan',
                                      style: TextStyle(
                                        fontFamily: 'DMSans',
                                        fontSize: 14,
                                        color: ctrl.halteTujuan != null
                                            ? AppColors.textPrimary
                                            : Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right: Swap Button
                          GestureDetector(
                            onTap: () => ctrl.tukarHalte(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Alarm Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  color: Color(0xFF4B5563), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Aktifkan alarm halte tujuan',
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: ctrl.alarmAktif,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => ctrl.setAlarm(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tombol Cari Rute
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading
                              ? null
                              : () => _handleCariRute(ctrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: ctrl.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Cari Rute',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Peta Mini
                Container(
                  height: 240,
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
                            PolylineLayer(polylines: [
                              if (ctrl.firstPartPolyline.isNotEmpty)
                                Polyline(
                                    points: ctrl.firstPartPolyline,
                                    color: const Color(0xFF10B981),
                                    strokeWidth: 4.5),
                              if (ctrl.secondPartPolyline.isNotEmpty)
                                Polyline(
                                    points: ctrl.secondPartPolyline,
                                    color: const Color(0xFF007AFF),
                                    strokeWidth: 4.5),
                            ]),
                            MarkerLayer(markers: [
                              // Intermediate halts (excluding start and destination)
                              if (ctrl.halteRute.isNotEmpty)
                                ...ctrl.halteRute
                                    .where((rh) =>
                                        (ctrl.halteAsal == null || rh.halte.id != ctrl.halteAsal!.id) &&
                                        (ctrl.halteTujuan == null || rh.halte.id != ctrl.halteTujuan!.id))
                                    .map((rh) {
                                  return Marker(
                                    point: LatLng(rh.halte.latitude,
                                        rh.halte.longitude),
                                    width: 14,
                                    height: 14,
                                    child: const Icon(Icons.circle,
                                        color: Colors.orange, size: 10),
                                  );
                                }),

                              // Current User Location GPS Marker
                              Marker(
                                point: ctrl.lokasiSaatIni,
                                width: 28,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.my_location,
                                        color: AppColors.primary, size: 20),
                                  ),
                                ),
                              ),

                              // Start Halt Marker (Halte Awal - Green Theme)
                              if (ctrl.halteAsal != null && ctrl.halteAsal!.id != 0)
                                Marker(
                                  point: LatLng(ctrl.halteAsal!.latitude, ctrl.halteAsal!.longitude),
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF10B981), width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.directions_bus_rounded,
                                          color: Color(0xFF10B981), size: 16),
                                    ),
                                  ),
                                ),

                              // Destination Halt Marker (Halte Tujuan - Red Theme)
                              if (ctrl.halteTujuan != null)
                                Marker(
                                  point: LatLng(ctrl.halteTujuan!.latitude, ctrl.halteTujuan!.longitude),
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFEF4444), width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.location_on_rounded,
                                          color: Color(0xFFEF4444), size: 16),
                                    ),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                        if (ctrl.isMapLoading)
                          const Center(child: CircularProgressIndicator()),
                        
                        // Floating map controls in bottom right
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMapControl(
                                icon: Icons.gps_fixed_rounded,
                                onTap: () {
                                  _mapController.move(ctrl.lokasiSaatIni, 15);
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildMapControl(
                                icon: Icons.layers_rounded,
                                onTap: () {
                                  // Layers toggled visually
                                },
                              ),
                            ],
                          ),
                        ),
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
                      child: Text(
                        'Rute Tersedia',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
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
                        schedules: ctrl.jadwalRuteMap[rute.id] ?? [],
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

  Widget _buildMapControl({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF4B5563), size: 18),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RuteTersediaCard extends StatelessWidget {
  final Rute rute;
  final String halteAsal;
  final String halteTujuan;
  final List<Map<String, dynamic>> schedules;
  final VoidCallback onMulai;

  const _RuteTersediaCard({
    required this.rute,
    required this.halteAsal,
    required this.halteTujuan,
    required this.schedules,
    required this.onMulai,
  });

  // Extract bus info from a schedule record
  Map<String, dynamic> _extractBusInfo(Map<String, dynamic> schedule) {
    final bus = schedule['bus'] as Map<String, dynamic>?;
    if (bus == null) {
      return {
        'poName': null,
        'busType': null,
        'busName': null,
        'platNomor': null,
      };
    }
    final poBus = bus['po_bus'] as Map<String, dynamic>?;
    return {
      'poName': poBus?['nama']?.toString(),
      'busType': bus['tipe']?.toString(),
      'busName': bus['nama_bus']?.toString(),
      'platNomor': bus['nomor_polisi']?.toString(),
    };
  }

  static String _formatRupiah(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  Map<String, dynamic> _getScheduleInfo() {
    if (schedules.isEmpty) {
      return {
        'hasDeparturesToday': false,
        'nextDeparture': null,
        'nextDepartureFormatted': '-',
        'notice': 'Tidak ada jadwal operasi tersedia',
        'tarif': null,
        'hari': 'Tidak Aktif',
        'allDepartures': <Map<String, dynamic>>[],
        'nextBusInfo': <String, dynamic>{},
      };
    }

    final now = DateTime.now();
    final weekdayNamesEn = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekdayNamesId = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayEn = weekdayNamesEn[now.weekday].toLowerCase();
    final todayId = weekdayNamesId[now.weekday].toLowerCase();

    // Collect tarif: use first non-null tarif found
    int? tarif;
    for (final s in schedules) {
      final t = s['tarif'];
      if (t != null && t is int && t > 0) {
        tarif = t;
        break;
      }
    }
    
    final Set<String> uniqueDays = schedules.expand((s) {
      final h = s['hari'];
      if (h is List) return h.map((e) => e.toString());
      if (h is String) return [h];
      return ['Setiap Hari'];
    }).toSet();
    
    final String hariOperasional;
    final lowerDays = uniqueDays.map((d) => d.toLowerCase()).toSet();
    if (lowerDays.contains('setiap hari') || lowerDays.contains('daily') || lowerDays.length >= 7) {
      hariOperasional = 'Setiap Hari';
    } else {
      hariOperasional = uniqueDays.map((day) {
        if (day.isEmpty) return day;
        return day[0].toUpperCase() + day.substring(1);
      }).join(', ');
    }

    final schedulesToday = schedules.where((s) {
      final h = s['hari'];
      List<String> listHari = [];
      if (h is List) {
        listHari = h.map((e) => e.toString().toLowerCase()).toList();
      } else if (h is String) {
        listHari = [h.toLowerCase()];
      }
      
      if (listHari.isEmpty) return true;
      return listHari.any((day) =>
        day == 'setiap hari' ||
        day == 'daily' ||
        day == todayEn ||
        day == todayId
      );
    }).toList();

    DateTime? nextDeparture;
    Map<String, dynamic>? nextScheduleRecord;
    final List<Map<String, dynamic>> allDepartures = [];
    
    if (schedulesToday.isNotEmpty) {
      int minDiff = 999999;
      for (final s in schedulesToday) {
        final jam = s['jam_berangkat']?.toString();
        if (jam == null || !jam.contains(':')) continue;
        final parts = jam.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final depTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
        final diff = depTimeToday.difference(now).inMinutes;
        
        final busInfo = _extractBusInfo(s);
        final formatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        allDepartures.add({
          'time': formatted,
          'isPast': diff <= 0,
          'isNext': false,
          'dateTime': depTimeToday,
          'poName': busInfo['poName'],
          'busType': busInfo['busType'],
          'busName': busInfo['busName'],
          'platNomor': busInfo['platNomor'],
          'tarif': s['tarif'],
        });

        if (diff > 0 && diff < minDiff) {
          minDiff = diff;
          nextDeparture = depTimeToday;
          nextScheduleRecord = s;
        }
      }
      
      // Sort by time and mark the next departure
      allDepartures.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));
      if (nextDeparture != null) {
        for (final dep in allDepartures) {
          final dt = dep['dateTime'] as DateTime;
          if (dt.hour == nextDeparture.hour && dt.minute == nextDeparture.minute) {
            dep['isNext'] = true;
            break;
          }
        }
      }
    }

    // Get bus info for the next departure (or first schedule as fallback)
    final nextBusInfo = _extractBusInfo(nextScheduleRecord ?? schedules.first);
    // Use tarif from next schedule if available, else fallback to global
    final nextTarif = nextScheduleRecord?['tarif'] as int? ?? tarif;

    if (nextDeparture != null) {
      final h = nextDeparture.hour.toString().padLeft(2, '0');
      final m = nextDeparture.minute.toString().padLeft(2, '0');
      return {
        'hasDeparturesToday': true,
        'nextDeparture': nextDeparture,
        'nextDepartureFormatted': '$h:$m WIB',
        'notice': null,
        'tarif': nextTarif,
        'hari': hariOperasional,
        'allDepartures': allDepartures,
        'nextBusInfo': nextBusInfo,
      };
    } else {
      String earliestTime = '08:00';
      int minHour = 24;
      int minMinute = 60;
      
      for (final s in schedules) {
        final jam = s['jam_berangkat']?.toString();
        if (jam == null || !jam.contains(':')) continue;
        final parts = jam.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        if (hour < minHour || (hour == minHour && minute < minMinute)) {
          minHour = hour;
          minMinute = minute;
          earliestTime = jam;
        }
      }

      String formattedTime = earliestTime;
      if (earliestTime.contains(':')) {
        final parts = earliestTime.split(':');
        if (parts.length >= 2) {
          formattedTime = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }

      final notice = 'Bus dengan rute terkait akan beroperasi besok pada jam $formattedTime WIB';
      return {
        'hasDeparturesToday': false,
        'nextDeparture': null,
        'nextDepartureFormatted': '$formattedTime WIB',
        'notice': notice,
        'tarif': nextTarif,
        'hari': hariOperasional,
        'allDepartures': allDepartures,
        'nextBusInfo': nextBusInfo,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _getScheduleInfo();
    final hasDepartures = info['hasDeparturesToday'] as bool;
    final isPureMandiri = (rute.id == 0);
    final nextBusInfo = info['nextBusInfo'] as Map<String, dynamic>? ?? {};

    // Real data from database
    final poName = nextBusInfo['poName'] as String? ?? rute.kode;
    final busType = nextBusInfo['busType'] as String? ?? 'ekonomi';
    final busName = nextBusInfo['busName'] as String?;
    final platNomor = nextBusInfo['platNomor'] as String?;
    final tarif = info['tarif'] as int?;
    final hariOps = info['hari'] as String? ?? '';
    
    // Determine type label and colors from actual bus data
    final String serviceLabel;
    final Color badgeColor;
    switch (busType.toLowerCase()) {
      case 'eksekutif':
        serviceLabel = 'Eksekutif';
        badgeColor = const Color(0xFF7C3AED); // Purple
        break;
      case 'bisnis':
        serviceLabel = 'Bisnis';
        badgeColor = const Color(0xFF0369A1); // Teal
        break;
      default:
        serviceLabel = 'Ekonomi';
        badgeColor = const Color(0xFF374151); // Dark grey
    }

    final duration = rute.estimasiMenit ?? 30;
    final durationText = '~$duration mnt';

    String formatTime(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m WIB';
    }

    if (isPureMandiri) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.motorcycle, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        rute.id == 0 ? 'Navigasi Mandiri' : 'Bus Tidak Aktif',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  durationText,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$halteAsal ➔ $halteTujuan',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMulai,
                icon: const Icon(
                  Icons.motorcycle,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Mulai Navigasi Mandiri',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
          // Header badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // PO Bus name badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        poName,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // Bus type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        serviceLabel,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (!hasDepartures)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_bus_filled_outlined, size: 12, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              'Bus Tidak Aktif',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                durationText,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bus info + tarif + operational days row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (busName != null || platNomor != null)
                        Text(
                          [busName, if (platNomor != null) '• $platNomor'].whereType<String>().join(' '),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 10, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            hariOps,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (tarif != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Rp ${_formatRupiah(tarif)}',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warning notice banner if no departures left today
          if (!hasDepartures)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info['notice'] ?? 'Jadwal keberangkatan hari ini sudah habis.',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Custom Timeline layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
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
                      halteAsal,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDepartures
                          ? 'Bus tiba di halte awal jam: ${info['nextDepartureFormatted']}'
                          : 'Operasional hari ini selesai',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasDepartures ? const Color(0xFFD97706) : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      halteTujuan,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDepartures
                          ? 'Estimasi Tiba: ${formatTime((info['nextDeparture'] as DateTime).add(Duration(minutes: duration)))}'
                          : 'Estimasi Tiba: -',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Jadwal Keberangkatan Hari Ini
          if ((info['allDepartures'] as List?)?.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      const Text(
                        'Jadwal Keberangkatan Hari Ini',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (info['allDepartures'] as List).map((dep) {
                      final isNext = dep['isNext'] as bool;
                      final isPast = dep['isPast'] as bool;
                      final depPoName = dep['poName'] as String?;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isNext
                              ? AppColors.primary
                              : (isPast ? const Color(0xFFF3F4F6) : const Color(0xFFEAF1FF)),
                          borderRadius: BorderRadius.circular(8),
                          border: isNext ? null : Border.all(color: isPast ? const Color(0xFFE5E7EB) : const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dep['time'] as String,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                                color: isNext
                                    ? Colors.white
                                    : (isPast ? const Color(0xFF9CA3AF) : const Color(0xFF1D4ED8)),
                                decoration: isPast ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (depPoName != null)
                              Text(
                                depPoName,
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isNext
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : (isPast ? const Color(0xFFBFC5CF) : const Color(0xFF6B7280)),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 20),
          
          // Mulai Navigasi Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onMulai,
              icon: Icon(
                !hasDepartures ? Icons.motorcycle : Icons.near_me_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                !hasDepartures ? 'Mulai Navigasi Mandiri' : 'Mulai Navigasi',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../core/theme/app_colors.dart';
import '../supabase/rute_service.dart';
import '../supabase/perjalanan_service.dart';
import '../supabase/halte_service.dart';

class NavigasiAktifScreen extends StatefulWidget {
  const NavigasiAktifScreen({super.key});

  @override
  State<NavigasiAktifScreen> createState() => _NavigasiAktifScreenState();
}

class _NavigasiAktifScreenState extends State<NavigasiAktifScreen> {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();
  final _mapController = MapController();

  bool _isLoading = true;
  bool _isAlmostThere = false;

  // Data Perjalanan
  Map<String, dynamic>? _perjalananAktif;
  List<LatLng> _titikPolyline = [];
  List<Map<String, dynamic>> _halteRute = [];
  Map<String, dynamic>? _halteBerikutnya;
  
  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304);
  int _sisaMenitTiba = 0;
  StreamSubscription<Position>? _gpsStream;

  @override
  void initState() {
    super.initState();
    _loadDataAktif();
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    super.dispose();
  }

  Future<void> _loadDataAktif() async {
    try {
      final aktif = await _perjalananService.getPerjalananAktif();
      if (aktif == null) {
        // Jika tidak ada perjalanan aktif, tutup layar ini
        if (mounted) Navigator.pop(context);
        return;
      }

      _perjalananAktif = aktif;

      // Load jalur polyline & halte dari rute
      final idRute = aktif['rute']['id'];
      final titik = await _ruteService.getTitikRute(idRute);
      _titikPolyline = titik.map((t) => LatLng(t['latitude'] as double, t['longitude'] as double)).toList();
      _halteRute = await _halteService.getHalteByRute(idRute);

      if (_titikPolyline.isNotEmpty && mounted) {
        _mapController.move(_titikPolyline.first, 15);
      }

      _mulaiLacakGps();
    } catch (e) {
      debugPrint('Error load aktif: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mulaiLacakGps() {
    _gpsStream?.cancel();
    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_lokasiSaatIni, 16);
        
        // Kalkulasi jarak ke tujuan & status "Hampir Sampai" (Kecepatan asumsi 25km/jam)
        final halteTujuan = _perjalananAktif?['halte_tujuan'];
        if (halteTujuan != null) {
          final jarak = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            (halteTujuan['latitude'] as num).toDouble(),
            (halteTujuan['longitude'] as num).toDouble(),
          );
          
          setState(() {
            _sisaMenitTiba = (jarak / 416).ceil();
            if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;
          });
          
          if (jarak < 500 && !_isAlmostThere) {
            setState(() => _isAlmostThere = true);
          }
        }
        
        _updateHalteBerikutnya(pos);
      }
    });
  }

  void _updateHalteBerikutnya(Position pos) {
    if (_halteRute.isEmpty) return;
    double jarakTerdekat = double.infinity;
    Map<String, dynamic>? halteTerdekat;

    for (var h in _halteRute) {
      final lat = (h['halte']['latitude'] as num).toDouble();
      final lon = (h['halte']['longitude'] as num).toDouble();
      
      final jarak = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon);
      if (jarak > 50 && jarak < jarakTerdekat) {
        jarakTerdekat = jarak;
        halteTerdekat = h['halte'];
      }
    }

    if (halteTerdekat != null && halteTerdekat['nama'] != _halteBerikutnya?['nama']) {
      setState(() {
        _halteBerikutnya = halteTerdekat;
      });
    }
  }

  Future<void> _selesaikanPerjalanan() async {
    if (_perjalananAktif == null) return;
    setState(() => _isLoading = true);
    try {
      final startTimeStr = _perjalananAktif!['waktu_mulai'] as String?;
      int durasiMenit = 1;
      if (startTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr).toLocal();
        durasiMenit = DateTime.now().difference(startTime).inMinutes;
        if (durasiMenit < 1) durasiMenit = 1;
      }
      await _perjalananService.selesaikanPerjalanan(
        idPerjalanan: _perjalananAktif!['id'], durasiMenit: durasiMenit
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _batalkanPerjalanan() async {
    if (_perjalananAktif == null) return;
    setState(() => _isLoading = true);
    try {
      await _perjalananService.batalkanPerjalanan(_perjalananAktif!['id']);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAlarm() async {
    if (_perjalananAktif == null) return;
    final isAlarmActive = _perjalananAktif!['alarm_aktif'] ?? false;
    await _perjalananService.toggleAlarm(idPerjalanan: _perjalananAktif!['id'], aktif: !isAlarmActive);
    final aktif = await _perjalananService.getPerjalananAktif();
    if (mounted) setState(() => _perjalananAktif = aktif);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _perjalananAktif == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chipBgColor = _isAlmostThere ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5);
    final chipTextColor = _isAlmostThere ? const Color(0xFFD97706) : const Color(0xFF059669);
    final chipIconColor = _isAlmostThere ? const Color(0xFFD97706) : const Color(0xFF10B981);
    final chipText = _isAlmostThere ? 'Hampir Sampai' : 'Navigasi Aktif';

    final ruteNama = _perjalananAktif!['rute']?['kode'] ?? 'Bus';
    final namaTujuan = _perjalananAktif!['halte_tujuan']?['nama'] ?? '-';
    final isAlarmActive = _perjalananAktif!['alarm_aktif'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: chipBgColor, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isAlmostThere ? Icons.wifi_tethering : Icons.circle, color: chipIconColor, size: 14),
                            const SizedBox(width: 6),
                            Text(chipText, style: TextStyle(color: chipTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    options: MapOptions(initialCenter: _lokasiSaatIni, initialZoom: 15),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.busguide.app'),
                      if (_titikPolyline.isNotEmpty)
                        PolylineLayer(polylines: [Polyline(points: _titikPolyline, color: AppColors.primary, strokeWidth: 5)]),
                      MarkerLayer(markers: [
                        if (_halteRute.isNotEmpty)
                          ..._halteRute.map((h) => Marker(
                            point: LatLng((h['halte']['latitude'] as num).toDouble(), (h['halte']['longitude'] as num).toDouble()),
                            width: 20, height: 20,
                            child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 3))),
                          )),
                        Marker(
                          point: _lokasiSaatIni,
                          width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                    ],
                  ),

                  // Panel Bawah
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.directions_bus, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Naik bus $ruteNama', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('Arah $namaTujuan', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Halte Berikutnya', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(_halteBerikutnya?['nama'] ?? namaTujuan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ])),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_filled, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Estimasi Tiba', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Row(children: [
                                        Text('~$_sisaMenitTiba mnt', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 6),
                                        GestureDetector(onTap: _toggleAlarm, child: Icon(isAlarmActive ? Icons.notifications_active : Icons.notifications_off, size: 16, color: isAlarmActive ? Colors.green : Colors.grey)),
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
                              Expanded(child: OutlinedButton.icon(onPressed: _batalkanPerjalanan, icon: const Icon(Icons.cancel, size: 18), label: const Text('Batalkan'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                              const SizedBox(width: 12),
                              Expanded(child: ElevatedButton.icon(onPressed: _selesaikanPerjalanan, icon: const Icon(Icons.check_circle, size: 18), label: const Text('Selesai'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
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
        ),
      ),
    );
  }
}
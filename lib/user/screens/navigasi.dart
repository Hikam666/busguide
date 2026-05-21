import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../templates/header.dart';
import '../supabase/rute_service.dart';
import '../supabase/perjalanan_service.dart';
import '../supabase/halte_service.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class NavigasiScreen extends StatefulWidget {
  const NavigasiScreen({super.key});

  @override
  State<NavigasiScreen> createState() => _NavigasiScreenState();
}

class _NavigasiScreenState extends State<NavigasiScreen> {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();
  final _mapController = MapController();

  bool _isLoading = false;
  bool _isMapLoading = false;

  // Data Search
  List<Map<String, dynamic>> _semuaHalte = [];
  Map<String, dynamic>? _halteAsal;
  Map<String, dynamic>? _halteTujuan;
  bool _alarmAktif = true;
  List<Map<String, dynamic>> _ruteTersedia = [];

  // Data Peta & GPS
  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304); // Default Malang
  List<LatLng> _titikPolyline = [];
  List<Map<String, dynamic>> _halteRute = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }


  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil data halte untuk dropdown/pencarian
      final halte = await _halteService.getSemuaHalte();
      if (mounted) setState(() => _semuaHalte = halte);

      // 2. Cek apakah ada perjalanan yang sedang aktif
      final aktif = await _perjalananService.getPerjalananAktif();
      if (aktif != null) {
        if (mounted) {
          Navigator.pushNamed(context, '/navigasi_aktif').then((_) {
            _resetState();
          });
        }
      } else {
        // Dapatkan lokasi awal untuk peta mode search
        await _dapatkanLokasiAwal();
      }
    } catch (e) {
      debugPrint('Error init navigasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dapatkanLokasiAwal() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Batas waktu maksimal 5 detik
      );
      setState(() {
        _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_lokasiSaatIni, 14);
    } catch (_) {}
  }

  // ─── FUNGSI PENCARIAN RUTE ──────────────────────────────────
  Future<void> _cariRute() async {
    if (_halteAsal == null || _halteTujuan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih halte asal dan tujuan terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final rute = await _ruteService.cariRute(
        idHalteAsal: _halteAsal!['id'],
        idHalteTujuan: _halteTujuan!['id'],
      );
      setState(() => _ruteTersedia = rute);
      
      if (rute.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada rute yang menghubungkan kedua halte ini.')),
        );
      } else {
        await _loadPolyline(rute.first['id']);
        final halteRute = await _halteService.getHalteByRute(rute.first['id']);
        setState(() {
          _halteRute = halteRute;
        });
      }
    } catch (e) {
      debugPrint('Error cari rute: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── FUNGSI MULAI NAVIGASI ──────────────────────────────────
  Future<void> _mulaiNavigasi(Map<String, dynamic> rute) async {
    setState(() => _isLoading = true);
    try {
      final perjalanan = await _perjalananService.mulaiPerjalanan(
        idRute: rute['id'],
        idHalteAsal: _halteAsal!['id'],
        idHalteTujuan: _halteTujuan!['id'],
      );
      
      // Update alarm sesuai toggle
      if (!_alarmAktif) {
        await _perjalananService.toggleAlarm(idPerjalanan: perjalanan['id'], aktif: false);
      }

      // Load jalur
      await _loadPolyline(rute['id']);
      _halteRute = await _halteService.getHalteByRute(rute['id']);

      if (mounted) {
        Navigator.pushNamed(context, '/navigasi_aktif').then((_) {
          _resetState();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai navigasi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPolyline(int idRute) async {
    setState(() => _isMapLoading = true);
    try {
      final titik = await _ruteService.getTitikRute(idRute);
      setState(() {
        _titikPolyline = titik.map((t) => LatLng(t['latitude'] as double, t['longitude'] as double)).toList();
      });
      if (_titikPolyline.isNotEmpty) {
        _mapController.move(_titikPolyline.first, 15);
      }
    } catch (_) {} finally {
      setState(() => _isMapLoading = false);
    }
  }

  void _resetState() {
    setState(() {
      _titikPolyline.clear();
      _halteRute.clear();
      _ruteTersedia.clear();
    });
  }

  // ─── UI BOTTOM SHEET PILIH HALTE ───────────────────────────
  void _bukaPilihHalte({required bool isAsal}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Text(isAsal ? 'Pilih Halte Asal' : 'Pilih Halte Tujuan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _semuaHalte.length,
                itemBuilder: (context, index) {
                  final h = _semuaHalte[index];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: isAsal ? AppColors.primary : Colors.red),
                    title: Text(h['nama'] ?? ''),
                    subtitle: Text(h['alamat'] ?? ''),
                    onTap: () {
                      setState(() {
                        if (isAsal) { _halteAsal = h; } else { _halteTujuan = h; }
                      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildScreenSearch(),
      ),
    );
  }

  // ==========================================
  // BUILDER LAYAR 1: SEARCH
  // ==========================================
  Widget _buildScreenSearch() {
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
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Ikon Kiri (Timeline)
                          Column(
                            children: [
                              const Icon(Icons.circle, color: AppColors.primary, size: 14),
                              Container(width: 2, height: 32, color: const Color(0xFFE5E7EB)),
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Input Asal & Tujuan
                          Expanded(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _bukaPilihHalte(isAsal: true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _halteAsal?['nama'] ?? 'Pilih halte asal...',
                                      style: TextStyle(fontSize: 14, color: _halteAsal != null ? AppColors.textPrimary : Colors.grey),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                GestureDetector(
                                  onTap: () => _bukaPilihHalte(isAsal: false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _halteTujuan?['nama'] ?? 'Pilih halte tujuan...',
                                      style: TextStyle(fontSize: 14, color: _halteTujuan != null ? AppColors.textPrimary : Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Swap
                          IconButton(
                            icon: const Icon(Icons.swap_vert, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                final temp = _halteAsal;
                                _halteAsal = _halteTujuan;
                                _halteTujuan = temp;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Alarm Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Aktifkan alarm halte tujuan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Switch(
                            value: _alarmAktif,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _alarmAktif = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tombol Cari Rute
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _cariRute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Cari Rute', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
                          options: MapOptions(initialCenter: _lokasiSaatIni, initialZoom: 13),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.busguide.app'),
                            if (_titikPolyline.isNotEmpty)
                              PolylineLayer(polylines: [
                                Polyline(points: _titikPolyline, color: AppColors.primary, strokeWidth: 4),
                              ]),
                            MarkerLayer(markers: [
                              if (_halteRute.isNotEmpty)
                                ..._halteRute.map((h) {
                                  return Marker(
                                    point: LatLng((h['halte']['latitude'] as num).toDouble(), (h['halte']['longitude'] as num).toDouble()),
                                    width: 16, height: 16,
                                    child: const Icon(Icons.circle, color: Colors.orange, size: 12),
                                  );
                                }),
                              Marker(
                                point: _lokasiSaatIni,
                                child: const Icon(Icons.my_location, color: AppColors.primary, size: 24),
                              ),
                            ]),
                          ],
                        ),
                        if (_isMapLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),

                // Section Rute Tersedia
                if (_ruteTersedia.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Rute Tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _ruteTersedia.length,
                    itemBuilder: (context, index) {
                      final rute = _ruteTersedia[index];
                      return _RuteTersediaCard(
                        rute: rute,
                        halteAsal: _halteAsal!['nama'],
                        halteTujuan: _halteTujuan!['nama'],
                        onMulai: () => _mulaiNavigasi(rute),
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
  final Map<String, dynamic> rute;
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Text(rute['kode'] ?? 'Bus', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rute['nama'] ?? 'Rute Bus',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text('~${rute['estimasi_menit'] ?? 25} mnt', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
            child: const Text('Lalu Lintas: Lancar', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ),
          const SizedBox(height: 16),
          // Timeline
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: AppColors.primary, size: 14),
                  Container(width: 2, height: 24, color: const Color(0xFFE5E7EB)),
                  const Icon(Icons.circle, color: Colors.red, size: 14),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(halteAsal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    Text(halteTujuan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
              label: const Text('Mulai Navigasi', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
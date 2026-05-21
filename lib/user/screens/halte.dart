import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../supabase/halte_service.dart';
import '../templates/header.dart';

class HalteScreen extends StatefulWidget {
  const HalteScreen({super.key});

  @override
  State<HalteScreen> createState() => _HalteScreenState();
}

class _HalteScreenState extends State<HalteScreen> {
  final HalteService _halteService = HalteService();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _semuaHalte = [];
  List<Map<String, dynamic>> _halteTerdekat = [];
  LatLng _titikPusat = const LatLng(-7.9797, 112.6304); // Default Malang
  String _labelLokasi = 'Mencari lokasi...';
  bool _pakaiGps = true;
  bool _isLoading = true;
  bool _isLoadingLokasi = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Muat data lokasi & halte ─────────────────────────────
  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Ambil semua data halte sekali saja
      final halte = await _halteService.getSemuaHalte();

      if (mounted) {
        setState(() {
          _semuaHalte = halte;
          _isLoading = false;
        });
        
        // Setelah data halte siap, dapatkan lokasi user
        await _dapatkanLokasi();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data halte. Periksa koneksi Anda.';
          _isLoading = false;
        });
      }
    }
  }

  // ── Dapatkan lokasi user ─────────────────────────────────
  Future<void> _dapatkanLokasi() async {
    setState(() => _isLoadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS mati');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin ditolak');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Izin ditolak permanen');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _titikPusat = LatLng(position.latitude, position.longitude);
          _labelLokasi = 'Lokasi Anda saat ini';
          _pakaiGps = true;
          _searchController.clear();
        });
        _mapController.move(_titikPusat, 14);
        _hitungHalteTerdekat();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _labelLokasi = 'Gagal mengambil GPS';
          _pakaiGps = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLokasi = false);
    }
  }

  // ── Hitung jarak Haversine ───────────────────────────────
  double _hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ── Format tampilan jarak ────────────────────────────────
  String _formatJarak(int jarakMeter) {
    if (jarakMeter < 1000) return '${jarakMeter}m';
    return '${(jarakMeter / 1000).toStringAsFixed(1)}km';
  }

  // ── Estimasi waktu jalan kaki (±80 m/menit) ─────────────
  String _estimasiWaktu(int jarakMeter) {
    final menit = (jarakMeter / 80).ceil();
    return '$menit Menit';
  }

  // ── Hitung halte terdekat berdasarkan titik pusat ────────
  void _hitungHalteTerdekat() {
    if (_semuaHalte.isEmpty) return;

    final halteWithJarak = _semuaHalte.map((h) {
      final jarak = _hitungJarak(
        _titikPusat.latitude,
        _titikPusat.longitude,
        (h['latitude'] as num).toDouble(),
        (h['longitude'] as num).toDouble(),
      );
      return {...h, 'jarak_meter': jarak.round()};
    }).toList();

    halteWithJarak.sort(
        (a, b) => (a['jarak_meter'] as int).compareTo(b['jarak_meter'] as int));

    setState(() {
      _halteTerdekat = halteWithJarak.take(5).toList();
    });
  }

  // ── Pencarian Lokasi (Geocoding API Nominatim) ───────────
  Future<void> _cariLokasi(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoadingLokasi = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'BusGuideApp/1.0',
      });

      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) {
        if (mounted) setState(() => _labelLokasi = 'Lokasi tidak ditemukan');
        return;
      }

      final lat = double.parse(results[0]['lat']);
      final lon = double.parse(results[0]['lon']);
      final displayName = results[0]['display_name'] as String;

      if (mounted) {
        setState(() {
          _titikPusat = LatLng(lat, lon);
          _labelLokasi = displayName.split(',').take(2).join(',').trim();
          _pakaiGps = false;
        });
        _mapController.move(_titikPusat, 14);
        _hitungHalteTerdekat();
      }
    } catch (e) {
      if (mounted) setState(() => _labelLokasi = 'Gagal mencari lokasi');
    } finally {
      if (mounted) setState(() => _isLoadingLokasi = false);
    }
  }

  // ── Buka navigasi Google Maps ────────────────────────────
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

  // ── Warna chip tipe halte ────────────────────────────────
  Color _warnaChip(String tipe) {
    switch (tipe.toLowerCase()) {
      case '1':
        return const Color(0xFF1A1A2E);
      case '3f':
        return const Color(0xFF2563EB);
      case '6m':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
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
      body: Column(
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
                          onSubmitted: _cariLokasi,
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
                        onTap: _isLoadingLokasi ? null : _dapatkanLokasi,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _pakaiGps ? AppColors.primary : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isLoadingLokasi
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(Icons.my_location_rounded,
                                  color: _pakaiGps ? Colors.white : const Color(0xFF6B7280), size: 18),
                        ),
                      ),
                    ],
                  ),

                  // Garis pemisah tipis
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

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
                            _labelLokasi,
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

          // ── Peta (Placeholder) ─────────────────────────
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
                  initialCenter: _titikPusat,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.busguide.app',
                  ),
                  MarkerLayer(
                    markers: [
                      ..._semuaHalte.map((h) {
                        return Marker(
                          point: LatLng((h['latitude'] as num).toDouble(), (h['longitude'] as num).toDouble()),
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
                        point: _titikPusat,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.my_location_rounded,
                          color: const Color(0xFFDC2626),
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
                if (!_isLoading)
                  Text(
                    '${_halteTerdekat.length} halte',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Konten Utama ───────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _halteTerdekat.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _halteTerdekat.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final halte = _halteTerdekat[index];
                              return _HalteCard(
                                nama: halte['nama'] as String,
                                alamat: halte['alamat'] as String? ?? '',
                                jarakLabel: _formatJarak(
                                    halte['jarak_meter'] as int),
                                waktuLabel: _estimasiWaktu(
                                    halte['jarak_meter'] as int),
                                tipeList: _parseTipe(halte['tipe']),
                                warnaChip: _warnaChip,
                                onNavigasi: () => _navigasiKeHalte(
                                  (halte['latitude'] as num).toDouble(),
                                  (halte['longitude'] as num).toDouble(),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ── Parse tipe halte menjadi list chip ───────────────────
  List<String> _parseTipe(dynamic tipe) {
    if (tipe == null) return [];
    if (tipe is List) return tipe.map((e) => e.toString()).toList();
    if (tipe is String) return tipe.split(',').map((e) => e.trim()).toList();
    return [];
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(_errorMessage,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _muatData,
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
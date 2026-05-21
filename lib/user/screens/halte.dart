import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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

  List<Map<String, dynamic>> _semuaHalte = [];
  List<Map<String, dynamic>> _halteTerfilter = [];
  Position? _posisiUser;
  bool _isLoading = true;
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
      _posisiUser = await _dapatkanLokasi();

      final halte = await _halteService.getHalteTerdekat(
        latitude: _posisiUser?.latitude ?? 0,
        longitude: _posisiUser?.longitude ?? 0,
      );

      // Hitung jarak untuk setiap halte
      final halteWithJarak = halte.map((h) {
        final jarak = _hitungJarak(
          _posisiUser?.latitude ?? 0,
          _posisiUser?.longitude ?? 0,
          (h['latitude'] as num).toDouble(),
          (h['longitude'] as num).toDouble(),
        );
        return {...h, 'jarak_meter': jarak.round()};
      }).toList();

      // Urutkan berdasarkan jarak terdekat
      halteWithJarak.sort(
          (a, b) => (a['jarak_meter'] as int).compareTo(b['jarak_meter'] as int));

      if (mounted) {
        setState(() {
          _semuaHalte = halteWithJarak;
          _halteTerfilter = halteWithJarak;
          _isLoading = false;
        });
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
  Future<Position?> _dapatkanLokasi() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
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

  // ── Filter pencarian ─────────────────────────────────────
  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _halteTerfilter = _semuaHalte;
      } else {
        _halteTerfilter = _semuaHalte
            .where((h) =>
                (h['nama'] as String)
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                (h['alamat'] as String? ?? '')
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
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
                          onChanged: _onSearch,
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
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: Colors.white, size: 18),
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
                        Text(
                          _posisiUser != null
                              ? 'Lokasi Anda saat ini'
                              : 'Lokasi tidak tersedia',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500),
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
              child: Stack(
                children: [
                  // Grid background map placeholder
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _MapGridPainter(),
                  ),
                  // Ikon pin tengah
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 36),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Lokasi Anda',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Drag handle bawah
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
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
                    '${_halteTerfilter.length} halte',
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
                    : _halteTerfilter.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _halteTerfilter.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final halte = _halteTerfilter[index];
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

// ── Painter: Grid Peta Placeholder ──────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8DDF0)
      ..strokeWidth = 0.8;

    // Garis horizontal
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Garis vertikal
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Garis jalan utama (horizontal)
    final jalanPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    canvas.drawLine(
        Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45),
        jalanPaint);

    // Garis jalan utama (diagonal/miring sedikit)
    canvas.drawLine(
        Offset(size.width * 0.3, 0),
        Offset(size.width * 0.5, size.height),
        jalanPaint);
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => false;
}
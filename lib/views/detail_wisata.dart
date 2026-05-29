import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../controllers/detail_wisata_controller.dart';
import '../models/wisata.dart';
import '../models/rute.dart';
import '../templates/bottom_navbar.dart';

class DetailWisataScreen extends StatefulWidget {
  final int idWisata;
  const DetailWisataScreen({super.key, required this.idWisata});

  @override
  State<DetailWisataScreen> createState() => _DetailWisataScreenState();
}

class _DetailWisataScreenState extends State<DetailWisataScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailWisataController>().loadData(widget.idWisata);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 3,
        onTap: _onTapBottomNav,
      ),
      body: Consumer<DetailWisataController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (ctrl.error != null) {
            return _BagianError(
              pesan: ctrl.error!,
              onRetry: () => ctrl.loadData(widget.idWisata),
            );
          }
          if (ctrl.wisata == null) {
            return _BagianError(
              pesan: 'Data wisata tidak ditemukan.',
              onRetry: () => ctrl.loadData(widget.idWisata),
            );
          }
          return _buildContent(ctrl.wisata!, ctrl.ruteList);
        },
      ),
    );
  }

  void _onTapBottomNav(int index) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/user',
      (route) => false,
      arguments: index,
    );
  }

  Widget _buildContent(Wisata w, List<Rute> ruteList) {
    return CustomScrollView(
      slivers: [
        _SliverFotoHeader(
          fotoUrl: w.fotoUrl,
          nama: w.nama,
          kota: w.kota,
          rating: w.rating,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deskripsi
                if (w.deskripsi != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    w.deskripsi!,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tarif masuk — full width card
                if (w.tarif != null) ...[
                  _TarifCard(tarif: w.tarifFormatted),
                  const SizedBox(height: 12),
                ],

                // Jam buka & Operasional — 2 kolom
                if (w.jamBuka != null || w.jamTutup != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          icon: Icons.access_time_rounded,
                          label: 'Jam buka',
                          value: w.jamBuka ?? '24 Jam',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoBox(
                          icon: Icons.calendar_today_rounded,
                          label: 'Operasional',
                          value: w.jamTutup ?? 'Setiap Hari',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                // Rute bus
                if (ruteList.isNotEmpty) ...[
                  const Text(
                    'Rute bus menuju sini',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ruteList.map((rute) => _RuteListItem(rute: rute)),
                  const SizedBox(height: 16),
                  _RuteDetailCard(rute: ruteList.first),
                ] else ...[
                  const SizedBox(height: 16),
                  const _StateInfo(
                    message: 'Belum ada rute bus yang tersedia untuk lokasi ini.',
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Sliver Header dengan overlay nama + lokasi + rating
// ──────────────────────────────────────────────
class _SliverFotoHeader extends StatelessWidget {
  final String? fotoUrl;
  final String nama;
  final String? kota;
  final double? rating;

  const _SliverFotoHeader({
    this.fotoUrl,
    required this.nama,
    this.kota,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'BusGuide',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      centerTitle: true,
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: const EdgeInsets.all(8),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary, size: 20),
            tooltip: 'Kembali',
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Foto
            fotoUrl != null
                ? Image.network(
                    fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FotoPlaceholder(),
                  )
                : const _FotoPlaceholder(),

            // Gradient gelap di bawah untuk teks overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x80000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Teks nama + lokasi + rating di atas foto
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (kota != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                kota!,
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Badge rating
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

// ──────────────────────────────────────────────
// Card tarif masuk — full width, ikon kotak gelap
// ──────────────────────────────────────────────
class _TarifCard extends StatelessWidget {
  final String tarif;
  const _TarifCard({required this.tarif});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_activity_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tarif masuk',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rp $tarif',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Info box — jam buka & operasional
// ──────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Rute list item — chip baris (mirip di screenshot)
// ──────────────────────────────────────────────
class _RuteListItem extends StatelessWidget {
  final Rute rute;
  const _RuteListItem({required this.rute});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Circle avatar biru dengan kode rute
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rute.kode,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rute.nama,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (rute.terminalAwal?.nama != null ||
                    rute.terminalAkhir?.nama != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(rute),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }

  String _subtitle(Rute rute) {
    final origin = rute.terminalAwal?.nama;
    final dest = rute.terminalAkhir?.nama;
    if (origin != null && dest != null) {
      return 'Naik di $origin, turun di $dest';
    }
    if (origin != null) return 'Naik di $origin';
    if (dest != null) return 'Tujuan $dest';
    return '';
  }
}

// ──────────────────────────────────────────────
// Rute detail card — dengan map preview & tombol navigasi
// ──────────────────────────────────────────────
class _RuteDetailCard extends StatelessWidget {
  final Rute rute;
  const _RuteDetailCard({required this.rute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map preview (menampilkan gambar peta OpenStreetMap jika tersedia)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _MapPreview(
                rute: rute,
                onTap: () => Navigator.pushNamed(context, '/navigasi_aktif'),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Map preview — tile OpenStreetMap atau placeholder
// ──────────────────────────────────────────────
class _MapPreview extends StatelessWidget {
  final Rute rute;
  final VoidCallback? onTap;
  const _MapPreview({required this.rute, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFD6E8C8)),
          CustomPaint(painter: _MapGridPainter()),

          if (onTap != null)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Ketuk untuk navigasi',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Jalan-jalan latar
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.65, 0),
        Offset(size.width * 0.65, size.height), roadPaint);

    // Rute merah
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.2)
      ..lineTo(size.width * 0.65, size.height * 0.2)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..lineTo(size.width * 0.85, size.height * 0.6);

    canvas.drawPath(path, routePaint..style = PaintingStyle.stroke);

    // Titik awal & akhir
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      5,
      Paint()..color = const Color(0xFF4CAF50),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.6),
      5,
      Paint()..color = const Color(0xFFE57373),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────
// Widget pendukung
// ──────────────────────────────────────────────
class _FotoPlaceholder extends StatelessWidget {
  const _FotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Color(0xFF9CA3AF), size: 48),
      ),
    );
  }
}

class _BagianError extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _BagianError({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFF6B7280), size: 40),
          const SizedBox(height: 12),
          Text(pesan,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi',
                style: TextStyle(color: Color(0xFF0D6EFD))),
          ),
        ],
      ),
    );
  }
}

class _StateInfo extends StatelessWidget {
  final String message;
  const _StateInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
    );
  }
}
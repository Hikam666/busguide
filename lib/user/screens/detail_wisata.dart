import 'package:flutter/material.dart';
import '../supabase/wisata_service.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class DetailWisataScreen extends StatefulWidget {
  final int idWisata;
  const DetailWisataScreen({super.key, required this.idWisata});

  @override
  State<DetailWisataScreen> createState() => _DetailWisataScreenState();
}

class _DetailWisataScreenState extends State<DetailWisataScreen> {
  final _wisataService = WisataService();

  Map<String, dynamic>? _wisata;
  List<Map<String, dynamic>> _ruteList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final wisata = await _wisataService.getDetailWisata(widget.idWisata);
      // Ambil rute yang melewati wisata ini (opsional, bisa gagal tanpa masalah)
      List<Map<String, dynamic>> ruteList = [];
      try {
        final raw = await _wisataService.getWisataByRute(widget.idWisata);
        ruteList = raw
            .map((e) => e['rute'] as Map<String, dynamic>?)
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _wisata = wisata;
          _ruteList = ruteList;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D6EFD)))
          : _error != null
              ? _BagianError(pesan: _error!, onRetry: _loadData)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final w = _wisata!;
    final fotoUrl = w['foto_url'] as String?;

    return CustomScrollView(
      slivers: [
        _SliverFotoHeader(fotoUrl: fotoUrl),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama
                Text(
                  w['nama'] ?? '-',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),

                if (w['alamat'] != null || w['kota'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF6B7280), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [w['kota'], w['alamat']].whereType<String>().join(', '),
                          style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (w['tarif'] != null)
                      _InfoChip(
                        icon: Icons.local_activity_rounded,
                        label: 'Rp ${_formatRupiah(w['tarif'])}', 
                        warna: const Color(0xFF3ECFB2),
                      ),
                    if (w['jam_buka'] != null && w['jam_tutup'] != null)
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: '${w['jam_buka']} – ${w['jam_tutup']}',
                        warna: const Color(0xFFF5A623),
                      ),
                  ],
                ),

                if (w['deskripsi'] != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Tentang Tempat Ini',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w['deskripsi'],
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                ],

                if (_ruteList.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Bisa Diakses Lewat Rute',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._ruteList.map((rute) => _RuteChipItem(rute: rute)),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(int angka) {
    return angka.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

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
          const Icon(Icons.error_outline_rounded, color: Color(0xFF6B7280), size: 40),
          const SizedBox(height: 12),
          Text(pesan, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi', style: TextStyle(color: Color(0xFF0D6EFD))),
          ),
        ],
      ),
    );
  }
}

class _SliverFotoHeader extends StatelessWidget {
  final String? fotoUrl;
  const _SliverFotoHeader({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFFF4F7FB),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: fotoUrl != null
            ? Image.network(fotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _FotoPlaceholder())
            : const _FotoPlaceholder(),
      ),
    );
  }
}

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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color warna;
  const _InfoChip({required this.icon, required this.label, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: warna, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuteChipItem extends StatelessWidget {
  final Map<String, dynamic> rute;
  const _RuteChipItem({required this.rute});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6EFD).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rute['kode'] ?? '-',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D6EFD),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rute['nama'] ?? '-',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
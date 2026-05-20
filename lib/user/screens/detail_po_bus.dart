import 'package:flutter/material.dart';
import '../supabase/po_bus_service.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class DetailPoBusScreen extends StatefulWidget {
  final int idPoBus;
  const DetailPoBusScreen({super.key, required this.idPoBus});

  @override
  State<DetailPoBusScreen> createState() => _DetailPoBusScreenState();
}

class _DetailPoBusScreenState extends State<DetailPoBusScreen> {
  final _poBusService = PoBusService();

  Map<String, dynamic>? _po;
  List<Map<String, dynamic>> _armadaList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final po = await _poBusService.getDetailPoBus(widget.idPoBus);
      final armada = await _poBusService.getArmadaByPo(widget.idPoBus);
      if (mounted) {
        setState(() {
          _po = po;
          _armadaList = armada;
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
    final po = _po!;
    final logoUrl = po['logo_url'] as String?;

    return CustomScrollView(
      slivers: [
        _SliverHeader(namaPo: po['nama']),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const _LogoPlaceholder()),
                            )
                          : const _LogoPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            po['nama'] ?? '-',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (po['tagline'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              po['tagline'],
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 13,
                                color: Color(0xFF0D6EFD),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (po['deskripsi'] != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Tentang PO',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    po['deskripsi'],
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                Row(
                  children: [
                    const Text(
                      'Armada Bus',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6EFD).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_armadaList.length}',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D6EFD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_armadaList.isEmpty)
                  const Text(
                    'Belum ada data armada',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  )
                else
                  ..._armadaList.map((bus) => _ArmadaCard(bus: bus)),

                const SizedBox(height: 40),
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

class _SliverHeader extends StatelessWidget {
  final String? namaPo;
  const _SliverHeader({this.namaPo});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFF4F7FB),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E), size: 20),
        ),
      ),
      title: Text(
        namaPo ?? '-',
        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.directions_bus_rounded, color: Color(0xFF9CA3AF), size: 32);
  }
}

class _ArmadaCard extends StatelessWidget {
  final Map<String, dynamic> bus;
  const _ArmadaCard({required this.bus});

  @override
  Widget build(BuildContext context) {
    final fasilitas = (bus['fasilitas'] as List?)?.cast<String>() ?? [];

    // Warna tipe bus
    final tipeColor = switch (bus['tipe'] as String? ?? '') {
      'eksekutif' => const Color(0xFFF5A623),
      'bisnis' => const Color(0xFF0D6EFD),
      _ => const Color(0xFF6B7280), // ekonomi
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Nomor polisi
              Text(
                bus['nomor_polisi'] ?? '-',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Tipe
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: tipeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _capitalize(bus['tipe'] ?? '-'),
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tipeColor,
                  ),
                ),
              ),
            ],
          ),

          if (bus['kapasitas'] != null) ...[
            const SizedBox(height: 6),
            Text(
              '${bus['kapasitas']} kursi',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],

          // Fasilitas
          if (fasilitas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: fasilitas
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
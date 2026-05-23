import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/detail_po_bus_controller.dart';
import '../models/po_bus.dart';

class DetailPoBusScreen extends StatefulWidget {
  final int idPoBus;
  const DetailPoBusScreen({super.key, required this.idPoBus});

  @override
  State<DetailPoBusScreen> createState() => _DetailPoBusScreenState();
}

class _DetailPoBusScreenState extends State<DetailPoBusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailPoBusController>().loadData(widget.idPoBus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Consumer<DetailPoBusController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D6EFD)));
          }
          if (ctrl.error != null) {
            return _BagianError(
                pesan: ctrl.error!,
                onRetry: () => ctrl.loadData(widget.idPoBus));
          }
          return _buildContent(ctrl.poBus!, ctrl.armadaList);
        },
      ),
    );
  }

  Widget _buildContent(PoBus po, List<Bus> armadaList) {
    return CustomScrollView(
      slivers: [
        _SliverHeader(namaPo: po.nama),
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
                      child: po.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(po.logoUrl!,
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
                            po.nama,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (po.tagline != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              po.tagline!,
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
                if (po.deskripsi != null) ...[
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
                    po.deskripsi!,
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
                        '${armadaList.length}',
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
                if (armadaList.isEmpty)
                  const Text(
                    'Belum ada data armada',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: Color(0xFF6B7280)),
                  )
                else
                  ...armadaList.map((bus) => _ArmadaCard(bus: bus)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
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
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF1A1A2E), size: 20),
        ),
      ),
      title: Text(
        namaPo ?? '-',
        style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E)),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.directions_bus_rounded,
        color: Color(0xFF9CA3AF), size: 32);
  }
}

class _ArmadaCard extends StatelessWidget {
  final Bus bus;
  const _ArmadaCard({required this.bus});

  @override
  Widget build(BuildContext context) {
    final fasilitas = bus.fasilitas;
    final tipeColor = switch (bus.tipe ?? '') {
      'eksekutif' => const Color(0xFFF5A623),
      'bisnis' => const Color(0xFF0D6EFD),
      _ => const Color(0xFF6B7280),
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
              Text(
                bus.nomorPolisi,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: tipeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bus.tipeLabel,
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
          if (bus.kapasitas != null) ...[
            const SizedBox(height: 6),
            Text(
              '${bus.kapasitas} kursi',
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: Color(0xFF6B7280)),
            ),
          ],
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
                        child: Text(f,
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                color: Color(0xFF4B5563))),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
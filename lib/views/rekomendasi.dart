import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rekomendasi_controller.dart';
import '../models/wisata.dart';
import '../models/po_bus.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RekomendasiController>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Consumer<RekomendasiController>(
          builder: (context, ctrl, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BagianHeader(tabController: _tabController),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWisataTab(ctrl),
                    _buildPoBusTab(ctrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB WISATA ──────────────────────────────────

  Widget _buildWisataTab(RekomendasiController ctrl) {
    if (ctrl.isLoadingWisata) return const _StateLoading();
    if (ctrl.errorWisata != null)
      return _StateError(
          pesan: ctrl.errorWisata!, onRetry: ctrl.loadWisata);
    if (ctrl.wisataList.isEmpty)
      return const _StateKosong(pesan: 'Belum ada data wisata');

    return RefreshIndicator(
      onRefresh: ctrl.loadWisata,
      color: const Color(0xFF0D6EFD),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: ctrl.wisataList.length,
        itemBuilder: (context, index) {
          final wisata = ctrl.wisataList[index];
          return _WisataCard(
            wisata: wisata,
            onTap: () => Navigator.pushNamed(
              context,
              '/detail-wisata',
              arguments: wisata.id,
            ),
          );
        },
      ),
    );
  }

  // ─── TAB PO BUS ──────────────────────────────────

  Widget _buildPoBusTab(RekomendasiController ctrl) {
    if (ctrl.isLoadingPoBus) return const _StateLoading();
    if (ctrl.errorPoBus != null)
      return _StateError(
          pesan: ctrl.errorPoBus!, onRetry: ctrl.loadPoBus);
    if (ctrl.poBusList.isEmpty)
      return const _StateKosong(pesan: 'Belum ada data PO Bus');

    return RefreshIndicator(
      onRefresh: ctrl.loadPoBus,
      color: const Color(0xFF0D6EFD),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: ctrl.poBusList.length,
        itemBuilder: (context, index) {
          final po = ctrl.poBusList[index];
          return _PoBusCard(
            po: po,
            onTap: () => Navigator.pushNamed(
              context,
              '/detail-po-bus',
              arguments: po.id,
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG
// ==========================================

class _BagianHeader extends StatelessWidget {
  final TabController tabController;
  const _BagianHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekomendasi',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wisata dan operator bus terbaik untukmu',
            style: TextStyle(fontFamily: 'DMSans', fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF0D6EFD),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 13),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              tabs: const [Tab(text: 'Wisata'), Tab(text: 'PO Bus')],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateLoading extends StatelessWidget {
  const _StateLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF0D6EFD)),
    );
  }
}

class _StateError extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _StateError({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 40),
          const SizedBox(height: 12),
          Text(
            pesan,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: Color(0xFF0D6EFD)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateKosong extends StatelessWidget {
  final String pesan;
  const _StateKosong({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        pesan,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _WisataCard extends StatelessWidget {
  final Wisata wisata;
  final VoidCallback onTap;

  const _WisataCard({required this.wisata, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fotoUrl = wisata.fotoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Foto
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: fotoUrl != null
                  ? Image.network(
                      fotoUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                    )
                  : _fotoPlaceholder(),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wisata.nama,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF6B7280), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        wisata.kota ?? wisata.alamat ?? '-',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      if (wisata.tarif != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3ECFB2).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Rp ${wisata.tarifFormatted}',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3ECFB2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.image_rounded,
          color: Color(0xFF9CA3AF), size: 40),
    );
  }
}

class _PoBusCard extends StatelessWidget {
  final PoBus po;
  final VoidCallback onTap;

  const _PoBusCard({required this.po, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final logoUrl = po.logoUrl;;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(logoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _logoPlaceholder()),
                    )
                  : _logoPlaceholder(),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    po.nama,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (po.tagline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      po.tagline!,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return const Icon(Icons.directions_bus_rounded,
        color: Color(0xFF9CA3AF), size: 26);
  }
}
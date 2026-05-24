import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rekomendasi_controller.dart';
import '../models/wisata.dart';
import '../models/po_bus.dart';
import '../templates/header.dart';

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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const AppHeader(
        title: 'BusGuide',
        showNotification: true,
        hasUnreadNotification: true,
      ),
      body: SafeArea(
        child: Consumer<RekomendasiController>(
          builder: (context, ctrl, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BagianHeader(
                tabController: _tabController,
                ctrl: ctrl,
              ),
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
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

// ─── HEADER (berubah dinamis sesuai tab) ─────────────

class _BagianHeader extends StatefulWidget {
  final TabController tabController;
  final RekomendasiController ctrl;

  const _BagianHeader({
    required this.tabController,
    required this.ctrl,
  });

  @override
  State<_BagianHeader> createState() => _BagianHeaderState();
}

class _BagianHeaderState extends State<_BagianHeader> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = widget.tabController.index;
      });
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String judul = _currentIndex == 0 ? 'Rekomendasi' : 'Rekomendasi';
    final String subtitle = _currentIndex == 0
        ? 'Temukan destinasi wisata dan armada bus terbaik untuk perjalananmu.'
        : 'Temukan destinasi wisata dan armada bus terbaik untuk perjalananmu.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul Halaman ────────────────────────
          Text(
            judul,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab Bar ──────────────────────────────
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x80C0C7D3), width: 1),
            ),
            child: TabBar(
              controller: widget.tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x33C0C7D3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x11000000),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 26),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overlayColor:
                  MaterialStateProperty.all(Colors.transparent),
              labelColor: const Color(0xFF1A1A2E),
              unselectedLabelColor: const Color(0xFF1A1A2E),
              tabs: const [Tab(text: 'Wisata'), Tab(text: 'PO Bus')],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── STATE WIDGETS ────────────────────────────────────

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
          const Icon(Icons.wifi_off_rounded,
              color: Color(0xFF6B7280), size: 40),
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

// ==========================================
// 3. WISATA CARD  — Grid 2 kolom
// ==========================================

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Foto + Bookmark ───────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: fotoUrl != null
                        ? Image.network(
                            fotoUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _fotoPlaceholder(),
                          )
                        : _fotoPlaceholder(),
                  ),

                  // ── PERBAIKAN: Icon bookmark sekarang terlihat ──
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded, // outline agar terlihat
                        color: Color(0xFF6B7280),       // warna abu-abu
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ──────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama
                    Text(
                      wisata.nama,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Lokasi
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFF6B7280), size: 11),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            wisata.kota ?? wisata.alamat ?? '-',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Deskripsi singkat
                    if (wisata.deskripsi != null)
                      Text(
                        wisata.deskripsi!,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.image_rounded,
          color: Color(0xFF9CA3AF), size: 32),
    );
  }
}

// ==========================================
// 4. PO BUS CARD  — List 1 kolom
// ==========================================

class _PoBusCard extends StatelessWidget {
  final PoBus po;
  final VoidCallback onTap;

  const _PoBusCard({required this.po, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fotoUrl = po.logoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto + Badge Kelas ────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                fotoUrl != null
                    ? Image.network(
                        fotoUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fotoBusPlaceholder(),
                      )
                    : _fotoBusPlaceholder(),

                if (po.tagline != null && po.tagline!.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        po.tagline!,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body Card ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + Ikon status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        po.nama,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusIcon(po),
                  ],
                ),

                const SizedBox(height: 12),

                // Deskripsi
                if (po.deskripsi != null)
                  Text(
                    po.deskripsi!,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 16),

                // Tombol Lihat Detail
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(PoBus po) {
    return const Icon(
      Icons.business_rounded,
      color: Color(0xFF9CA3AF),
      size: 18,
    );
  }

  Widget _fotoBusPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.directions_bus_rounded,
          color: Color(0xFF4B5563), size: 48),
    );
  }
}
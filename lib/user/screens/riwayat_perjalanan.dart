import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../templates/header.dart';

class RiwayatPerjalananScreen extends StatefulWidget {
  const RiwayatPerjalananScreen({super.key});

  @override
  State<RiwayatPerjalananScreen> createState() =>
      _RiwayatPerjalananScreenState();
}

class _RiwayatPerjalananScreenState extends State<RiwayatPerjalananScreen> {
  // ── State ────────────────────────────────────────────────
  String _filterStatus = 'semua'; // 'semua' | 'selesai' | 'dibatalkan'
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // ── Ambil data dari Supabase ─────────────────────────────
  // JOIN: perjalanan + riwayat_perjalanan + halte asal & tujuan + po_bus via rute > jadwal > bus > po_bus
  Future<void> _loadRiwayat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        setState(() { _isLoading = false; _error = 'Sesi tidak ditemukan.'; });
        return;
      }

      // Query perjalanan milik user ini, join ke halte asal & tujuan
      var query = Supabase.instance.client
          .from('perjalanan')
          .select('''
            id,
            status,
            waktu_mulai,
            waktu_selesai,
            alarm_aktif,
            halte_asal:halte!perjalanan_halte_asal_fkey(id, nama),
            halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama),
            rute:rute!perjalanan_id_rute_fkey(
              id,
              kode,
              nama,
              jadwal(
                id,
                bus(
                  id,
                  po_bus(id, nama)
                )
              )
            ),
            riwayat_perjalanan(id, durasi_menit, estimasi_biaya)
          ''')
          .eq('id_pengguna', uid)
          .order('waktu_mulai', ascending: false);

      final List data = await query;

      // Filter status jika bukan 'semua'
      final filtered = _filterStatus == 'semua'
          ? data
          : data
              .where((d) => d['status'] == _filterStatus)
              .toList();

      if (mounted) {
        setState(() {
          _riwayat = List<Map<String, dynamic>>.from(filtered);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat riwayat. Coba lagi.';
        });
      }
    }
  }

  // ── Ganti filter & reload ────────────────────────────────
  void _setFilter(String status) {
    if (_filterStatus == status) return;
    setState(() => _filterStatus = status);
    _loadRiwayat();
  }

  // ── Helper: nama PO dari data nested ────────────────────
  String _getNamaPO(Map<String, dynamic> item) {
    try {
      final rute = item['rute'];
      if (rute == null) return 'Bus';
      final jadwalList = rute['jadwal'] as List?;
      if (jadwalList == null || jadwalList.isEmpty) return rute['kode'] ?? 'Bus';
      final bus = jadwalList.first['bus'];
      if (bus == null) return rute['kode'] ?? 'Bus';
      final po = bus['po_bus'];
      return po?['nama'] ?? rute['kode'] ?? 'Bus';
    } catch (_) {
      return 'Bus';
    }
  }

  // ── Helper: id unik (TR-XXXXXX) ─────────────────────────
  String _getTripId(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '0';
    return 'TR-${id.padLeft(6, '0')}';
  }

  // ── Helper: format datetime ─────────────────────────────
  String _formatDateTime(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = months[dt.month];
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $month ${dt.year} • $hour:$min WIB';
    } catch (_) {
      return '-';
    }
  }

  // ── Helper: durasi display ───────────────────────────────
  String? _getDurasi(Map<String, dynamic> item) {
    try {
      final riwayat = item['riwayat_perjalanan'];
      if (riwayat == null) return null;
      final list = riwayat is List ? riwayat : [riwayat];
      if (list.isEmpty) return null;
      final menit = list.first['durasi_menit'] as int?;
      if (menit == null) return null;
      final jam = menit ~/ 60;
      final sisa = menit % 60;
      if (jam > 0 && sisa > 0) return '${jam}j ${sisa}m';
      if (jam > 0) return '${jam}j';
      return '${sisa}m';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'BusGuide', showBack: true),
      body: Column(
        children: [
          // ── Filter Chips ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  isActive: _filterStatus == 'semua',
                  onTap: () => _setFilter('semua'),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Selesai',
                  isActive: _filterStatus == 'selesai',
                  onTap: () => _setFilter('selesai'),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Dibatalkan',
                  isActive: _filterStatus == 'dibatalkan',
                  onTap: () => _setFilter('dibatalkan'),
                ),
              ],
            ),
          ),

          // ── Konten ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(
                        message: _error!,
                        onRetry: _loadRiwayat,
                      )
                    : _riwayat.isEmpty
                        ? _EmptyState(filterStatus: _filterStatus)
                        : RefreshIndicator(
                            onRefresh: _loadRiwayat,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _riwayat.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final item = _riwayat[i];
                                return _TripCard(
                                  namaPO: _getNamaPO(item),
                                  tripId: _getTripId(item),
                                  status: item['status'] ?? '',
                                  namaAsal: item['halte_asal']?['nama'] ?? '-',
                                  namaTujuan:
                                      item['halte_tujuan']?['nama'] ?? '-',
                                  waktuAsal:
                                      _formatDateTime(item['waktu_mulai']),
                                  waktuTujuan:
                                      _formatDateTime(item['waktu_selesai']),
                                  durasi: _getDurasi(item),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Filter Chip ──────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── Widget: Trip Card ────────────────────────────────────────
class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.namaPO,
    required this.tripId,
    required this.status,
    required this.namaAsal,
    required this.namaTujuan,
    required this.waktuAsal,
    required this.waktuTujuan,
    this.durasi,
  });

  final String namaPO;
  final String tripId;
  final String status;
  final String namaAsal;
  final String namaTujuan;
  final String waktuAsal;
  final String waktuTujuan;
  final String? durasi;

  // Badge warna berdasarkan status
  Color get _badgeColor {
    switch (status) {
      case 'selesai':
        return AppColors.primary;
      case 'dibatalkan':
        return const Color(0xFFEF4444);
      case 'aktif':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Color get _badgeBg {
    switch (status) {
      case 'selesai':
        return AppColors.primary;
      case 'dibatalkan':
        return const Color(0xFFFEE2E2);
      case 'aktif':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _badgeTextColor {
    switch (status) {
      case 'selesai':
        return Colors.white;
      case 'dibatalkan':
        return const Color(0xFFEF4444);
      case 'aktif':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _badgeLabel => status.toUpperCase();

  // Warna teks untuk perjalanan yang dibatalkan (dicoret)
  bool get _isCancelled => status == 'dibatalkan';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            // ── Header: Nama PO + Badge ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaPO,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $tripId',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Titik asal ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isCancelled
                              ? const Color(0xFF9CA3AF)
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    // Garis vertikal penghubung
                    Container(
                      width: 2,
                      height: 28,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaAsal,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isCancelled
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1A1A2E),
                          decoration: _isCancelled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        waktuAsal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Titik tujuan ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: _isCancelled
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF374151),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaTujuan,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isCancelled
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1A1A2E),
                          decoration: _isCancelled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        waktuTujuan,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Durasi (jika ada) ─────────────────────────
            if (durasi != null && !_isCancelled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 5),
                  Text(
                    durasi!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Widget: Empty State ──────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterStatus});
  final String filterStatus;

  String get _message {
    switch (filterStatus) {
      case 'selesai':
        return 'Belum ada perjalanan yang selesai.';
      case 'dibatalkan':
        return 'Belum ada perjalanan yang dibatalkan.';
      default:
        return 'Belum ada riwayat perjalanan.\nMulai navigasi pertamamu!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_outlined,
              size: 56, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Error State ──────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
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
}
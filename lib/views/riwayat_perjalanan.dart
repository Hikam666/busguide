import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../controllers/riwayat_controller.dart';
import '../templates/header.dart';
import '../models/perjalanan.dart';

class RiwayatPerjalananScreen extends StatefulWidget {
  const RiwayatPerjalananScreen({super.key});

  @override
  State<RiwayatPerjalananScreen> createState() =>
      _RiwayatPerjalananScreenState();
}

class _RiwayatPerjalananScreenState extends State<RiwayatPerjalananScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiwayatController>().loadRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'BusGuide', showBack: true),
      body: Consumer<RiwayatController>(
        builder: (context, ctrl, _) => Column(
          children: [
            // ── Filter Chips ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    isActive: ctrl.filterStatus == 'semua',
                    onTap: () => ctrl.setFilter('semua'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Selesai',
                    isActive: ctrl.filterStatus == 'selesai',
                    onTap: () => ctrl.setFilter('selesai'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Dibatalkan',
                    isActive: ctrl.filterStatus == 'dibatalkan',
                    onTap: () => ctrl.setFilter('dibatalkan'),
                  ),
                ],
              ),
            ),

            // ── Konten ───────────────────────────────────────────
            Expanded(
              child: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.error != null
                      ? _ErrorState(
                          message: ctrl.error!,
                          onRetry: ctrl.loadRiwayat,
                        )
                      : ctrl.riwayat.isEmpty
                          ? _EmptyState(filterStatus: ctrl.filterStatus)
                          : RefreshIndicator(
                              onRefresh: ctrl.loadRiwayat,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                itemCount: ctrl.riwayat.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (ctx, i) {
                                  final item = ctrl.riwayat[i];
                                  return _TripCard(
                                    perjalanan: item,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
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

// ── Widget: Trip Card ───────────────────────────────────────
class _TripCard extends StatelessWidget {
  const _TripCard({required this.perjalanan});
  final Perjalanan perjalanan;

  bool get _isCancelled => perjalanan.status == 'dibatalkan';

  Color get _badgeBg {
    switch (perjalanan.status) {
      case 'selesai': return AppColors.primary;
      case 'dibatalkan': return const Color(0xFFFEE2E2);
      case 'aktif': return const Color(0xFFD1FAE5);
      default: return const Color(0xFFF3F4F6);
    }
  }

  Color get _badgeTextColor {
    switch (perjalanan.status) {
      case 'selesai': return Colors.white;
      case 'dibatalkan': return const Color(0xFFEF4444);
      case 'aktif': return const Color(0xFF059669);
      default: return const Color(0xFF6B7280);
    }
  }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perjalanan.namaPO,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${perjalanan.tripId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    perjalanan.status.toUpperCase(),
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
            // Titik asal
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
                    Container(width: 2, height: 28, color: const Color(0xFFE5E7EB)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perjalanan.halteAsal?.nama ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isCancelled ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A2E),
                          decoration: _isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perjalanan.waktuMulaiFormatted,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Titik tujuan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: _isCancelled ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perjalanan.halteTujuan?.nama ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isCancelled ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A2E),
                          decoration: _isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perjalanan.waktuSelesaiFormatted,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Halte yang dilewati
            if (perjalanan.riwayat.isNotEmpty && !_isCancelled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 5),
                  Text('${perjalanan.riwayat.length} halte dilewati', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
      case 'selesai': return 'Belum ada perjalanan yang selesai.';
      case 'dibatalkan': return 'Belum ada perjalanan yang dibatalkan.';
      default: return 'Belum ada riwayat perjalanan.\nMulai navigasi pertamamu!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_outlined, size: 56, color: const Color(0xFFD1D5DB)),
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
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
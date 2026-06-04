import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../templates/header.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Tentang Aplikasi', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Logo & Nama App ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
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
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'BusGuide',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Perjalanan bus jadi lebih mudah ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Versi 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Deskripsi ────────────────────────────────
            _InfoCard(
              title: 'Tentang BusGuide',
              child: const Text(
                'BusGuide adalah aplikasi navigasi bus yang membantu pengguna '
                'menemukan rute perjalanan, halte terdekat, dan informasi bus dengan lebih mudah dan praktis. '
                'Selain itu, BusGuide juga menyediakan rekomendasi destinasi wisata '
                'yang dapat dijangkau menggunakan bus untuk mendukung '
                'perjalanan yang lebih nyaman dan menyenangkan.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Fitur Utama ──────────────────────────────
            _InfoCard(
              title: 'Fitur Utama',
              child: Column(
                children: const [
                  _FeatureItem(
                    icon: Icons.near_me_rounded,
                    label: 'Navigasi Rute Bus',
                    desc: 'Temukan rute bus terbaik dari lokasi kamu ke tujuan.',
                  ),
                  _FeatureItem(
                    icon: Icons.location_on_outlined,
                    label: 'Halte Terdekat',
                    desc: 'Lihat halte dan terminal bus di sekitar kamu.',
                  ),
                  _FeatureItem(
                    icon: Icons.notifications_outlined,
                    label: 'Alarm Halte Tujuan',
                    desc: 'Dapatkan notifikasi saat mendekati halte tujuan.',
                  ),
                  _FeatureItem(
                    icon: Icons.explore_outlined,
                    label: 'Rekomendasi Wisata',
                    desc: 'Temukan destinasi wisata yang bisa dicapai dengan bus.',
                  ),
                  _FeatureItem(
                    icon: Icons.directions_bus_outlined,
                    label: 'Info Armada PO Bus',
                    desc: 'Informasi lengkap PO bus, kelas, dan fasilitas.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Info Teknis ──────────────────────────────
            _InfoCard(
              title: 'Informasi Teknis',
              child: Column(
                children: [
                  _DetailRow(
                      label: 'Platform', value: 'Android'),
                  _DetailRow(
                      label: 'Framework', value: 'Flutter'),
                  _DetailRow(
                      label: 'Backend', value: 'Supabase'),
                  _DetailRow(
                      label: 'Database', value: 'PostgreSQL'),
                  _DetailRow(
                      label: 'Versi Aplikasi', value: '1.0.0'),
                  _DetailRow(
                      label: 'Pembaruan Terakhir',
                      value: 'Mei 2026',
                      isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Kontak & Dukungan ────────────────────────
            _InfoCard(
              title: 'Kontak & Dukungan',
              child: Column(
                children: [
                  _DetailRow(label: 'Email', value: 'pbl4@gmail.com'),
                  _DetailRow(
                      label: 'Website',
                      value: 'www.busguide.app',
                      isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Footer ───────────────────────────────────
            Text(
              '© 2026 BusGuide. Hak cipta dilindungi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Info Card ────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Widget: Feature Item ─────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.desc,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF1D6FEA)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          const Divider(
              height: 20,
              thickness: 1,
              color: Color(0xFFF3F4F6)),
      ],
    );
  }
}

// ── Widget: Detail Row ───────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        if (!isLast)
          const Divider(
              height: 16,
              thickness: 1,
              color: Color(0xFFF3F4F6)),
      ],
    );
  }
}
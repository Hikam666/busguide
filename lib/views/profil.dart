import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../controllers/profil_controller.dart';
import '../templates/header.dart';
import 'riwayat_perjalanan.dart';
import 'tentang_aplikasi.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    // Load profil saat pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilController>().loadProfile();
    });
  }

  Future<void> _handleLogout(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if ((confirm ?? false) && mounted) {
      await ctx.read<ProfilController>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'BusGuide', showBack: false),
      body: Consumer<ProfilController>(
        builder: (context, ctrl, _) => ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // ignore: unused_element - ctrl available from Consumer

                  // ── Avatar ──────────────────────────────
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          ctrl.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Nama & Email ─────────────────────────
                  Text(
                    ctrl.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ctrl.email,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),

                  const SizedBox(height: 14),

                  // ── Tombol Edit Profil ───────────────────
                  OutlinedButton(
                    onPressed: () {
                      // navigasi ke halaman edit profil (tambahkan nanti)
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 8),
                    ),
                    child: Text(
                      'Edit profil',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Menu Card ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Riwayat Perjalanan
                          _MenuTile(
                            icon: Icons.history_rounded,
                            label: 'Riwayat Perjalanan',
                            showArrow: true,
                            onTap: () {
                      
                              //    adalah StatefulWidget, tidak bisa const
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RiwayatPerjalananScreen(),
                                ),
                              );
                            },
                          ),
                          _Divider(),

                          // Perizinan Aplikasi
                          _MenuTile(
                            icon: Icons.shield_outlined,
                            label: 'Perizinan Aplikasi',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PermissionChip(
                                  icon: Icons.location_on_outlined,
                                  label: 'Lokasi',
                                ),
                                const SizedBox(width: 6),
                                _PermissionChip(
                                  icon: Icons.notifications_outlined,
                                  label: 'Notif',
                                ),
                              ],
                            ),
                          ),

                          _Divider(),

                          _Divider(),

                          // Tentang Aplikasi
                          _MenuTile(
  icon: Icons.info_outline_rounded,
  label: 'Tentang Aplikasi',
  showArrow: true,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TentangAplikasiScreen(),
      ),
    );
  },
),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tombol Keluar ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _handleLogout(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF0F0),
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Keluar',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
        // tutup Consumer
      ),
    );
  }
}

// ── Widget Helper: Menu Tile ─────────────────────────────────
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.showArrow = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showArrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF374151)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow && trailing == null)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

// ── Widget Helper: Divider ───────────────────────────────────
class _Divider extends StatelessWidget {
  _Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F4F6),
      indent: 18,
      endIndent: 18,
    );
  }
}

class _PermissionChip extends StatelessWidget {
  _PermissionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}










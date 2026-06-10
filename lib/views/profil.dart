import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';
import '../core/notification_service.dart';
import '../controllers/profil_controller.dart';
import '../templates/header.dart';
import 'riwayat_perjalanan.dart';
import 'tentang_aplikasi.dart';
import 'edit_profil.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    //Proses ambil data profil setelah widget selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilController>().loadProfile();
    });
  }

  Future<void> _handleLogout(BuildContext ctx) async { //Proses logout pengguna
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
      await ctx.read<ProfilController>().logout(); //Hapus sesi login pengguna
      if (mounted) {
        //Hapus seluruh halaman, kembali login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
          title: 'BusGuide', showBack: false, showNotification: false),
      body: Consumer<ProfilController>(
        builder: (context, ctrl, _) => ctrl.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // ── Avatar ──────────────────────────────
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar( //Menampilkan foto profil pengguna
                          radius: 48,
                          backgroundColor: AppColors.primary,
                          backgroundImage: ctrl.profile?.avatarUrl != null
                              ? NetworkImage(ctrl.profile!.avatarUrl!)
                              : null,
                          child: ctrl.profile?.avatarUrl == null
                              ? Text(
                                  ctrl.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
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
                    OutlinedButton( //Buka halaman edit profil
                      onPressed: () {
                        Navigator.push( //Pindah ke halaman edit profil
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilScreen()),
                        );
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

                    // ── Menu Card (semua item termasuk Keluar) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
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
                            // Riwayat Perjalanan
                            _MenuTile( //Menu lihat seluruh riwayat
                              icon: Icons.history_rounded,
                              label: 'Riwayat Perjalanan',
                              showArrow: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RiwayatPerjalananScreen(),
                                  ),
                                );
                              },
                            ),

                            _Divider(),

                            // Perizinan Aplikasi
                            _MenuTile(
                              icon: Icons.shield_outlined,
                              label: 'Perizinan Aplikasi',
                              onTap: () async {
                                final currentContext = context;
                                //Memeriksa, minta izin lokasi dan notifikasi
                                LocationPermission locPerm =
                                    await Geolocator.checkPermission();
                                if (locPerm == LocationPermission.denied) {
                                  locPerm =
                                      await Geolocator.requestPermission();
                                }
                                //Meminta izin notifikasi ke pengguna
                                final notifGranted =
                                    await NotificationService.requestPermission();

                                if (!currentContext.mounted) return;

                                final locGranted = (locPerm ==
                                        LocationPermission.whileInUse ||
                                    locPerm == LocationPermission.always);
                                if (locGranted && notifGranted) {
                                  ScaffoldMessenger.of(currentContext)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Perizinan lokasi & notifikasi sudah aktif!'),
                                    backgroundColor: Colors.green,
                                  ));
                                } else {
                                  ScaffoldMessenger.of(currentContext)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Perizinan belum lengkap. Anda bisa mengaktifkannya via pengaturan perangkat.'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              },
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

                            // Tentang Aplikasi
                            _MenuTile(
                              icon: Icons.info_outline_rounded,
                              label: 'Tentang Aplikasi',
                              showArrow: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TentangAplikasiScreen(),
                                  ),
                                );
                              },
                            ),

                            _Divider(),

                            // ── Keluar (di dalam card, dengan styling merah) ──
                            _LogoutTile(
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
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

// ── Widget: Logout Tile (merah, ikon pintu keluar) ───────────
class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            // Ikon pintu keluar (logout door)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Keluar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                  inherit: false,         // ← tidak mewarisi tema apapun
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFDC2626),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget Helper: Divider ───────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider({super.key});

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

// ── Widget Helper: Permission Chip ───────────────────────────
//Jenis izin aplikasi
class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.icon, required this.label});

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
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
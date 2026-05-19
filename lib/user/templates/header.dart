import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Standard app header / AppBar untuk BusGuide.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppHeader(title: 'BusGuide'),
/// )
/// ```
///
/// Atau dengan back button:
/// ```dart
/// AppHeader(title: 'Detail Halte', showBack: true)
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Tampilkan tombol back. Default: otomatis (true jika ada route sebelumnya).
  final bool? showBack;

  /// Aksi kustom saat back ditekan. Default: Navigator.pop.
  final VoidCallback? onBack;

  /// Widget di sisi kanan (trailing actions).
  final List<Widget>? actions;

  /// Tampilkan divider bawah.
  final bool showDivider;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack,
    this.onBack,
    this.actions,
    this.showDivider = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final displayBack = showBack ?? canPop;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            // Status bar spacer
            SizedBox(height: MediaQuery.of(context).padding.top),

            // Header bar
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    // Back button
                    if (displayBack)
                      _HeaderIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 48),

                    // Title (centered)
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Trailing actions
                    if (actions != null && actions!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    else
                      // Default: 3-dots menu placeholder (sesuai design)
                      _HeaderIconButton(
                        icon: Icons.more_vert_rounded,
                        onTap: () {}, // hook to your menu
                      ),
                  ],
                ),
              ),
            ),

            // Divider
            if (showDivider)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

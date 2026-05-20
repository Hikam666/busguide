import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showDivider;

  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack,
    this.onBack,
    this.actions,
    this.showDivider = true,
    this.showNotification = false,     
    this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(showDivider ? 57 : 56);

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
            SizedBox(height: MediaQuery.of(context).padding.top),

            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    if (displayBack)
                      _HeaderIconButton(
                        icon: Icons.chevron_left_rounded,
                        iconSize: 28,
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 48),

                    // Title (selalu center)
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

                    // Kanan: actions custom > bell > spacer
                    if (actions != null && actions!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    else if (showNotification)
                      _NotificationButton(
                        hasUnread: hasUnreadNotification,
                        onTap: onNotificationTap ?? () {},
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            if (showDivider)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.hasUnread,
    required this.onTap,
  });

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_outlined,
                  size: 22, color: AppColors.textPrimary),
              if (hasUnread)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
  });

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
          child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
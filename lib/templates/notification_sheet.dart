import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../controllers/notifikasi_controller.dart';
import '../models/notifikasi.dart';

// Global ValueNotifier to track unread notifications
final ValueNotifier<bool> hasUnreadNotifications = ValueNotifier(false);

// Shows the notification panel
void showNotificationBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const NotificationSheetWidget(),
  );
}

class NotificationSheetWidget extends StatefulWidget {
  const NotificationSheetWidget({super.key});

  @override
  State<NotificationSheetWidget> createState() => _NotificationSheetWidgetState();
}

class _NotificationSheetWidgetState extends State<NotificationSheetWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotifikasiController>().fetchNotifikasi();
    });
  }

  void _markAllAsRead() {
    context.read<NotifikasiController>().tandaiSemuaDibaca();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sebagai dibaca'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleRead(Notifikasi notification) {
    context.read<NotifikasiController>().tandaiDibaca(notification.id);
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'wisata':
      case 'info':
        return Icons.explore_rounded;
      case 'perjalanan':
      case 'selesai':
        return Icons.directions_bus_rounded;
      case 'po':
      case 'alarm':
        return Icons.notifications_active_rounded;
      case 'jadwal':
        return Icons.calendar_month_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'wisata':
      case 'info':
        return const Color(0xFF0284C7); // Light Blue
      case 'perjalanan':
      case 'selesai':
        return const Color(0xFF059669); // Emerald Green
      case 'po':
      case 'alarm':
        return const Color(0xFFD97706); // Amber/Orange
      case 'jadwal':
        return const Color(0xFF7E22CE); // Purple
      default:
        return AppColors.primary;
    }
  }

  Color _getBgColor(String type) {
    return _getColor(type).withOpacity(0.08);
  }

  String _getDefaultTitle(String type) {
    switch (type.toLowerCase()) {
      case 'wisata':
      case 'info':
        return 'Destinasi Populer Baru!';
      case 'perjalanan':
      case 'selesai':
        return 'Perjalanan Selesai!';
      case 'po':
      case 'alarm':
        return 'Armada Baru!';
      case 'jadwal':
        return 'Penyesuaian Jadwal!';
      default:
        return 'Notifikasi Baru';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header title and actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: const Text(
                    'Tandai dibaca',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          // Scrollable Notifications List
          Expanded(
            child: Consumer<NotifikasiController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.notifikasiList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: ctrl.notifikasiList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final item = ctrl.notifikasiList[idx];
                    final icon = _getIcon(item.tipe);
                    final color = _getColor(item.tipe);
                    final bg = _getBgColor(item.tipe);
                    final title = item.judul ?? _getDefaultTitle(item.tipe);
                    final timeAgoText = _getTimeAgo(item.tanggalKirim);

                    return GestureDetector(
                      onTap: () => _toggleRead(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.statusBaca ? Colors.white : const Color(0xFFF9FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.statusBaca ? const Color(0xFFF3F4F6) : const Color(0xFFE0E7FF),
                            width: 1,
                          ),
                          boxShadow: item.statusBaca
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon circle
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: bg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),

                            // Title, text, time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: item.statusBaca ? FontWeight.w600 : FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (!item.statusBaca)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.pesan,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.statusBaca ? const Color(0xFF6B7280) : const Color(0xFF374151),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    timeAgoText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

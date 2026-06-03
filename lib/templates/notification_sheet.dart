import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// In-memory Notification Model
class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type; // 'wisata' | 'perjalanan' | 'po' | 'jadwal'
  final String timeAgo;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeAgo,
    this.isRead = false,
  });
}

// Global ValueNotifier to track unread notifications
final ValueNotifier<bool> hasUnreadNotifications = ValueNotifier(true);

// Static list of session notifications
final List<AppNotification> appNotifications = [
  AppNotification(
    id: 1,
    title: 'Destinasi Populer Baru!',
    message: 'Malang Night Paradise kini tersedia di direktori wisata. Jelajahi keindahannya sekarang!',
    type: 'wisata',
    timeAgo: '1 jam yang lalu',
  ),
  AppNotification(
    id: 2,
    title: 'Perjalanan Selesai!',
    message: 'Perjalanan Anda TR-000059 telah selesai direkam dengan durasi 12 menit.',
    type: 'perjalanan',
    timeAgo: '3 jam yang lalu',
  ),
  AppNotification(
    id: 3,
    title: 'Armada Baru!',
    message: 'PO Menggala bergabung dengan rute Malang - Surabaya. Nikmati perjalanan dengan PO favorit Anda.',
    type: 'po',
    timeAgo: '1 hari yang lalu',
  ),
  AppNotification(
    id: 4,
    title: 'Penyesuaian Jadwal!',
    message: 'Rute AL (Terminal Arjosari - Landungsari) mengalami penyesuaian waktu keberangkatan di jam malam.',
    type: 'jadwal',
    timeAgo: '2 hari yang lalu',
  ),
];

// Helper function to update the global unread badge
void updateUnreadStatus() {
  hasUnreadNotifications.value = appNotifications.any((n) => !n.isRead);
}

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
  void _markAllAsRead() {
    setState(() {
      for (var notification in appNotifications) {
        notification.isRead = true;
      }
      updateUnreadStatus();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sebagai dibaca'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleRead(AppNotification notification) {
    setState(() {
      notification.isRead = true;
      updateUnreadStatus();
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'wisata':
        return Icons.explore_rounded;
      case 'perjalanan':
        return Icons.directions_bus_rounded;
      case 'po':
        return Icons.business_rounded;
      case 'jadwal':
        return Icons.calendar_month_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'wisata':
        return const Color(0xFF0284C7); // Light Blue
      case 'perjalanan':
        return const Color(0xFF059669); // Emerald Green
      case 'po':
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
            child: ListView.separated(
              itemCount: appNotifications.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = appNotifications[idx];
                final icon = _getIcon(item.type);
                final color = _getColor(item.type);
                final bg = _getBgColor(item.type);

                return GestureDetector(
                  onTap: () => _toggleRead(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.white : const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isRead ? const Color(0xFFF3F4F6) : const Color(0xFFE0E7FF),
                        width: 1,
                      ),
                      boxShadow: item.isRead
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
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (!item.isRead)
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
                                item.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isRead ? const Color(0xFF6B7280) : const Color(0xFF374151),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.timeAgo,
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
            ),
          ),
        ],
      ),
    );
  }
}

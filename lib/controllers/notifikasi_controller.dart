import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi.dart';
import '../models/notifikasi_service.dart';
import '../templates/notification_sheet.dart' show hasUnreadNotifications;
import '../core/notification_service.dart';

class NotifikasiController extends ChangeNotifier {
  final _service = NotifikasiService();

  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = false;

  Timer? _pollingTimer;
  RealtimeChannel? _realtimeChannel;
  final Set<int> _notifiedIds = {};
  bool _isFirstFetch = true;
  bool _hasRequestedPermission = false;

  List<Notifikasi> get notifikasiList => _notifikasiList;
  bool get isLoading => _isLoading;

  NotifikasiController() {
    startPolling();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollNotifikasi();
    });
    // Run initial poll asynchronously after constructor returns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollNotifikasi();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  // Subscribe to real-time inserts on the notifikasi table
  void startRealtimeSubscription(String userId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('public:notifikasi')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final id = (newRecord['id'] as num).toInt();
            final idPengguna = newRecord['id_pengguna'] as String?;

            // Filter for the current user's notifications (personal or broadcast)
            if (idPengguna == null || idPengguna == userId) {
              final notif = Notifikasi.fromMap(newRecord);

              if (!_notifiedIds.contains(notif.id)) {
                _notifiedIds.add(notif.id);

                // Insert at the beginning of the list since it's the newest
                _notifikasiList.insert(0, notif);
                hasUnreadNotifications.value = _notifikasiList.any((n) => !n.statusBaca);
                notifyListeners();

                if (!notif.statusBaca) {
                  await NotificationService.showNotification(
                    id: notif.id,
                    title: notif.judul ?? 'Notifikasi Baru',
                    body: notif.pesan,
                  );
                }
              }
            }
          },
        );
    _realtimeChannel!.subscribe();
  }

  // Polling notifications silently every 10 seconds
  Future<void> _pollNotifikasi() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // User is not logged in, reset state cache
      _isFirstFetch = true;
      _notifiedIds.clear();
      _hasRequestedPermission = false;
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
      if (_notifikasiList.isNotEmpty) {
        _notifikasiList = [];
        hasUnreadNotifications.value = false;
        notifyListeners();
      }
      return;
    }

    if (!_hasRequestedPermission) {
      _hasRequestedPermission = true;
      try {
        await NotificationService.requestPermission();
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }
      startRealtimeSubscription(userId);
    }

    try {
      final list = await _service.getNotifikasi();

      // Detect new unread notifications
      for (final notif in list) {
        if (!notif.statusBaca) {
          if (!_notifiedIds.contains(notif.id)) {
            _notifiedIds.add(notif.id);

            // Trigger local system notification if:
            // - It is not the first fetch, OR
            // - It is the first fetch but the notification was sent very recently (e.g. within 10 minutes)
            final isRecent = DateTime.now().difference(notif.tanggalKirim).inMinutes.abs() < 10;
            if (!_isFirstFetch || isRecent) {
              await NotificationService.showNotification(
                id: notif.id,
                title: notif.judul ?? 'Notifikasi Baru',
                body: notif.pesan,
              );
            }
          }
        }
      }

      // Mark first fetch as completed once notifications are processed
      _isFirstFetch = false;

      _notifikasiList = list;
      hasUnreadNotifications.value = _notifikasiList.any((n) => !n.statusBaca);
      notifyListeners();
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  // Load all notifications from Supabase (manually triggered, shows loading state)
  Future<void> fetchNotifikasi() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifikasiList = await _service.getNotifikasi();

      // Synchronize locally notified status
      for (final notif in _notifikasiList) {
        if (!notif.statusBaca) {
          _notifiedIds.add(notif.id);
        }
      }
      _isFirstFetch = false;

      // Update global unread badge
      hasUnreadNotifications.value = _notifikasiList.any((n) => !n.statusBaca);
    } catch (_) {
      _notifikasiList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a single notification as read
  Future<void> tandaiDibaca(int idNotifikasi) async {
    // Optimistic update locally
    final index = _notifikasiList.indexWhere((n) => n.id == idNotifikasi);
    if (index != -1 && !_notifikasiList[index].statusBaca) {
      final oldNotif = _notifikasiList[index];
      _notifikasiList[index] = Notifikasi(
        id: oldNotif.id,
        idPerjalanan: oldNotif.idPerjalanan,
        idPengguna: oldNotif.idPengguna,
        judul: oldNotif.judul,
        pesan: oldNotif.pesan,
        tipe: oldNotif.tipe,
        tanggalKirim: oldNotif.tanggalKirim,
        statusBaca: true,
        thresholdJarak: oldNotif.thresholdJarak,
      );
      hasUnreadNotifications.value = _notifikasiList.any((n) => !n.statusBaca);
      notifyListeners();

      // Update database asynchronously
      await _service.tandaiDibaca(idNotifikasi);
    }
  }

  // Mark all notifications as read
  Future<void> tandaiSemuaDibaca() async {
    bool hasUnread = _notifikasiList.any((n) => !n.statusBaca);
    if (!hasUnread) return;

    // Optimistic update locally
    _notifikasiList = _notifikasiList.map((n) {
      if (!n.statusBaca) {
        return Notifikasi(
          id: n.id,
          idPerjalanan: n.idPerjalanan,
          idPengguna: n.idPengguna,
          judul: n.judul,
          pesan: n.pesan,
          tipe: n.tipe,
          tanggalKirim: n.tanggalKirim,
          statusBaca: true,
          thresholdJarak: n.thresholdJarak,
        );
      }
      return n;
    }).toList();

    hasUnreadNotifications.value = false;
    notifyListeners();

    // Update database asynchronously
    await _service.tandaiSemuaDibaca();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

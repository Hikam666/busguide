import 'package:flutter/material.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/perjalanan.dart';

class RiwayatController extends ChangeNotifier {
  final _perjalananService = PerjalananService();

  String _filterStatus = 'semua'; // 'semua' | 'selesai' | 'dibatalkan'
  List<Perjalanan> _riwayat = [];
  bool _isLoading = true;
  String? _error;

  // ─── GETTERS ─────────────────────────────────────────────
  String get filterStatus => _filterStatus;
  List<Perjalanan> get riwayat => _riwayat;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── LOAD RIWAYAT ─────────────────────────────────────────
  Future<void> loadRiwayat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _perjalananService.getRiwayatLengkap(
        filterStatus: _filterStatus,
      );
      _riwayat = data;
    } catch (_) {
      _error = 'Gagal memuat riwayat. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── SET FILTER ───────────────────────────────────────────
  Future<void> setFilter(String status) async {
    if (_filterStatus == status) return;
    _filterStatus = status;
    notifyListeners();
    await loadRiwayat();
  }
}

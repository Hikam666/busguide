import 'package:flutter/material.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/perjalanan.dart';

//Kelola data riwayat perjalanan pengguna
class RiwayatController extends ChangeNotifier {
  //Ambil data riwayat dari backend/API
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
  //Mengambil data riwayat dari server
  Future<void> loadRiwayat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _perjalananService.getRiwayatLengkap(
        filterStatus: _filterStatus,
      );
      //Menyimpan data yang diterima dri server
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
    _filterStatus = status; //Menyimpan filter baru
    notifyListeners(); //Update UI
    await loadRiwayat();
  }
}

import 'package:flutter/material.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/wisata_service.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/wisata.dart';

class HomeController extends ChangeNotifier {
  final _perjalananService = PerjalananService();
  final _wisataService = WisataService();

  List<Perjalanan> _riwayatList = [];
  List<Wisata> _rekomendasiList = [];
  bool _isLoading = true;

  // ─── GETTERS ─────────────────────────────────────────────
  List<Perjalanan> get riwayatList => _riwayatList;
  List<Wisata> get rekomendasiList => _rekomendasiList;
  bool get isLoading => _isLoading;

  // ─── LOAD DATA ────────────────────────────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final riwayat = await _perjalananService.getRiwayatPerjalanan();
      final wisata = await _wisataService.getSemuaWisata();

      _riwayatList = riwayat.take(2).toList(); // Tampilkan 2 riwayat terakhir
      _rekomendasiList = wisata.take(3).toList(); // Tampilkan 3 rekomendasi
    } catch (_) {
      // Error ditangani secara diam-diam; state kosong akan tampil empty state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

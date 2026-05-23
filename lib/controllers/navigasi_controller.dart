import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/rute_service.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/halte.dart';
import 'package:busguide/models/rute.dart';

class NavigasiController extends ChangeNotifier {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();

  bool _isLoading = false;
  bool _isMapLoading = false;
  bool _adaPerjalananAktif = false;

  // Data Search
  List<Halte> _semuaHalte = [];
  Halte? _halteAsal;
  Halte? _halteTujuan;
  bool _alarmAktif = true;
  List<Rute> _ruteTersedia = [];

  // Data Peta & GPS
  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304); // Default Malang
  List<LatLng> _titikPolyline = [];
  List<RuteHalte> _halteRute = [];

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isMapLoading => _isMapLoading;
  bool get adaPerjalananAktif => _adaPerjalananAktif;
  List<Halte> get semuaHalte => _semuaHalte;
  Halte? get halteAsal => _halteAsal;
  Halte? get halteTujuan => _halteTujuan;
  bool get alarmAktif => _alarmAktif;
  List<Rute> get ruteTersedia => _ruteTersedia;
  LatLng get lokasiSaatIni => _lokasiSaatIni;
  List<LatLng> get titikPolyline => _titikPolyline;
  List<RuteHalte> get halteRute => _halteRute;

  // ─── INIT DATA ────────────────────────────────────────────
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ambil data halte untuk dropdown/pencarian
      final halte = await _halteService.getSemuaHalte();
      _semuaHalte = halte;

      // 2. Cek apakah ada perjalanan yang sedang aktif
      final aktif = await _perjalananService.getPerjalananAktif();
      if (aktif != null) {
        _adaPerjalananAktif = true;
        notifyListeners();
        return;
      }

      // Dapatkan lokasi awal untuk peta
      await _dapatkanLokasiAwal();
    } catch (e) {
      debugPrint('Error init navigasi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _dapatkanLokasiAwal() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {}
  }

  // ─── PILIH HALTE ──────────────────────────────────────────
  void pilihHalteAsal(Halte halte) {
    _halteAsal = halte;
    notifyListeners();
  }

  void pilihHalteTujuan(Halte halte) {
    _halteTujuan = halte;
    notifyListeners();
  }

  void tukarHalte() {
    final temp = _halteAsal;
    _halteAsal = _halteTujuan;
    _halteTujuan = temp;
    notifyListeners();
  }

  void setAlarm(bool aktif) {
    _alarmAktif = aktif;
    notifyListeners();
  }

  // ─── CARI RUTE ────────────────────────────────────────────
  /// Mengembalikan pesan error atau null jika berhasil
  Future<String?> cariRute() async {
    if (_halteAsal == null || _halteTujuan == null) {
      return 'Pilih halte asal dan tujuan terlebih dahulu';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final rute = await _ruteService.cariRute(
        idHalteAsal: _halteAsal!.id,
        idHalteTujuan: _halteTujuan!.id,
      );
      _ruteTersedia = rute;

      if (rute.isEmpty) {
        return 'Tidak ada rute yang menghubungkan kedua halte ini.';
      }

      // Load polyline untuk rute pertama
      await _loadPolyline(rute.first.id);
      _halteRute = await _halteService.getHalteByRute(rute.first.id);
      return null;
    } catch (e) {
      debugPrint('Error cari rute: $e');
      return 'Gagal mencari rute. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── MULAI NAVIGASI ───────────────────────────────────────
  /// Mengembalikan pesan error atau null jika berhasil
  Future<String?> mulaiNavigasi(Rute rute) async {
    _isLoading = true;
    notifyListeners();

    try {
      final perjalanan = await _perjalananService.mulaiPerjalanan(
        idRute: rute.id,
        idHalteAsal: _halteAsal!.id,
        idHalteTujuan: _halteTujuan!.id,
      );

      // Update alarm sesuai toggle
      if (!_alarmAktif) {
        await _perjalananService.toggleAlarm(
          idPerjalanan: perjalanan.id,
          aktif: false,
        );
      }

      await _loadPolyline(rute.id);
      _halteRute = await _halteService.getHalteByRute(rute.id);
      _adaPerjalananAktif = true;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Gagal memulai navigasi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── LOAD POLYLINE ────────────────────────────────────────
  Future<void> _loadPolyline(int idRute) async {
    _isMapLoading = true;
    notifyListeners();

    try {
      final titik = await _ruteService.getTitikRute(idRute);
      _titikPolyline = titik
          .map((t) => LatLng(t.latitude, t.longitude))
          .toList();
    } catch (_) {
    } finally {
      _isMapLoading = false;
      notifyListeners();
    }
  }

  // ─── RESET STATE ──────────────────────────────────────────
  void resetState() {
    _titikPolyline = [];
    _halteRute = [];
    _ruteTersedia = [];
    _adaPerjalananAktif = false;
    notifyListeners();
  }
}

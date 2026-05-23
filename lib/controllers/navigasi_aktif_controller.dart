import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:busguide/models/rute_service.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/rute.dart';
import 'package:busguide/models/halte.dart';

class NavigasiAktifController extends ChangeNotifier {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();

  bool _isLoading = true;
  bool _isAlmostThere = false;

  // Data Perjalanan
  Perjalanan? _perjalananAktif;
  List<LatLng> _titikPolyline = [];
  List<RuteHalte> _halteRute = [];
  Halte? _halteBerikutnya;

  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304);
  int _sisaMenitTiba = 0;
  StreamSubscription<Position>? _gpsStream;

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isAlmostThere => _isAlmostThere;
  Perjalanan? get perjalananAktif => _perjalananAktif;
  List<LatLng> get titikPolyline => _titikPolyline;
  List<RuteHalte> get halteRute => _halteRute;
  Halte? get halteBerikutnya => _halteBerikutnya;
  LatLng get lokasiSaatIni => _lokasiSaatIni;
  int get sisaMenitTiba => _sisaMenitTiba;

  // ─── LOAD DATA AKTIF ──────────────────────────────────────
  Future<void> loadDataAktif() async {
    try {
      final aktif = await _perjalananService.getPerjalananAktif();
      if (aktif == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _perjalananAktif = aktif;

      // Load jalur polyline & halte dari rute
      final idRute = aktif.rute?.id;
      if (idRute != null) {
        final titik = await _ruteService.getTitikRute(idRute);
        _titikPolyline =
            titik.map((t) => LatLng(t.latitude, t.longitude)).toList();
        _halteRute = await _halteService.getHalteByRute(idRute);
      }

      if (_titikPolyline.isNotEmpty) {
        _lokasiSaatIni = _titikPolyline.first;
      }

      mulaiLacakGps();
    } catch (e) {
      debugPrint('Error load aktif: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── GPS STREAM ───────────────────────────────────────────
  void mulaiLacakGps() {
    _gpsStream?.cancel();
    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);

      // Kalkulasi jarak ke tujuan (kecepatan asumsi 25km/jam = 416 m/menit)
      final halteTujuan = _perjalananAktif?.halteTujuan;
      if (halteTujuan != null) {
        final jarak = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          halteTujuan.latitude,
          halteTujuan.longitude,
        );

        _sisaMenitTiba = (jarak / 416).ceil();
        if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;

        if (jarak < 500 && !_isAlmostThere) {
          _isAlmostThere = true;
        }
      }

      _updateHalteBerikutnya(pos);
      notifyListeners();
    }, onError: (e) {
      debugPrint('GPS Stream error: $e');
    });
  }

  // ─── UPDATE HALTE BERIKUTNYA ──────────────────────────────
  void _updateHalteBerikutnya(Position pos) {
    if (_halteRute.isEmpty) return;
    double jarakTerdekat = double.infinity;
    Halte? halteTerdekat;

    for (var rh in _halteRute) {
      final jarak = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        rh.halte.latitude,
        rh.halte.longitude,
      );
      if (jarak > 50 && jarak < jarakTerdekat) {
        jarakTerdekat = jarak;
        halteTerdekat = rh.halte;
      }
    }

    if (halteTerdekat != null &&
        halteTerdekat.nama != _halteBerikutnya?.nama) {
      _halteBerikutnya = halteTerdekat;
    }
  }

  // ─── SELESAIKAN PERJALANAN ────────────────────────────────
  /// Mengembalikan true jika berhasil
  Future<bool> selesaikanPerjalanan() async {
    if (_perjalananAktif == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final startTime = _perjalananAktif!.waktuMulai;
      int durasiMenit = DateTime.now().difference(startTime).inMinutes;
      if (durasiMenit < 1) durasiMenit = 1;

      await _perjalananService.selesaikanPerjalanan(
        idPerjalanan: _perjalananAktif!.id,
        durasiMenit: durasiMenit,
      );
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── BATALKAN PERJALANAN ──────────────────────────────────
  /// Mengembalikan true jika berhasil
  Future<bool> batalkanPerjalanan() async {
    if (_perjalananAktif == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await _perjalananService.batalkanPerjalanan(_perjalananAktif!.id);
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── TOGGLE ALARM ─────────────────────────────────────────
  Future<void> toggleAlarm() async {
    if (_perjalananAktif == null) return;
    final isAlarmActive = _perjalananAktif!.alarmAktif;
    await _perjalananService.toggleAlarm(
      idPerjalanan: _perjalananAktif!.id,
      aktif: !isAlarmActive,
    );
    // Refresh data perjalanan aktif
    final aktif = await _perjalananService.getPerjalananAktif();
    _perjalananAktif = aktif;
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────
  @override
  void dispose() {
    _gpsStream?.cancel();
    super.dispose();
  }
}

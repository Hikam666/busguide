import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:busguide/models/osrm_routes_service.dart';
import 'package:busguide/models/rute_service.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/rute.dart';
import 'package:busguide/models/halte.dart';
import 'package:busguide/core/notification_service.dart';
import 'package:busguide/utils/polyline_utils.dart';
import 'package:busguide/utils/temp_cache.dart';

class NavigasiAktifController extends ChangeNotifier {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();
  final _osrmRoutesService = OsrmRoutesService();

  bool _isLoading = true;
  bool _isAlmostThere = false;
  bool _alarmTriggered = false;

  // Data Perjalanan
  Perjalanan? _perjalananAktif;
  List<LatLng> _titikPolyline = [];
  List<RuteHalte> _halteRute = [];
  Halte? _halteBerikutnya;

  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304);
  double _headingSaatIni = 0;
  int _sisaMenitTiba = 0;
  double _kecepatanMps = 6.94; // Default 25 km/jam (dalam m/s)
  
  StreamSubscription<Position>? _gpsStream;

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isAlmostThere => _isAlmostThere;
  Perjalanan? get perjalananAktif => _perjalananAktif;
  List<LatLng> get titikPolyline => _titikPolyline;
  List<RuteHalte> get halteRute => _halteRute;
  Halte? get halteBerikutnya => _halteBerikutnya;
  LatLng get lokasiSaatIni => _lokasiSaatIni;
  double get headingSaatIni => _headingSaatIni;
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

      final idRute = aktif.rute?.id;
      if (idRute != null && idRute > 0) {
        _halteRute = await _halteService.getHalteByRute(idRute);

        // ── Prioritas 1: titik_rute dari database Supabase ──
        final titikDB = await _ruteService.getTitikRute(idRute);
        if (titikDB.length >= 2) {
          final List<LatLng> rawPoints = titikDB.map((t) => LatLng(t.latitude, t.longitude)).toList();
          // Pangkas titik (Simplify) agar Map tidak berat me-render
          _titikPolyline = PolylineUtils.simplify(rawPoints, tolerance: 0.00015);
          debugPrint('Polyline dari DB (di-simplify): ${_titikPolyline.length} titik dari awal ${rawPoints.length} titik');
          
          // Tetap panggil OSRM hanya untuk dapat ETA Real-Time
          final waypoints = _halteRute.map((h) => LatLng(h.halte.latitude, h.halte.longitude)).toList();
          final routeData = await _osrmRoutesService.getRoute(waypoints);
          if (routeData != null) {
            _sisaMenitTiba = (routeData.durationSeconds / 60).round();
            if (routeData.durationSeconds > 0) {
              _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
            }
          }
        } else if (_halteRute.length >= 2) {
          // ── Prioritas 2: OSRM API ──
          debugPrint('titik_rute kosong, fallback ke OSRM API');
          final waypoints = _halteRute
              .map((h) => LatLng(h.halte.latitude, h.halte.longitude))
              .toList();
          final routeData = await _osrmRoutesService.getRoute(waypoints);
          if (routeData != null) {
            _titikPolyline = routeData.polyline;
            _sisaMenitTiba = (routeData.durationSeconds / 60).round();
            if (routeData.durationSeconds > 0) {
              _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
            }
            debugPrint('Polyline dari OSRM: ${_titikPolyline.length} titik');
          }
        }
      } else if (aktif.rute == null) {
        // Mode Bebas: Gunakan custom tujuan dari Cache jika di database null
        final customAtauDbTujuan = aktif.halteTujuan ?? TempCache.customTujuanNavigasi;
        
        if (customAtauDbTujuan != null) {
          final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
          _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);

          final waypoints = [
            _lokasiSaatIni,
            LatLng(customAtauDbTujuan.latitude, customAtauDbTujuan.longitude)
          ];
          
          final routeData = await _osrmRoutesService.getRoute(waypoints);
          if (routeData != null) {
            _titikPolyline = routeData.polyline;
            _sisaMenitTiba = (routeData.durationSeconds / 60).round();
            if (routeData.durationSeconds > 0) {
              _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
            }
            debugPrint('Polyline Bebas dari OSRM: ${_titikPolyline.length} titik');
          }
        }
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
      _headingSaatIni = pos.heading; // Menyimpan arah pergerakan (0-360)

      // Kalkulasi jarak ke tujuan dan ETA dinamis
      final halteTujuan = _perjalananAktif?.halteTujuan ?? TempCache.customTujuanNavigasi;
      if (halteTujuan != null) {
        final jarak = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          halteTujuan.latitude,
          halteTujuan.longitude,
        );

        _sisaMenitTiba = (jarak / _kecepatanMps / 60).ceil();
        if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;

        if (jarak < 500 && !_isAlmostThere) {
          _isAlmostThere = true;
          // Trigger Notifikasi Alarm jika aktif
          if (_perjalananAktif!.alarmAktif && !_alarmTriggered) {
            _alarmTriggered = true;
            NotificationService.showNotification(
              id: 1,
              title: 'Hampir Sampai!',
              body: 'Siap-siap, Anda sudah dekat dengan ${halteTujuan.nama}.',
            );
          }
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

    if (halteTerdekat != null && halteTerdekat.nama != _halteBerikutnya?.nama) {
      // Hanya update halte berikutnya di memori lokal
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
      // Clear local active trip state
      _perjalananAktif = null;
      _titikPolyline = [];
      _halteRute = [];
      _halteBerikutnya = null;
      _gpsStream?.cancel();
      _gpsStream = null;
      notifyListeners();
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
      // Clear local active trip state
      _perjalananAktif = null;
      _titikPolyline = [];
      _halteRute = [];
      _halteBerikutnya = null;
      _gpsStream?.cancel();
      _gpsStream = null;
      notifyListeners();
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
    
    if (!isAlarmActive) {
      // Jika akan mengaktifkan alarm, pastikan punya izin
      await NotificationService.requestPermission();
    }

    await _perjalananService.toggleAlarm(
      idPerjalanan: _perjalananAktif!.id,
      aktif: !isAlarmActive,
    );
    // Refresh data perjalanan aktif (gunakan copyWith agar custom route tidak hilang)
    _perjalananAktif = _perjalananAktif!.copyWith(alarmAktif: !isAlarmActive);
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────
  @override
  void dispose() {
    _gpsStream?.cancel();
    super.dispose();
  }
}

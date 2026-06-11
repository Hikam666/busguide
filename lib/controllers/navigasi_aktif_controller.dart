import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

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

  // Logika Pemotongan Rute & Rerouting
  List<LatLng> _originalRoutePolyline = [];
  List<LatLng> _busRoutePolyline = [];
  List<LatLng> _firstPartPolyline = [];
  List<LatLng> _secondPartPolyline = [];
  int _firstPartLength = 0;
  int _lastPassedRouteIndex = 0;
  bool _isRerouting = false;
  DateTime? _lastRerouteTime;

  bool _userBelumDiHalteAsal = false;
  int _estimasiBusTibaMenit = 8;
  DateTime? _nextBusDepartureTime;
  
  StreamSubscription<Position>? _gpsStream;

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isAlmostThere => _isAlmostThere;
  Perjalanan? get perjalananAktif => _perjalananAktif;
  List<LatLng> get titikPolyline => _titikPolyline;
  List<LatLng> get firstPartPolyline => _firstPartPolyline;
  List<LatLng> get secondPartPolyline => _secondPartPolyline;
  List<RuteHalte> get halteRute => _halteRute;
  Halte? get halteBerikutnya => _halteBerikutnya;
  LatLng get lokasiSaatIni => _lokasiSaatIni;
  double get headingSaatIni => _headingSaatIni;
  int get sisaMenitTiba => _sisaMenitTiba;
  bool get userBelumDiHalteAsal => _userBelumDiHalteAsal;
  
  int get estimasiBusTibaMenit {
    if (_nextBusDepartureTime == null) return _estimasiBusTibaMenit;
    final diff = _nextBusDepartureTime!.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 0;
  }
  
  String get estimasiBusTibaJam {
    if (_nextBusDepartureTime == null) {
      final dt = DateTime.now().add(Duration(minutes: _estimasiBusTibaMenit));
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m WIB';
    }
    final h = _nextBusDepartureTime!.hour.toString().padLeft(2, '0');
    final m = _nextBusDepartureTime!.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

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
      final startHalt = aktif.halteAsal;
      final destHalt = aktif.halteTujuan;
      
      if (idRute != null && idRute > 0) {
        final allHalteRute = await _halteService.getHalteByRute(idRute);
        if (startHalt != null && destHalt != null) {
          int indexAsal = allHalteRute.indexWhere((rh) => rh.halte.id == startHalt.id);
          int indexTujuan = allHalteRute.indexWhere((rh) => rh.halte.id == destHalt.id);
          if (indexAsal != -1 && indexTujuan != -1) {
            if (indexAsal <= indexTujuan) {
              _halteRute = allHalteRute.sublist(indexAsal, indexTujuan + 1);
            } else {
              _halteRute = allHalteRute.sublist(indexTujuan, indexAsal + 1).reversed.toList();
            }
          } else {
            _halteRute = allHalteRute;
          }
        } else {
          _halteRute = allHalteRute;
        }
      }

      // Dapatkan lokasi awal user dulu
      try {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}

      // Muat Polyline rute & user
      await _muatPolyline();

      // Hitung jadwal keberangkatan bus
      await _updateBusArrivalSchedule(idRute);

      // Kirim Notifikasi jika jauh dari halte awal (> 100 meter)
      if (startHalt != null) {
        final distToAsal = Geolocator.distanceBetween(
          _lokasiSaatIni.latitude,
          _lokasiSaatIni.longitude,
          startHalt.latitude,
          startHalt.longitude,
        );
        if (distToAsal > 100) {
          NotificationService.showNotification(
            id: 99,
            title: 'Lokasi Anda Jauh',
            body: 'Lokasi Anda jauh dari halte awal ${startHalt.nama}.',
          );
        }
      }

      mulaiLacakGps();
    } catch (e) {
      debugPrint('Error load aktif: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── MUAT POLYLINE JALUR ──────────────────────────────────
  Future<void> _muatPolyline() async {
    final startHalt = _perjalananAktif?.halteAsal;
    final destHalt = _perjalananAktif?.halteTujuan ?? TempCache.customTujuanNavigasi;
    final idRute = _perjalananAktif?.rute?.id;

    _userBelumDiHalteAsal = false;
    List<LatLng> firstPart = [];
    _firstPartLength = 0;

    if (startHalt != null && idRute != null && idRute > 0) {
      final distToAsal = Geolocator.distanceBetween(
        _lokasiSaatIni.latitude,
        _lokasiSaatIni.longitude,
        startHalt.latitude,
        startHalt.longitude,
      );
      if (distToAsal > 100) {
        _userBelumDiHalteAsal = true;
        // Dapatkan rute ke halte asal (firstPart) lewat jalan
        final routeToAsal = await _osrmRoutesService.getRoute([
          _lokasiSaatIni,
          LatLng(startHalt.latitude, startHalt.longitude),
        ]);
        if (routeToAsal != null) {
          firstPart = routeToAsal.polyline;
        } else {
          firstPart = [
            _lokasiSaatIni,
            LatLng(startHalt.latitude, startHalt.longitude),
          ];
        }
        _firstPartLength = firstPart.length;
        _sisaMenitTiba = (distToAsal / 1.4 / 60).ceil();
        if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;
      }
    }

    // 1. Dapatkan Jalur Bus
    List<LatLng> secondPart = [];
    if (idRute != null && idRute > 0 && startHalt != null && destHalt != null) {
      // Coba dapatkan rute dari database titik_rute terlebih dahulu
      final titikDB = await _ruteService.getTitikRute(idRute);
      if (titikDB.length >= 2) {
        final List<LatLng> rawPoints = titikDB.map((t) => LatLng(t.latitude, t.longitude)).toList();
        final List<LatLng> slicedDbPoints = _sliceRouteCoordinates(rawPoints, startHalt, destHalt);
        
        if (slicedDbPoints.length >= 2) {
          // Haluskan koordinat database mengikuti jalan menggunakan OSRM API
          final waypoints = _sampleWaypoints(slicedDbPoints, maxPoints: 25);
          final routeData = await _osrmRoutesService.getRoute(waypoints);
          if (routeData != null && routeData.polyline.isNotEmpty) {
            secondPart = routeData.polyline;
            if (!_userBelumDiHalteAsal) {
              _sisaMenitTiba = (routeData.durationSeconds / 60).round();
            }
            if (routeData.durationSeconds > 0) {
              _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
            }
          } else {
            secondPart = slicedDbPoints; // Fallback ke koordinat database mentah
          }
        }
      }

      // Fallback: OSRM API rute jalan biasa melewati semua halte rute jika database titik_rute kosong
      if (secondPart.isEmpty && _halteRute.length >= 2) {
        final waypoints = _halteRute
            .where((rh) => rh.halte.id != 0 && rh.halte.id != -1) // abaikan lokasi saat ini/custom jika ada
            .map((rh) => LatLng(rh.halte.latitude, rh.halte.longitude))
            .toList();
        
        if (waypoints.length >= 2) {
          final routeData = await _osrmRoutesService.getRoute(waypoints);
          if (routeData != null && routeData.polyline.isNotEmpty) {
            secondPart = routeData.polyline;
            if (!_userBelumDiHalteAsal) {
              _sisaMenitTiba = (routeData.durationSeconds / 60).round();
            }
            if (routeData.durationSeconds > 0) {
              _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
            }
          }
        }
      }
      _busRoutePolyline = List.from(secondPart);
    } else {
      _busRoutePolyline = [];
    }

    // Fallback prioritas 2: OSRM API rute jalan biasa
    if (secondPart.isEmpty && startHalt != null && destHalt != null) {
      final waypoints = [
        LatLng(startHalt.latitude, startHalt.longitude),
        LatLng(destHalt.latitude, destHalt.longitude)
      ];
      final routeData = await _osrmRoutesService.getRoute(waypoints);
      if (routeData != null) {
        secondPart = routeData.polyline;
        if (!_userBelumDiHalteAsal) {
          _sisaMenitTiba = (routeData.durationSeconds / 60).round();
        }
        if (routeData.durationSeconds > 0) {
          _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
        }
      } else {
        secondPart = [
          LatLng(startHalt.latitude, startHalt.longitude),
          LatLng(destHalt.latitude, destHalt.longitude)
        ];
      }
      _busRoutePolyline = List.from(secondPart);
    } else if (secondPart.isEmpty && destHalt != null) {
      // Navigasi Bebas
      final waypoints = [
        _lokasiSaatIni,
        LatLng(destHalt.latitude, destHalt.longitude)
      ];
      final routeData = await _osrmRoutesService.getRoute(waypoints);
      if (routeData != null) {
        secondPart = routeData.polyline;
        _sisaMenitTiba = (routeData.durationSeconds / 60).round();
        if (routeData.durationSeconds > 0) {
          _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
        }
      }
    }

    if (_userBelumDiHalteAsal) {
      _originalRoutePolyline = [...firstPart, ...secondPart];
    } else {
      _originalRoutePolyline = List.from(secondPart);
    }
    _lastPassedRouteIndex = 0;
    _sliceRouteFromCurrentLocation();
  }

  List<LatLng> _sliceRouteCoordinates(
      List<LatLng> titikDB, Halte asal, Halte tujuan) {
    int indexAsal = -1;
    int indexTujuan = -1;
    double minDistanceAsal = double.infinity;
    double minDistanceTujuan = double.infinity;

    for (int i = 0; i < titikDB.length; i++) {
      final pt = titikDB[i];

      final distAsal = Geolocator.distanceBetween(
        asal.latitude,
        asal.longitude,
        pt.latitude,
        pt.longitude,
      );
      if (distAsal < minDistanceAsal) {
        minDistanceAsal = distAsal;
        indexAsal = i;
      }

      final distTujuan = Geolocator.distanceBetween(
        tujuan.latitude,
        tujuan.longitude,
        pt.latitude,
        pt.longitude,
      );
      if (distTujuan < minDistanceTujuan) {
        minDistanceTujuan = distTujuan;
        indexTujuan = i;
      }
    }

    if (indexAsal != -1 && indexTujuan != -1) {
      if (indexAsal <= indexTujuan) {
        return titikDB.sublist(indexAsal, indexTujuan + 1);
      } else {
        return titikDB.sublist(indexTujuan, indexAsal + 1).reversed.toList();
      }
    }
    return PolylineUtils.simplify(titikDB, tolerance: 0.00015);
  }

  // ─── GPS STREAM ───────────────────────────────────────────
  void mulaiLacakGps() {
    _gpsStream?.cancel();

    // 1. Konfigurasi hardware GPS ke mode "Akurasi Terbaik / Navigasi"
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // 0 = Laporkan sekecil apapun pergerakan pengguna
        intervalDuration: const Duration(seconds: 1), // Refresh setiap detik
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    // 2. Berlangganan (Listen) ke pancaran sinyal satelit GPS
    _gpsStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      _lokasiSaatIni = LatLng(pos.latitude, pos.longitude);
      _headingSaatIni = pos.heading; // Menyimpan arah pergerakan (0-360)

      final startHalt = _perjalananAktif?.halteAsal;
      final destHalt = _perjalananAktif?.halteTujuan ?? TempCache.customTujuanNavigasi;
      final idRute = _perjalananAktif?.rute?.id;
      final isBebasOrMandiri = idRute == 0 || _perjalananAktif?.id == -999;

      // 3. Potong garis (polyline) yang sudah terlewati di belakang mobil agar peta bersih
      final distanceToRoute = _sliceRouteFromCurrentLocation();

      // 4. AUTO REROUTING: Jika jarak menyimpang > 50 meter, panggil OSRM bikin rute baru
      if (_originalRoutePolyline.isNotEmpty && distanceToRoute > 50.0) {
        if (_userBelumDiHalteAsal && startHalt != null) {
          recalculateRoute(target: LatLng(startHalt.latitude, startHalt.longitude));
        } else if (isBebasOrMandiri && destHalt != null) {
          recalculateRoute(target: LatLng(destHalt.latitude, destHalt.longitude));
        }
      }

      if (startHalt != null && _userBelumDiHalteAsal) {
        final distToAsal = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          startHalt.latitude,
          startHalt.longitude,
        );

        if (distToAsal <= 100) {
          // Tiba di halte asal! Matikan rute jalan kaki hijau, transisi murni ke jalur bus biru.
          _userBelumDiHalteAsal = false;
          _isLoading = true;
          notifyListeners();
          
          await _muatPolyline();
          
          _isLoading = false;
          notifyListeners();
        } else {
          // Estimasi waktu jalan kaki
          _sisaMenitTiba = (distToAsal / 1.4 / 60).ceil();
          if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;

          // Kurangi estimasi bus secara dinamis agar realistis
          if (_estimasiBusTibaMenit > 1 && DateTime.now().second % 15 == 0) {
            _estimasiBusTibaMenit--;
          }
        }
      } else if (destHalt != null) {
        final jarak = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          destHalt.latitude,
          destHalt.longitude,
        );

        _sisaMenitTiba = (jarak / _kecepatanMps / 60).ceil();
        if (_sisaMenitTiba < 1) _sisaMenitTiba = 1;

        // 5. LOGIKA ALARM HAMPIR SAMPAI
        if (jarak < 500 && !_isAlmostThere) {
          _isAlmostThere = true;
          // Trigger Notifikasi Bawaan HP (Ring/Vibrate) jika switch alarm menyala
          if (_perjalananAktif!.alarmAktif && !_alarmTriggered) {
            _alarmTriggered = true;
            NotificationService.showNotification(
              id: 1,
              title: 'Hampir Sampai!',
              body: 'Siap-siap, Anda sudah dekat dengan ${destHalt.nama}.',
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

  // ─── ALGORITMA SNAP-TO-ROAD & PENGHAPUSAN GARIS BELAKANG ───
  double _sliceRouteFromCurrentLocation() {
    if (_originalRoutePolyline.isEmpty) {
      _firstPartPolyline = [];
      _secondPartPolyline = [];
      _titikPolyline = [];
      return 0.0;
    }

    int closestIndex = _lastPassedRouteIndex;
    double minDistance = double.infinity;

    // Looping koordinat garis biru dari titik terakhir yang dilewati sampai ujung
    for (int i = _lastPassedRouteIndex; i < _originalRoutePolyline.length; i++) {
      final dist = Geolocator.distanceBetween(
        _lokasiSaatIni.latitude,
        _lokasiSaatIni.longitude,
        _originalRoutePolyline[i].latitude,
        _originalRoutePolyline[i].longitude,
      );
      // Mencari indeks array garis yang meternya paling dekat dengan ban mobil/GPS saat ini
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // Simpan titik terdekat tersebut di memori
    _lastPassedRouteIndex = closestIndex;

    if (closestIndex != -1 && closestIndex < _originalRoutePolyline.length) {
      // Potong array (Sublist): Buang array di belakang closestIndex.
      final remaining = _originalRoutePolyline.sublist(closestIndex);
      _titikPolyline = [_lokasiSaatIni, ...remaining];

      if (_userBelumDiHalteAsal) {
        if (closestIndex < _firstPartLength) {
          // Pengguna masih berada pada jalur hijau (menuju halte asal)
          _firstPartPolyline = [_lokasiSaatIni, ..._originalRoutePolyline.sublist(closestIndex, _firstPartLength)];
          _secondPartPolyline = _originalRoutePolyline.sublist(_firstPartLength);
        } else {
          // Pengguna telah memasuki jalur bus (telah melewati halte asal)
          _userBelumDiHalteAsal = false;
          _firstPartPolyline = [];
          _secondPartPolyline = [_lokasiSaatIni, ...remaining];
        }
      } else {
        _firstPartPolyline = [];
        _secondPartPolyline = [_lokasiSaatIni, ...remaining];
      }
    } else {
      _titikPolyline = [_lokasiSaatIni, ..._originalRoutePolyline];
      if (_userBelumDiHalteAsal) {
        _firstPartPolyline = [_lokasiSaatIni, ..._originalRoutePolyline.sublist(0, _firstPartLength)];
        _secondPartPolyline = _originalRoutePolyline.sublist(_firstPartLength);
      } else {
        _firstPartPolyline = [];
        _secondPartPolyline = [_lokasiSaatIni, ..._originalRoutePolyline];
      }
    }

    return minDistance;
  }

  // ─── RECALCULATE ROUTE (REROUTING) ────────────────────────
  Future<void> recalculateRoute({required LatLng target}) async {
    if (_isRerouting) return;
    final now = DateTime.now();
    if (_lastRerouteTime != null && now.difference(_lastRerouteTime!).inSeconds < 10) {
      return; // Cooldown 10 detik agar tidak spam OSRM API
    }

    _isRerouting = true;
    _lastRerouteTime = now;

    try {
      final waypoints = [
        _lokasiSaatIni,
        target,
      ];
      final routeData = await _osrmRoutesService.getRoute(waypoints);
      if (routeData != null && routeData.polyline.isNotEmpty) {
        if (_userBelumDiHalteAsal) {
          _originalRoutePolyline = [...routeData.polyline, ..._busRoutePolyline];
          _firstPartLength = routeData.polyline.length;
        } else {
          _originalRoutePolyline = routeData.polyline;
          _firstPartLength = 0;
        }
        _lastPassedRouteIndex = 0;
        
        _sliceRouteFromCurrentLocation();

        _sisaMenitTiba = (routeData.durationSeconds / 60).round();
        if (routeData.durationSeconds > 0) {
          _kecepatanMps = routeData.distanceMeters / routeData.durationSeconds;
        }
        notifyListeners();
        debugPrint("Successfully rerouted to target: ${target.latitude}, ${target.longitude}");
      }
    } catch (e) {
      debugPrint("Error during rerouting: $e");
    } finally {
      _isRerouting = false;
    }
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

  // ─── UPDATE JADWAL BUS DARI DATABASE ────────────────────────
  Future<void> _updateBusArrivalSchedule(int? idRute) async {
    final now = DateTime.now();
    DateTime? closestDeparture;
    
    if (idRute != null && idRute > 0) {
      // 1. Fetch departures from database
      final schedules = await _ruteService.getJadwalRute(idRute);
      
      if (schedules.isNotEmpty) {
        final weekdayNamesEn = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final weekdayNamesId = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        final todayEn = weekdayNamesEn[now.weekday].toLowerCase();
        final todayId = weekdayNamesId[now.weekday].toLowerCase();
        
        int minDiffMinutes = 999999;
        
        for (final schedule in schedules) {
          final hariField = schedule['hari'];
          List<String> listHari = [];
          if (hariField is List) {
            listHari = hariField.map((e) => e.toString().toLowerCase()).toList();
          } else if (hariField is String) {
            listHari = [hariField.toLowerCase()];
          }
          
          if (listHari.isNotEmpty) {
            final isMatch = listHari.any((h) => 
              h == 'setiap hari' || 
              h == 'daily' || 
              h == todayEn || 
              h == todayId
            );
            if (!isMatch) continue;
          }
          
          final jamBerangkat = schedule['jam_berangkat']?.toString();
          if (jamBerangkat == null || !jamBerangkat.contains(':')) continue;
          
          final parts = jamBerangkat.split(':');
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;
          
          final depTimeToday = DateTime(now.year, now.month, now.day, hour, minute);
          int diff = depTimeToday.difference(now).inMinutes;
          
          if (diff > 0 && diff < minDiffMinutes) {
            minDiffMinutes = diff;
            closestDeparture = depTimeToday;
          } else if (diff <= 0) {
            final depTimeTomorrow = depTimeToday.add(const Duration(days: 1));
            int diffTom = depTimeTomorrow.difference(now).inMinutes;
            if (diffTom > 0 && diffTom < minDiffMinutes) {
              minDiffMinutes = diffTom;
              closestDeparture = depTimeTomorrow;
            }
          }
        }
      }
    }
    
    // 2. Fallback jika tidak ada data dari database (jadwal kosong atau navigasi bebas)
    if (closestDeparture == null) {
      final currentMinute = now.minute;
      final int interval = 30;
      final nextBusMinute = ((currentMinute ~/ interval) + 1) * interval;
      closestDeparture = DateTime(now.year, now.month, now.day, now.hour).add(Duration(minutes: nextBusMinute));
    }
    
    _nextBusDepartureTime = closestDeparture;
    _estimasiBusTibaMenit = _nextBusDepartureTime!.difference(now).inMinutes;
    if (_estimasiBusTibaMenit < 1) _estimasiBusTibaMenit = 1;
    
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────
  @override
  void dispose() {
    _gpsStream?.cancel();
    super.dispose();
  }

  List<LatLng> _sampleWaypoints(List<LatLng> points, {int maxPoints = 25}) {
    if (points.length <= maxPoints) return points;
    final List<LatLng> sampled = [];
    sampled.add(points.first);
    
    final double step = (points.length - 1) / (maxPoints - 1);
    for (int i = 1; i < maxPoints - 1; i++) {
      final int index = (i * step).round();
      sampled.add(points[index]);
    }
    
    sampled.add(points.last);
    return sampled;
  }
}

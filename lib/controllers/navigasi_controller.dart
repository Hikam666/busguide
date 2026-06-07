import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/rute_service.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/osrm_routes_service.dart';

import 'package:busguide/models/halte.dart';
import 'package:busguide/models/rute.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/utils/polyline_utils.dart';
import 'package:busguide/utils/temp_cache.dart';

class NavigasiController extends ChangeNotifier {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();
  final _osrmRoutesService = OsrmRoutesService();

  bool _isLoading = false;
  bool _isMapLoading = false;
  bool _adaPerjalananAktif = false;

  // Data Search
  List<Halte> _semuaHalte = [];
  Halte? _halteAsal;
  Halte? _halteTujuan;
  bool _alarmAktif = true;
  List<Rute> _ruteTersedia = [];
  Map<int, List<Map<String, dynamic>>> _jadwalRuteMap = {};

  // Data Peta & GPS
  LatLng _lokasiSaatIni = const LatLng(-7.9797, 112.6304); // Default Malang
  List<LatLng> _titikPolyline = [];
  List<RuteHalte> _halteRute = [];

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isMapLoading => _isMapLoading;
  bool get adaPerjalananAktif => _adaPerjalananAktif;
  
  List<Halte> get semuaHalte {
    // Sisipkan Lokasi Saat Ini di indeks 0
    return [
      Halte.lokasiSaatIni(_lokasiSaatIni.latitude, _lokasiSaatIni.longitude),
      ..._semuaHalte,
    ];
  }
  
  Halte? get halteAsal => _halteAsal;
  Halte? get halteTujuan => _halteTujuan;
  bool get alarmAktif => _alarmAktif;
  List<Rute> get ruteTersedia => _ruteTersedia;
  Map<int, List<Map<String, dynamic>>> get jadwalRuteMap => _jadwalRuteMap;
  LatLng get lokasiSaatIni => _lokasiSaatIni;
  List<LatLng> get titikPolyline => _titikPolyline;
  List<RuteHalte> get halteRute => _halteRute;

  // ─── INIT DATA ────────────────────────────────────────────
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final halte = await _halteService.getSemuaHalte();
      _semuaHalte = halte;

      final aktif = await _perjalananService.getPerjalananAktif();
      if (aktif != null) {
        _adaPerjalananAktif = true;
        notifyListeners();
        return;
      }

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

  Halte _cariHalteTerdekat() {
    if (_semuaHalte.isEmpty) return Halte.lokasiSaatIni(_lokasiSaatIni.latitude, _lokasiSaatIni.longitude);
    const dist = Distance();
    return _semuaHalte.reduce((a, b) {
      final dA = dist.as(LengthUnit.Meter, _lokasiSaatIni, LatLng(a.latitude, a.longitude));
      final dB = dist.as(LengthUnit.Meter, _lokasiSaatIni, LatLng(b.latitude, b.longitude));
      return dA < dB ? a : b;
    });
  }

  // ─── CARI RUTE ────────────────────────────────────────────
  Future<String?> cariRute() async {
    if (_halteAsal == null || _halteTujuan == null) {
      return 'Pilih lokasi asal dan tujuan terlebih dahulu';
    }
    if (_halteTujuan!.id == 0) {
      return 'Tujuan tidak boleh Lokasi Saat Ini';
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_halteAsal!.id == 0) {
        // Mode Lokasi Saat Ini -> Halte
        final nearestHalte = _cariHalteTerdekat();
        
        if (nearestHalte.id == _halteTujuan!.id) {
          // Hanya menuju halte terdekat (tidak naik bus)
          _ruteTersedia = [
            const Rute(id: 0, kode: 'LOKAL', nama: 'Menuju Halte')
          ];
          _halteRute = [
            RuteHalte(urutan: 1, halte: _halteAsal!),
            RuteHalte(urutan: 2, halte: _halteTujuan!),
          ];
          await _loadPolyline(0);
        } else {
          // Menuju halte terdekat lalu naik bus
          final rute = await _ruteService.cariRute(
            idHalteAsal: nearestHalte.id,
            idHalteTujuan: _halteTujuan!.id,
          );
          _ruteTersedia = rute;
          if (rute.isEmpty) {
            _ruteTersedia = [
              const Rute(id: 0, kode: 'BEBAS', nama: 'Navigasi Bebas (Peta)')
            ];
            _halteRute = [
              RuteHalte(urutan: 1, halte: _halteAsal!),
              RuteHalte(urutan: 2, halte: _halteTujuan!),
            ];
            await _loadPolyline(0);
          } else {
            final realHalteRute = await _halteService.getHalteByRute(rute.first.id);
            int indexAsal = realHalteRute.indexWhere((rh) => rh.halte.id == nearestHalte.id);
            int indexTujuan = realHalteRute.indexWhere((rh) => rh.halte.id == _halteTujuan!.id);
            List<RuteHalte> sliced = [];
            if (indexAsal != -1 && indexTujuan != -1) {
              if (indexAsal <= indexTujuan) {
                sliced = realHalteRute.sublist(indexAsal, indexTujuan + 1);
              } else {
                sliced = realHalteRute.sublist(indexTujuan, indexAsal + 1).reversed.toList();
              }
            } else {
              sliced = realHalteRute;
            }
            _halteRute = [
              RuteHalte(urutan: 0, halte: _halteAsal!),
              ...sliced,
            ];
            await _loadPolyline(rute.first.id);
          }
        }
      } else {
        // Mode normal: Halte -> Halte
        final rute = await _ruteService.cariRute(
          idHalteAsal: _halteAsal!.id,
          idHalteTujuan: _halteTujuan!.id,
        );
        _ruteTersedia = rute;

        if (rute.isEmpty) {
            _ruteTersedia = [
              const Rute(id: 0, kode: 'BEBAS', nama: 'Navigasi Bebas (Peta)')
            ];
            _halteRute = [
              RuteHalte(urutan: 1, halte: _halteAsal!),
              RuteHalte(urutan: 2, halte: _halteTujuan!),
            ];
            await _loadPolyline(0);
        } else {
          final realHalteRute = await _halteService.getHalteByRute(rute.first.id);
          int indexAsal = realHalteRute.indexWhere((rh) => rh.halte.id == _halteAsal!.id);
          int indexTujuan = realHalteRute.indexWhere((rh) => rh.halte.id == _halteTujuan!.id);
          if (indexAsal != -1 && indexTujuan != -1) {
            if (indexAsal <= indexTujuan) {
              _halteRute = realHalteRute.sublist(indexAsal, indexTujuan + 1);
            } else {
              _halteRute = realHalteRute.sublist(indexTujuan, indexAsal + 1).reversed.toList();
            }
          } else {
            _halteRute = realHalteRute;
          }
          await _loadPolyline(rute.first.id);
        }
      }

      // FETCH JADWAL FOR ALL RUTES IN _ruteTersedia
      _jadwalRuteMap.clear();
      for (final r in _ruteTersedia) {
        if (r.id > 0) {
          final listJadwal = await _ruteService.getJadwalRute(r.id);
          if (listJadwal.isEmpty) {
            _jadwalRuteMap[r.id] = _generateMockSchedules(r.id);
          } else {
            _jadwalRuteMap[r.id] = listJadwal;
          }
        } else {
          _jadwalRuteMap[r.id] = _generateMockSchedules(r.id);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error cari rute: $e');
      return 'Gagal mencari rute. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _generateMockSchedules(int idRute) {
    final List<String> times = [
      '07:00', '08:30', '10:00', '11:30', '13:00',
      '14:30', '16:00', '17:30', '19:00', '20:30'
    ];
    final isEkonomi = idRute % 2 == 1;
    final tarif = isEkonomi ? 10000 : 15000;
    
    return times.map((t) => {
      'id': 99999 + times.indexOf(t),
      'id_rute': idRute,
      'id_bus': 1,
      'hari': 'Setiap Hari',
      'jam_berangkat': t,
      'tarif': tarif,
    }).toList();
  }

  // ─── MULAI NAVIGASI ───────────────────────────────────────
  Future<String?> mulaiNavigasi(Rute rute, {bool writeToDb = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cari halte asal sebenarnya jika dari Lokasi Saat Ini (id=0), null-kan agar dicatat sbg GPS
      final idAsalReal = _halteAsal!.id == 0 ? null : _halteAsal!.id;

      if (rute.id == 0) {
        // Jika titik custom (-1), kita cache sementara karena di database bakal null
        if (_halteTujuan!.id == -1) {
          TempCache.customTujuanNavigasi = _halteTujuan;
        } else {
          TempCache.customTujuanNavigasi = null;
        }

        // Perjalanan lokal / Menuju Halte
        final Perjalanan perjalanan;
        if (!writeToDb) {
          perjalanan = Perjalanan(
            id: -999,
            status: 'aktif',
            waktuMulai: DateTime.now(),
            alarmAktif: _alarmAktif,
            rute: rute,
            halteAsal: _halteAsal!.id == 0 ? null : _halteAsal,
            halteTujuan: _halteTujuan,
          );
          TempCache.inMemoryPerjalanan = perjalanan;
        } else {
          perjalanan = await _perjalananService.mulaiPerjalanan(
            idRute: null,
            idHalteAsal: idAsalReal,
            idHalteTujuan: _halteTujuan!.id,
          );
        }

        if (!_alarmAktif && writeToDb) {
          await _perjalananService.toggleAlarm(
            idPerjalanan: perjalanan.id,
            aktif: false,
          );
        }

        _halteRute = [
          RuteHalte(urutan: 1, halte: _halteAsal!),
          RuteHalte(urutan: 2, halte: _halteTujuan!),
        ];
        await _loadPolyline(0);
        _adaPerjalananAktif = true;
        notifyListeners();
        return null;
      }

      // Perjalanan Bus Normal
      final Perjalanan perjalanan;
      if (!writeToDb) {
        perjalanan = Perjalanan(
          id: -999,
          status: 'aktif',
          waktuMulai: DateTime.now(),
          alarmAktif: _alarmAktif,
          rute: rute,
          halteAsal: _halteAsal!.id == 0 ? null : _halteAsal,
          halteTujuan: _halteTujuan,
        );
        TempCache.inMemoryPerjalanan = perjalanan;
      } else {
        perjalanan = await _perjalananService.mulaiPerjalanan(
          idRute: rute.id,
          idHalteAsal: idAsalReal,
          idHalteTujuan: _halteTujuan!.id,
        );
      }

      if (!_alarmAktif && writeToDb) {
        await _perjalananService.toggleAlarm(
          idPerjalanan: perjalanan.id,
          aktif: false,
        );
      }

      final realHalteRute = await _halteService.getHalteByRute(rute.id);
      final startHalt = _halteAsal!.id == 0 ? _cariHalteTerdekat() : _halteAsal!;
      int indexAsal = realHalteRute.indexWhere((rh) => rh.halte.id == startHalt.id);
      int indexTujuan = realHalteRute.indexWhere((rh) => rh.halte.id == _halteTujuan!.id);
      List<RuteHalte> sliced = [];
      if (indexAsal != -1 && indexTujuan != -1) {
        if (indexAsal <= indexTujuan) {
          sliced = realHalteRute.sublist(indexAsal, indexTujuan + 1);
        } else {
          sliced = realHalteRute.sublist(indexTujuan, indexAsal + 1).reversed.toList();
        }
      } else {
        sliced = realHalteRute;
      }

      if (_halteAsal!.id == 0) {
        _halteRute = [
          RuteHalte(urutan: 0, halte: _halteAsal!),
          ...sliced,
        ];
      } else {
        _halteRute = sliced;
      }
      
      await _loadPolyline(rute.id);
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
      // 1. Dapatkan bagian 1: dari GPS ke _halteAsal (jika jarak > 100m dan _halteAsal bukan Lokasi Saat Ini)
      List<LatLng> firstPart = [];
      bool needsFirstPart = false;

      if (_halteAsal != null && _halteAsal!.id != 0) {
        final distToAsal = Geolocator.distanceBetween(
          _lokasiSaatIni.latitude,
          _lokasiSaatIni.longitude,
          _halteAsal!.latitude,
          _halteAsal!.longitude,
        );
        if (distToAsal > 100) {
          needsFirstPart = true;
          final routeToAsal = await _osrmRoutesService.getRoute([
            _lokasiSaatIni,
            LatLng(_halteAsal!.latitude, _halteAsal!.longitude),
          ]);
          if (routeToAsal != null) {
            firstPart = routeToAsal.polyline;
          } else {
            firstPart = [
              _lokasiSaatIni,
              LatLng(_halteAsal!.latitude, _halteAsal!.longitude)
            ];
          }
        }
      }

      // 2. Dapatkan bagian 2: dari _halteAsal ke _halteTujuan (Jalur Bus)
      List<LatLng> secondPart = [];
      if (idRute > 0) {
        // Coba dapatkan rute OSRM melewati semua halte rute terlebih dahulu agar mengikuti jalan
        if (_halteRute.length >= 2) {
          final waypoints = _halteRute
              .where((rh) => rh.halte.id != 0 && rh.halte.id != -1) // abaikan lokasi saat ini/custom jika ada
              .map((rh) => LatLng(rh.halte.latitude, rh.halte.longitude))
              .toList();
          
          if (waypoints.length >= 2) {
            final routeData = await _osrmRoutesService.getRoute(waypoints);
            if (routeData != null && routeData.polyline.isNotEmpty) {
              secondPart = routeData.polyline;
            }
          }
        }

        // Fallback: Database koordinat titik_rute dari database Supabase jika OSRM gagal
        if (secondPart.isEmpty) {
          final titikDB = await _ruteService.getTitikRute(idRute);
          if (titikDB.length >= 2) {
            final List<LatLng> rawPoints =
                titikDB.map((t) => LatLng(t.latitude, t.longitude)).toList();
            if (_halteAsal != null && _halteTujuan != null && _halteAsal!.id != 0) {
              secondPart = _sliceRouteCoordinates(rawPoints, _halteAsal!, _halteTujuan!);
            } else {
              secondPart = PolylineUtils.simplify(rawPoints, tolerance: 0.00015);
            }
          }
        }
      }

      // ── Prioritas 2: OSRM API ──
      if (secondPart.isEmpty && _halteAsal != null && _halteTujuan != null) {
        final originPoint = _halteAsal!.id == 0 ? _lokasiSaatIni : LatLng(_halteAsal!.latitude, _halteAsal!.longitude);
        final waypoints = [
          originPoint,
          LatLng(_halteTujuan!.latitude, _halteTujuan!.longitude),
        ];
        final routeData = await _osrmRoutesService.getRoute(waypoints);
        if (routeData != null) {
          secondPart = routeData.polyline;
        } else {
          secondPart = [
            originPoint,
            LatLng(_halteTujuan!.latitude, _halteTujuan!.longitude)
          ];
        }
      }

      // 3. Gabungkan bagian
      if (needsFirstPart) {
        _titikPolyline = [...firstPart, ...secondPart];
      } else {
        _titikPolyline = secondPart;
      }
    } catch (e) {
      debugPrint('loadPolyline error: $e');
    } finally {
      _isMapLoading = false;
      notifyListeners();
    }
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

  // ─── RESET STATE ──────────────────────────────────────────
  void resetState() {
    _titikPolyline = [];
    _halteRute = [];
    _ruteTersedia = [];
    _jadwalRuteMap = {};
    _adaPerjalananAktif = false;
    notifyListeners();
  }
}

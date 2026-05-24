import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/rute_service.dart';
import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/osrm_service.dart';
import 'package:busguide/models/halte.dart';
import 'package:busguide/models/rute.dart';
import 'package:busguide/models/perjalanan.dart';

class NavigasiController extends ChangeNotifier {
  final _ruteService = RuteService();
  final _perjalananService = PerjalananService();
  final _halteService = HalteService();
  final _osrmService = OsrmService();

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
          return null;
        } else {
          // Menuju halte terdekat lalu naik bus
          final rute = await _ruteService.cariRute(
            idHalteAsal: nearestHalte.id,
            idHalteTujuan: _halteTujuan!.id,
          );
          _ruteTersedia = rute;
          
          if (rute.isEmpty) return 'Tidak ada rute dari lokasi Anda ke tujuan tersebut.';

          final realHalteRute = await _halteService.getHalteByRute(rute.first.id);
          _halteRute = [
            RuteHalte(urutan: 0, halte: _halteAsal!),
            ...realHalteRute,
          ];
          await _loadPolyline(rute.first.id);
          return null;
        }
      } else {
        // Mode normal: Halte -> Halte
        final rute = await _ruteService.cariRute(
          idHalteAsal: _halteAsal!.id,
          idHalteTujuan: _halteTujuan!.id,
        );
        _ruteTersedia = rute;

        if (rute.isEmpty) return 'Tidak ada rute yang menghubungkan kedua halte ini.';

        _halteRute = await _halteService.getHalteByRute(rute.first.id);
        await _loadPolyline(rute.first.id);
        return null;
      }
    } catch (e) {
      debugPrint('Error cari rute: $e');
      return 'Gagal mencari rute. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── MULAI NAVIGASI ───────────────────────────────────────
  Future<String?> mulaiNavigasi(Rute rute) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (rute.id == 0) {
        // Perjalanan lokal / Menuju Halte (jangan simpan di DB)
        _halteRute = [
          RuteHalte(urutan: 1, halte: _halteAsal!),
          RuteHalte(urutan: 2, halte: _halteTujuan!),
        ];
        await _loadPolyline(0);
        // Buat mock Perjalanan Aktif
        final mockPerjalanan = Perjalanan(
          id: -1,
          status: 'aktif',
          waktuMulai: DateTime.now(),
          alarmAktif: _alarmAktif,
          rute: rute,
          halteAsal: _halteAsal,
          halteTujuan: _halteTujuan,
        );
        // Set ke NavigasiAktifController atau via UI
        // Karena ini local mock, tandai state bahwa ada perjalanan aktif virtual
        _adaPerjalananAktif = true;
        notifyListeners();
        return null;
      }

      // Perjalanan Bus Normal
      // Cari halte asal sebenarnya jika dari Lokasi Saat Ini
      final idAsalReal = _halteAsal!.id == 0 ? _cariHalteTerdekat().id : _halteAsal!.id;
      
      final perjalanan = await _perjalananService.mulaiPerjalanan(
        idRute: rute.id,
        idHalteAsal: idAsalReal,
        idHalteTujuan: _halteTujuan!.id,
      );

      if (!_alarmAktif) {
        await _perjalananService.toggleAlarm(
          idPerjalanan: perjalanan.id,
          aktif: false,
        );
      }

      final realHalteRute = await _halteService.getHalteByRute(rute.id);
      if (_halteAsal!.id == 0) {
        _halteRute = [
          RuteHalte(urutan: 0, halte: _halteAsal!),
          ...realHalteRute,
        ];
      } else {
        _halteRute = realHalteRute;
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
      if (_halteRute.length >= 2) {
        final waypoints = _halteRute
            .map((h) => LatLng(h.halte.latitude, h.halte.longitude))
            .toList();
        final routeData = await _osrmService.getRoute(waypoints);
        if (routeData != null) {
          _titikPolyline = routeData.polyline;
        }
      }
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

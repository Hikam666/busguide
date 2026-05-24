import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/halte.dart';

class HalteController extends ChangeNotifier {
  final _halteService = HalteService();

  List<Halte> _semuaHalte = [];
  List<Halte> _halteTerdekat = [];
  LatLng _titikPusat = const LatLng(-7.9797, 112.6304); // Default Malang
  String _labelLokasi = 'Mencari lokasi...';
  bool _pakaiGps = true;
  bool _isLoading = true;
  bool _isLoadingLokasi = false;
  String _errorMessage = '';

  // ─── GETTERS ─────────────────────────────────────────────
  List<Halte> get semuaHalte => _semuaHalte;
  List<Halte> get halteTerdekat => _halteTerdekat;
  LatLng get titikPusat => _titikPusat;
  String get labelLokasi => _labelLokasi;
  bool get pakaiGps => _pakaiGps;
  bool get isLoading => _isLoading;
  bool get isLoadingLokasi => _isLoadingLokasi;
  String get errorMessage => _errorMessage;

  // ─── MUAT DATA ────────────────────────────────────────────
  Future<void> muatData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final halte = await _halteService.getSemuaHalte();
      _semuaHalte = halte;
      _isLoading = false;
      notifyListeners();

      await dapatkanLokasi();
    } catch (_) {
      _errorMessage = 'Gagal memuat data halte. Periksa koneksi Anda.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── GET DETAIL ──────────────────────────────────────────
  Future<Halte?> getDetail(int id) async {
    try {
      return await _halteService.getDetailHalte(id);
    } catch (_) {
      return null;
    }
  }

  // ─── DAPATKAN LOKASI GPS ──────────────────────────────────
  Future<void> dapatkanLokasi() async {
    _isLoadingLokasi = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS mati');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin ditolak');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin ditolak permanen');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _titikPusat = LatLng(position.latitude, position.longitude);
      _labelLokasi = 'Lokasi Anda saat ini';
      _pakaiGps = true;
      notifyListeners();

      hitungHalteTerdekat();
    } catch (_) {
      _labelLokasi = 'Gagal mengambil GPS';
      _pakaiGps = false;
      notifyListeners();
    } finally {
      _isLoadingLokasi = false;
      notifyListeners();
    }
  }

  // ─── HITUNG HALTE TERDEKAT ────────────────────────────────
  void hitungHalteTerdekat() {
    if (_semuaHalte.isEmpty) return;

    final halteWithJarak = _semuaHalte.map((h) {
      final jarak = Geolocator.distanceBetween(
        _titikPusat.latitude,
        _titikPusat.longitude,
        h.latitude,
        h.longitude,
      );
      return h.withJarak(jarak);
    }).toList();

    halteWithJarak.sort(
      (a, b) => (a.jarakMeter ?? 0).compareTo(b.jarakMeter ?? 0),
    );

    _halteTerdekat = halteWithJarak.take(5).toList();
    notifyListeners();
  }

  // ─── CARI LOKASI (GEOCODING) ──────────────────────────────
  Future<void> cariLokasi(String query) async {
    if (query.trim().isEmpty) return;
    _isLoadingLokasi = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'BusGuideApp/1.0',
      });

      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) {
        _labelLokasi = 'Lokasi tidak ditemukan';
        notifyListeners();
        return;
      }

      final lat = double.parse(results[0]['lat']);
      final lon = double.parse(results[0]['lon']);
      final displayName = results[0]['display_name'] as String;

      _titikPusat = LatLng(lat, lon);
      _labelLokasi = displayName.split(',').take(2).join(',').trim();
      _pakaiGps = false;
      notifyListeners();

      hitungHalteTerdekat();
    } catch (_) {
      _labelLokasi = 'Gagal mencari lokasi';
      notifyListeners();
    } finally {
      _isLoadingLokasi = false;
      notifyListeners();
    }
  }

  // ─── FORMAT JARAK ─────────────────────────────────────────
  String formatJarak(double jarakMeter) {
    final meter = jarakMeter.round();
    if (meter < 1000) return '${meter}m';
    return '${(meter / 1000).toStringAsFixed(1)}km';
  }

  // ─── ESTIMASI WAKTU JALAN KAKI ────────────────────────────
  String estimasiWaktu(double jarakMeter) {
    final menit = (jarakMeter / 80).ceil(); // ±80 m/menit
    return '$menit Menit';
  }

  // ─── WARNA CHIP TIPE HALTE ────────────────────────────────
  Color warnaChip(String tipe) {
    switch (tipe.toLowerCase()) {
      case '1':
        return const Color(0xFF1A1A2E);
      case '3f':
        return const Color(0xFF2563EB);
      case '6m':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ─── PARSE TIPE HALTE MENJADI LIST ───────────────────────
  List<String> parseTipe(String? tipe) {
    if (tipe == null) return [];
    return tipe.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}

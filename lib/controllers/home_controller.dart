import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:busguide/models/perjalanan_service.dart';
import 'package:busguide/models/wisata_service.dart';
import 'package:busguide/models/halte_service.dart';
import 'package:busguide/models/perjalanan.dart';
import 'package:busguide/models/wisata.dart';
import 'package:busguide/models/halte.dart';

class HomeController extends ChangeNotifier {
  // Mengimpor service untuk berinteraksi dengan database
  final _perjalananService = PerjalananService();
  final _wisataService = WisataService();
  final _halteService = HalteService();

  // Variabel untuk menyimpan data yang akan ditampilkan di layar
  List<Perjalanan> _riwayatList = [];
  List<Wisata> _rekomendasiList = [];
  Perjalanan? _perjalananAktif;
  
  // Variabel status loading dan error
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchError = '';

  // ─── GETTERS ─────────────────────────────────────────────
  List<Perjalanan> get riwayatList => _riwayatList;
  List<Wisata> get rekomendasiList => _rekomendasiList;
  bool get isLoading => _isLoading;
  Perjalanan? get perjalananAktif => _perjalananAktif;
  bool get adaPerjalananAktif => _perjalananAktif != null;
  bool get isSearching => _isSearching;
  String get searchError => _searchError;

  // ─── LOAD DATA ────────────────────────────────────────────
  /// Memuat semua data awal yang dibutuhkan oleh layar Beranda
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // 1. Cek apakah pengguna memiliki perjalanan yang belum diselesaikan
    try {
      _perjalananAktif = await _perjalananService.getPerjalananAktif();
    } catch (e) {
      debugPrint('HomeController: Error loading active journey: $e');
    }

    // 2. Ambil riwayat perjalanan masa lalu untuk daftar "Riwayat Perjalanan"
    try {
      final riwayat = await _perjalananService.getRiwayatPerjalanan();
      _riwayatList = riwayat.take(2).toList(); // Tampilkan 2 riwayat terakhir
    } catch (e) {
      debugPrint('HomeController: Error loading trip history: $e');
    }

    // 3. Ambil daftar tempat wisata untuk daftar geser horizontal
    try {
      final wisata = await _wisataService.getSemuaWisata();
      _rekomendasiList = wisata.take(3).toList(); // Tampilkan 3 rekomendasi
    } catch (e) {
      debugPrint('HomeController: Error loading recommendations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── GEOCODE LOKASI (cari lokasi dari text) ──────────────
  /// Mengubah teks nama tempat (misal: "Gadang") menjadi koordinat Peta
  Future<LatLng?> _geocodeLokasi(String query) async {
    if (query.trim().isEmpty) return null;

    try {
      // Memanggil API Publik Nominatim (OpenStreetMap) secara gratis
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'BusGuideApp/1.0',
      });

      if (response.statusCode != 200) return null;

      // Mengambil data pertama dari hasil pencarian JSON
      final results = jsonDecode(response.body) as List;
      if (results.isEmpty) return null;

      final lat = double.parse(results[0]['lat']);
      final lon = double.parse(results[0]['lon']);
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  // ─── CARI HALTE TERDEKAT DARI LOKASI ──────────────────────
  /// Mencari 1 halte fisik terdekat dari sebuah titik koordinat acak
  Future<Halte?> _cariHalteTerdekat(LatLng lokasi) async {
    try {
      // Ambil daftar seluruh halte di kota Malang dari database
      final semuaHalte = await _halteService.getSemuaHalte();
      if (semuaHalte.isEmpty) return null;

      // Hitung jarak garis lurus (Haversine) dari titik acak tersebut ke setiap halte
      final halteWithJarak = semuaHalte.map((h) {
        final jarak = Geolocator.distanceBetween(
          lokasi.latitude,
          lokasi.longitude,
          h.latitude,
          h.longitude,
        );
        return h.withJarak(jarak);
      }).toList();

      // Urutkan list halte dari yang meternya terkecil (Terdekat) ke terjauh
      halteWithJarak.sort(
        (a, b) => (a.jarakMeter ?? 0).compareTo(b.jarakMeter ?? 0),
      );

      // Kembalikan urutan pertama (yang paling dekat)
      return halteWithJarak.isNotEmpty ? halteWithJarak.first : null;
    } catch (_) {
      return null;
    }
  }

  // ─── DAPATKAN LOKASI USER (GPS) ──────────────────────────
  /// Meminta sensor GPS HP untuk memberikan koordinat pengguna saat ini
  Future<LatLng?> _dapatkanLokasiUser() async {
    try {
      // Pengecekan hardware GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS mati');

      // Pengecekan software/Izin Aplikasi
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin ditolak');
        }
      }

      // Tembakkan request untuk mendapatkan titik saat ini
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  // ─── MULAI NAVIGASI DARI HOME ────────────────────────────
  /// Dijalankan saat user menekan 'Enter' setelah mengetik di search bar
  /// 1. Geocode destinasi
  /// 2. Cari halte terdekat ke destinasi (tujuan)
  /// 3. Cari halte terdekat ke GPS user (asal)
  /// 4. Return pair of (halteAsal, halteTujuan) atau error message
  Future<({Halte halteAsal, Halte halteTujuan})?> setupNavigasi(
    String destinasiQuery,
  ) async {
    _isSearching = true;
    _searchError = '';
    notifyListeners();

    try {
      // 1. Geocode: Cari tahu di mana letak persis tempat yang diketik pengguna
      final destinasiLatLng = await _geocodeLokasi(destinasiQuery);
      if (destinasiLatLng == null) {
        _searchError = 'Lokasi "$destinasiQuery" tidak ditemukan';
        _isSearching = false;
        notifyListeners();
        return null;
      }

      // 2. Halte Turun: Cari halte mana yang letaknya paling dekat dengan tempat tujuan tadi
      final halteTujuan = await _cariHalteTerdekat(destinasiLatLng);
      if (halteTujuan == null) {
        _searchError = 'Tidak ada halte ditemukan di dekat lokasi tersebut';
        _isSearching = false;
        notifyListeners();
        return null;
      }

      // 3. Halte Naik: Cari tahu lokasi pengguna, lalu cari halte yang paling dekat dengan pengguna
      final lokasiUser = await _dapatkanLokasiUser();
      if (lokasiUser == null) {
        _searchError = 'Tidak dapat mengakses lokasi Anda';
        _isSearching = false;
        notifyListeners();
        return null;
      }

      final halteAsal = await _cariHalteTerdekat(lokasiUser);
      if (halteAsal == null) {
        _searchError = 'Tidak ada halte ditemukan di dekat Anda';
        _isSearching = false;
        notifyListeners();
        return null;
      }

      _isSearching = false;
      notifyListeners();

      // Kembalikan pasangan Halte Naik dan Halte Turun ke UI untuk diteruskan ke Tab Navigasi
      return (halteAsal: halteAsal, halteTujuan: halteTujuan);
    } catch (e) {
      _searchError = 'Terjadi kesalahan: ${e.toString()}';
      _isSearching = false;
      notifyListeners();
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import '../models/perjalanan_service.dart';
import '../models/perjalanan.dart';
import 'package:geolocator/geolocator.dart';

class PerjalananController extends ChangeNotifier {
  final _service = PerjalananService();
  Perjalanan? _perjalananAktif;

  Perjalanan? get perjalananAktif => _perjalananAktif;

  Future<void> mulaiPerjalanan(int idRute, int idHalteAsal, int idHalteTujuan) async {
    _perjalananAktif = await _service.mulaiPerjalanan(
      idRute: idRute,
      idHalteAsal: idHalteAsal,
      idHalteTujuan: idHalteTujuan,
    );
    notifyListeners();
  }

  Future<void> akhiriPerjalanan([int durasiMenit = 0]) async {
    if (_perjalananAktif == null) return;
    await _service.selesaikanPerjalanan(
      idPerjalanan: _perjalananAktif!.id,
      durasiMenit: durasiMenit,
    );
    _hentikanPelacakan();
    _simpanStatusSelesai();
    _perjalananAktif = null;
    notifyListeners();
  }

  Future<void> batalkan() async {
    if (_perjalananAktif == null) return;
    await _service.batalkanPerjalanan(_perjalananAktif!.id);
    _hentikanPelacakan();
    _perjalananAktif = null;
    notifyListeners();
  }

  void aktifkanAlarmTidur() {
    if (_perjalananAktif == null) return;
    // Logika menyalakan alarm / background service
  }

  void _hentikanPelacakan() {
    // Stop background location listener
  }

  void _simpanStatusSelesai() {
    // Sinkronisasi status selesai ke lokal atau database
  }

  double hitungJarakTujuan(double currentLat, double currentLng, double targetLat, double targetLng) {
    return Geolocator.distanceBetween(currentLat, currentLng, targetLat, targetLng);
  }

  // Notifikasi Methods
  void kirimNotifikasi(String pesan) {
    // Integrasi dengan local_notifications
  }

  void tandaiDibaca() {
    // Menghapus badge atau mark as read di tabel notifikasi
  }

  void cekJarakTujuan(double currentLat, double currentLng, double targetLat, double targetLng) {
    final jarak = hitungJarakTujuan(currentLat, currentLng, targetLat, targetLng);
    if (jarak < 500) { // Jika kurang dari 500 meter
      _triggerAlarmProximity();
    }
  }

  void _triggerAlarmProximity() {
    kirimNotifikasi("Anda sudah dekat dengan tujuan!");
    // Trigger getaran / suara alarm
  }
}

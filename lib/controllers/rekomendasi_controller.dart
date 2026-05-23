import 'package:flutter/material.dart';
import 'package:busguide/models/wisata_service.dart';
import 'package:busguide/models/po_bus_service.dart';
import 'package:busguide/models/wisata.dart';
import 'package:busguide/models/po_bus.dart';

class RekomendasiController extends ChangeNotifier {
  final _wisataService = WisataService();
  final _poBusService = PoBusService();

  List<Wisata> _wisataList = [];
  List<PoBus> _poBusList = [];
  bool _isLoadingWisata = true;
  bool _isLoadingPoBus = true;
  String? _errorWisata;
  String? _errorPoBus;

  // ─── GETTERS ─────────────────────────────────────────────
  List<Wisata> get wisataList => _wisataList;
  List<PoBus> get poBusList => _poBusList;
  bool get isLoadingWisata => _isLoadingWisata;
  bool get isLoadingPoBus => _isLoadingPoBus;
  String? get errorWisata => _errorWisata;
  String? get errorPoBus => _errorPoBus;

  // ─── LOAD WISATA ──────────────────────────────────────────
  Future<void> loadWisata() async {
    _isLoadingWisata = true;
    _errorWisata = null;
    notifyListeners();

    try {
      _wisataList = await _wisataService.getSemuaWisata();
    } catch (_) {
      _errorWisata = 'Gagal memuat data wisata. Coba lagi.';
    } finally {
      _isLoadingWisata = false;
      notifyListeners();
    }
  }

  // ─── LOAD PO BUS ──────────────────────────────────────────
  Future<void> loadPoBus() async {
    _isLoadingPoBus = true;
    _errorPoBus = null;
    notifyListeners();

    try {
      _poBusList = await _poBusService.getSemuaPoBus();
    } catch (_) {
      _errorPoBus = 'Gagal memuat data PO Bus. Coba lagi.';
    } finally {
      _isLoadingPoBus = false;
      notifyListeners();
    }
  }

  // ─── LOAD KEDUANYA ────────────────────────────────────────
  Future<void> loadAll() async {
    await Future.wait([loadWisata(), loadPoBus()]);
  }
}

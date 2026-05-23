import 'package:flutter/material.dart';
import 'package:busguide/models/wisata_service.dart';
import 'package:busguide/models/wisata.dart';
import 'package:busguide/models/rute.dart';

class DetailWisataController extends ChangeNotifier {
  final _wisataService = WisataService();

  Wisata? _wisata;
  List<Rute> _ruteList = [];
  bool _isLoading = true;
  String? _error;

  // ─── GETTERS ─────────────────────────────────────────────
  Wisata? get wisata => _wisata;
  List<Rute> get ruteList => _ruteList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── LOAD DATA ────────────────────────────────────────────
  Future<void> loadData(int idWisata) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final wisata = await _wisataService.getDetailWisata(idWisata);

      List<Rute> ruteList = [];
      try {
        ruteList = await _wisataService.getRuteByWisata(idWisata);
      } catch (_) {}

      _wisata = wisata;
      _ruteList = ruteList;
    } catch (e) {
      _error = 'Gagal memuat detail wisata.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import '../models/wisata_service.dart';
import '../models/wisata.dart';
import '../models/rute.dart';

class WisataController extends ChangeNotifier {
  final _service = WisataService();

  List<Wisata> _rekomendasi = [];
  bool _isLoading = false;

  List<Wisata> get rekomendasi => _rekomendasi;
  bool get isLoading => _isLoading;

  Future<void> muatRekomendasi() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rekomendasi = await _service.getSemuaWisata(); // Anggap semua sebagai rekomendasi
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<Wisata?> getDetail(int idWisata) async {
    try {
      return await _service.getDetailWisata(idWisata);
    } catch (_) {
      return null;
    }
  }

  Future<List<Rute>> getRuteByWisata(int idWisata) async {
    // Logika mencari rute yang melewati halte di dekat wisata ini
    return [];
  }
}

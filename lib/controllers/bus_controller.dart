import 'package:flutter/material.dart';
import '../models/bus_service.dart';
import '../models/po_bus.dart';
import '../models/jadwal.dart';

class BusController extends ChangeNotifier {
  final _service = BusService();
  
  List<PoBus> _busList = [];
  List<Jadwal> _jadwal = [];
  bool _isLoading = false;

  List<PoBus> get busList => _busList;
  List<Jadwal> get jadwal => _jadwal;
  bool get isLoading => _isLoading;

  Future<void> muatBusList() async {
    _isLoading = true;
    notifyListeners();
    try {
      _busList = await _service.getBusList();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> filterBus(Map<String, dynamic> kriteria) async {
    _isLoading = true;
    notifyListeners();
    try {
      _busList = await _service.filterBus(kriteria);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<PoBus?> getDetail(int id) async {
    try {
      return await _service.getDetail(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> getJadwal(int idBus) async {
    _isLoading = true;
    notifyListeners();
    try {
      _jadwal = await _service.getJadwal(idBus);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}

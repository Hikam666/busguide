import 'package:flutter/material.dart';
import 'package:busguide/models/po_bus_service.dart';
import 'package:busguide/models/po_bus.dart';

class DetailPoBusController extends ChangeNotifier {
  final _poBusService = PoBusService();

  PoBus? _poBus;
  List<Bus> _armadaList = [];
  bool _isLoading = true;
  String? _error;

  // ─── GETTERS ─────────────────────────────────────────────
  PoBus? get poBus => _poBus;
  List<Bus> get armadaList => _armadaList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── LOAD DATA ────────────────────────────────────────────
  Future<void> loadData(int idPoBus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final po = await _poBusService.getDetailPoBus(idPoBus);
      final armada = await _poBusService.getArmadaByPo(idPoBus);
      _poBus = po;
      _armadaList = armada;
    } catch (_) {
      _error = 'Gagal memuat detail PO Bus.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

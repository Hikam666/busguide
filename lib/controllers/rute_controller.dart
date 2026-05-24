import 'package:flutter/material.dart';
import '../models/rute_service.dart';
import '../models/rute.dart';
import '../models/halte.dart';

class RuteController extends ChangeNotifier {
  final _service = RuteService();

  List<Rute> _ruteList = [];
  bool _isLoading = false;

  List<Rute> get ruteList => _ruteList;
  bool get isLoading => _isLoading;

  Future<List<Halte>> getHalteList(int idRute) async {
    // Akan memanggil rute_halte dari halte_service atau rute_service
    return [];
  }

  Future<List<TitikRute>> getTitikRute(int idRute) async {
    return await _service.getTitikRute(idRute);
  }

  Future<Rute?> tentukanRuteTerbaik(Halte asal, Halte tujuan) async {
    // Algoritma penentuan rute terbaik (misal: mencari rute yang melewati kedua halte tersebut)
    return null;
  }

  int hitungEstimasiWaktu(Rute rute) {
    return 25; // Default fallback (hardcoded until dynamic OSRM integration if needed)
  }
}

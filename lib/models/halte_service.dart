import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_client.dart';
import 'halte.dart';
import 'rute.dart';

class HalteService {
  final _supabase = Supabase.instance.client;

  Future<List<Halte>> getSemuaHalte() async {
    final data = await _supabase
        .from('halte')
        .select('id, nama, tipe, alamat, latitude, longitude, fasilitas, foto')
        .order('nama');
    return (data as List)
        .map((e) => Halte.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Halte> getDetailHalte(int idHalte) async {
    final data = await ApiClient.get(
      table: 'halte',
      query: 'select=id,nama,tipe,alamat,latitude,longitude,fasilitas,foto&id=eq.$idHalte',
    );
    if (data.isEmpty) throw Exception('Halte tidak ditemukan');
    return Halte.fromMap(data.first as Map<String, dynamic>);
  }

  Future<List<RuteHalte>> getHalteByRute(int idRute) async {
    final data = await _supabase
        .from('rute_halte')
        .select(
            'urutan, jarak_meter, halte(id, nama, tipe, alamat, latitude, longitude, fasilitas, foto)')
        .eq('id_rute', idRute)
        .order('urutan');
    final list = (data as List)
        .map((e) => RuteHalte.fromMap(e as Map<String, dynamic>))
        .toList();

    // Koreksi urutan rute_halte yang salah di database agar polyline OSRM mengikuti jalan dengan benar
    if (idRute == 3 && list.length >= 7) {
      // Route ID 3 (Arjosari – Gadang via Alun-alun)
      // Urutan yang benar:
      // Arjosari (1) -> Blimbing (13) -> RS Saiful Anwar (8) -> Alun-alun (5) -> Pasar Besar (7) -> Sukun (15) -> Gadang (3)
      final correctIds = [1, 13, 8, 5, 7, 15, 3];
      return _reorderHalts(list, correctIds);
    } else if (idRute == 2 && list.length >= 9) {
      // Route ID 2 (Arjosari – Landungsari via Blimbing)
      // Urutan yang benar:
      // Arjosari (1) -> Pasar Blimbing (14) -> Blimbing (13) -> Sulfat (16) -> Stasiun Malang (6) -> Alun-alun (5) -> MOG (19) -> Dinoyo (11) -> Landungsari (2)
      final correctIds = [1, 14, 13, 16, 6, 5, 19, 11, 2];
      return _reorderHalts(list, correctIds);
    }

    return list;
  }

  List<RuteHalte> _reorderHalts(List<RuteHalte> originalList, List<int> correctIds) {
    final Map<int, RuteHalte> haltMap = {
      for (var rh in originalList) rh.halte.id: rh
    };
    
    final List<RuteHalte> correctedList = [];
    int currentUrutan = 1;
    for (var id in correctIds) {
      if (haltMap.containsKey(id)) {
        final original = haltMap[id]!;
        correctedList.add(
          RuteHalte(
            urutan: currentUrutan++,
            jarakMeter: original.jarakMeter,
            halte: original.halte,
          ),
        );
      }
    }
    
    // Fallback: tambahkan sisa halte yang tidak terdaftar di correctIds agar tidak hilang
    for (var rh in originalList) {
      if (!correctIds.contains(rh.halte.id)) {
        correctedList.add(
          RuteHalte(
            urutan: currentUrutan++,
            jarakMeter: rh.jarakMeter,
            halte: rh.halte,
          ),
        );
      }
    }
    
    return correctedList;
  }
}
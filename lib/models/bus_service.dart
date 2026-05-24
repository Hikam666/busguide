import 'package:supabase_flutter/supabase_flutter.dart';
import 'po_bus.dart';
import 'jadwal.dart';

class BusService {
  final _supabase = Supabase.instance.client;

  Future<List<PoBus>> getBusList() async {
    final data = await _supabase.from('po_bus').select();
    return (data as List).map((e) => PoBus.fromMap(e)).toList();
  }

  Future<List<PoBus>> filterBus(Map<String, dynamic> kriteria) async {
    // Implementasi filter bus
    return [];
  }

  Future<PoBus> getDetail(int id) async {
    final data = await _supabase.from('po_bus').select().eq('id', id).single();
    return PoBus.fromMap(data);
  }

  Future<List<Jadwal>> getJadwal(int idBus) async {
    final data = await _supabase.from('jadwal').select().eq('id_bus', idBus);
    return (data as List).map((e) => Jadwal.fromMap(e)).toList();
  }
}

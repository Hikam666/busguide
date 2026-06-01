import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_client.dart';
import 'halte.dart';
import 'rute.dart';

class HalteService {
  final _supabase = Supabase.instance.client;

  // Ambil semua halte
  Future<List<Halte>> getSemuaHalte() async {
    final data = await _supabase
        .from('halte')
        .select('id, nama, tipe, alamat, latitude, longitude')
        .order('nama');
    return (data as List)
        .map((e) => Halte.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Ambil detail satu halte (Menggunakan HTTP murni sesuai tugas)
  Future<Halte> getDetailHalte(int idHalte) async {
    final data = await ApiClient.get(
      table: 'halte',
      query: 'select=id,nama,tipe,alamat,latitude,longitude&id=eq.$idHalte',
    );
    if (data.isEmpty) throw Exception('Halte tidak ditemukan');
    return Halte.fromMap(data.first as Map<String, dynamic>);
  }

  // Ambil daftar halte dalam satu rute (urut berdasarkan urutan)
  Future<List<RuteHalte>> getHalteByRute(int idRute) async {
    final data = await _supabase
        .from('rute_halte')
        .select(
            'urutan, jarak_meter, halte(id, nama, tipe, alamat, latitude, longitude)')
        .eq('id_rute', idRute)
        .order('urutan');
    return (data as List)
        .map((e) => RuteHalte.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
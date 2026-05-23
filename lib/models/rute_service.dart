import 'package:supabase_flutter/supabase_flutter.dart';
import 'rute.dart';

class RuteService {
  final _supabase = Supabase.instance.client;

  // Ambil semua rute
  Future<List<Rute>> getSemuaRute() async {
    final data = await _supabase.from('rute').select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama, tipe, alamat, latitude, longitude),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama, tipe, alamat, latitude, longitude)
        ''').order('kode');
    return (data as List)
        .map((e) => Rute.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Ambil detail satu rute
  Future<Rute> getDetailRute(int idRute) async {
    final data = await _supabase.from('rute').select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama, tipe, alamat, latitude, longitude),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama, tipe, alamat, latitude, longitude)
        ''').eq('id', idRute).single();
    return Rute.fromMap(data);
  }

  // Ambil titik GPS jalur rute (untuk gambar polyline di peta)
  Future<List<TitikRute>> getTitikRute(int idRute) async {
    final data = await _supabase
        .from('titik_rute')
        .select('urutan, latitude, longitude')
        .eq('id_rute', idRute)
        .order('urutan');
    return (data as List)
        .map((e) => TitikRute.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Cari rute berdasarkan halte asal dan tujuan
  Future<List<Rute>> cariRute({
    required int idHalteAsal,
    required int idHalteTujuan,
  }) async {
    // Ambil id_rute yang melewati halte asal
    final ruteAsal = await _supabase
        .from('rute_halte')
        .select('id_rute')
        .eq('id_halte', idHalteAsal);

    final idRuteList = (ruteAsal as List).map((e) => e['id_rute']).toList();
    if (idRuteList.isEmpty) return [];

    // Dari rute tersebut, filter yang juga melewati halte tujuan
    final ruteTujuan = await _supabase
        .from('rute_halte')
        .select('id_rute')
        .eq('id_halte', idHalteTujuan)
        .inFilter('id_rute', idRuteList);

    final idRuteCocok =
        (ruteTujuan as List).map((e) => e['id_rute']).toList();
    if (idRuteCocok.isEmpty) return [];

    // Ambil detail rute yang cocok
    final data = await _supabase.from('rute').select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama, tipe, alamat, latitude, longitude),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama, tipe, alamat, latitude, longitude)
        ''').inFilter('id', idRuteCocok);

    return (data as List)
        .map((e) => Rute.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
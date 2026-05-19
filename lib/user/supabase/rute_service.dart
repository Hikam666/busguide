import 'package:supabase_flutter/supabase_flutter.dart';

class RuteService {
  final _supabase = Supabase.instance.client;

  // Ambil semua rute
  Future<List<Map<String, dynamic>>> getSemuaRute() async {
    final data = await _supabase
        .from('rute')
        .select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama)
        ''')
        .order('kode');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ambil detail satu rute beserta semua haltenya
  Future<Map<String, dynamic>> getDetailRute(int idRute) async {
    final rute = await _supabase
        .from('rute')
        .select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama)
        ''')
        .eq('id', idRute)
        .single();
    return rute;
  }

  // Ambil titik GPS jalur rute (untuk gambar polyline di peta)
  Future<List<Map<String, dynamic>>> getTitikRute(int idRute) async {
    final data = await _supabase
        .from('titik_rute')
        .select('urutan, latitude, longitude')
        .eq('id_rute', idRute)
        .order('urutan');
    return List<Map<String, dynamic>>.from(data);
  }

  // Cari rute berdasarkan halte asal dan tujuan
  Future<List<Map<String, dynamic>>> cariRute({
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

    final idRuteCocok = (ruteTujuan as List).map((e) => e['id_rute']).toList();
    if (idRuteCocok.isEmpty) return [];

    // Ambil detail rute yang cocok
    final data = await _supabase
        .from('rute')
        .select('''
          id, kode, nama, estimasi_menit,
          terminal_awal:halte!rute_terminal_awal_fkey(id, nama),
          terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama)
        ''')
        .inFilter('id', idRuteCocok);

    return List<Map<String, dynamic>>.from(data);
  }
}
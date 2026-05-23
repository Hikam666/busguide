import 'package:supabase_flutter/supabase_flutter.dart';

class JadwalService {
  final _supabase = Supabase.instance.client;

  // Ambil jadwal berdasarkan rute
  Future<List<Map<String, dynamic>>> getJadwalByRute(int idRute) async {
    final data = await _supabase
        .from('jadwal')
        .select('''
          id, jam_berangkat, estimasi_menit, hari, status,
          bus(id, nomor_polisi, tipe, fasilitas,
            po_bus(id, nama, logo_url)
          )
        ''')
        .eq('id_rute', idRute)
        .eq('status', 'aktif')
        .order('jam_berangkat');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ambil jadwal berdasarkan rute dan hari tertentu
  // contoh hari: 'senin', 'selasa', dst
  Future<List<Map<String, dynamic>>> getJadwalByRuteAndHari({
    required int idRute,
    required String hari,
  }) async {
    final data = await _supabase
        .from('jadwal')
        .select('''
          id, jam_berangkat, estimasi_menit, hari, status,
          bus(id, nomor_polisi, tipe, fasilitas,
            po_bus(id, nama, logo_url)
          )
        ''')
        .eq('id_rute', idRute)
        .eq('status', 'aktif')
        .contains('hari', [hari])
        .order('jam_berangkat');
    return List<Map<String, dynamic>>.from(data);
  }
}
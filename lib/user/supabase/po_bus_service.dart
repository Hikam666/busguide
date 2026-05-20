import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// SERVICE: PO BUS
// ==========================================
class PoBusService {
  final _supabase = Supabase.instance.client;

  // Mengambil semua profil PO Bus
  Future<List<Map<String, dynamic>>> getSemuaPoBus() async {
    final data = await _supabase.from('po_bus').select('*').order('nama');
    return List<Map<String, dynamic>>.from(data);
  }

  // Mengambil detail 1 profil PO Bus berdasarkan ID
  Future<Map<String, dynamic>> getDetailPoBus(int idPoBus) async {
    final data = await _supabase.from('po_bus').select('*').eq('id', idPoBus).single();
    return data;
  }

  // Mengambil armada bus yang dimiliki oleh PO tersebut
  Future<List<Map<String, dynamic>>> getArmadaByPo(int idPoBus) async {
    final data = await _supabase
        .from('bus')
        .select('*')
        .eq('id_po', idPoBus)
        .order('nomor_polisi');
    return List<Map<String, dynamic>>.from(data);
  }
}
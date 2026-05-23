import 'package:supabase_flutter/supabase_flutter.dart';
import 'po_bus.dart';

class PoBusService {
  final _supabase = Supabase.instance.client;

  // Mengambil semua profil PO Bus
  Future<List<PoBus>> getSemuaPoBus() async {
    final data = await _supabase
        .from('po_bus')
        .select('id, nama, tagline, deskripsi, logo_url')
        .order('nama');
    return (data as List)
        .map((e) => PoBus.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Mengambil detail 1 profil PO Bus berdasarkan ID
  Future<PoBus> getDetailPoBus(int idPoBus) async {
    final data = await _supabase
        .from('po_bus')
        .select('id, nama, tagline, deskripsi, logo_url')
        .eq('id', idPoBus)
        .single();
    return PoBus.fromMap(data);
  }

  // Mengambil armada bus yang dimiliki oleh PO tersebut
  Future<List<Bus>> getArmadaByPo(int idPoBus) async {
    final data = await _supabase
        .from('bus')
        .select('id, id_po, nomor_polisi, tipe, kapasitas, fasilitas, status')
        .eq('id_po', idPoBus)
        .order('nomor_polisi');
    return (data as List)
        .map((e) => Bus.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

class WisataService {
  final _supabase = Supabase.instance.client;

  // Ambil semua wisata
  Future<List<Map<String, dynamic>>> getSemuaWisata() async {
    final data = await _supabase
        .from('wisata')
        .select('id, nama, alamat, kota, deskripsi, tarif, jam_buka, jam_tutup, foto_url')
        .order('nama');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ambil detail satu wisata
  Future<Map<String, dynamic>> getDetailWisata(int idWisata) async {
    final data = await _supabase
        .from('wisata')
        .select('id, nama, alamat, kota, deskripsi, tarif, jam_buka, jam_tutup, foto_url')
        .eq('id', idWisata)
        .single();
    return data;
  }

  // Ambil wisata yang bisa diakses lewat rute tertentu
  Future<List<Map<String, dynamic>>> getWisataByRute(int idRute) async {
    final data = await _supabase
        .from('rute_wisata')
        .select('wisata(id, nama, alamat, kota, deskripsi, tarif, jam_buka, jam_tutup, foto_url)')
        .eq('id_rute', idRute);
    return List<Map<String, dynamic>>.from(data);
  }
}
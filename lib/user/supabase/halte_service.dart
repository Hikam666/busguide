import 'package:supabase_flutter/supabase_flutter.dart';

class HalteService {
  final _supabase = Supabase.instance.client;

  // Ambil semua halte
  Future<List<Map<String, dynamic>>> getSemuaHalte() async {
    final data = await _supabase
        .from('halte')
        .select('id, nama, tipe, alamat, latitude, longitude')
        .order('nama');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ambil halte terdekat berdasarkan koordinat user
  // Filtering jarak dilakukan di sisi client pakai Haversine (location_helper.dart)
  Future<List<Map<String, dynamic>>> getHalteTerdekat({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _supabase
        .from('halte')
        .select('id, nama, tipe, alamat, latitude, longitude');
    return List<Map<String, dynamic>>.from(data);
  }

  // Ambil detail satu halte
  Future<Map<String, dynamic>> getDetailHalte(int idHalte) async {
    final data = await _supabase
        .from('halte')
        .select('id, nama, tipe, alamat, latitude, longitude')
        .eq('id', idHalte)
        .single();
    return data;
  }

  // Ambil daftar halte dalam satu rute (urut berdasarkan urutan)
  Future<List<Map<String, dynamic>>> getHalteByRute(int idRute) async {
    final data = await _supabase
        .from('rute_halte')
        .select('urutan, jarak_meter, halte(id, nama, tipe, alamat, latitude, longitude)')
        .eq('id_rute', idRute)
        .order('urutan');
    return List<Map<String, dynamic>>.from(data);
  }
}
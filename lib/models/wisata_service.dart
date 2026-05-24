import 'package:supabase_flutter/supabase_flutter.dart';
import 'wisata.dart';
import 'rute.dart';

class WisataService {
  final _supabase = Supabase.instance.client;

  // Ambil semua wisata
  Future<List<Wisata>> getSemuaWisata() async {
    final data = await _supabase
        .from('wisata')
        .select(
            'id, nama, alamat, kota, deskripsi, tarif, jam_buka, jam_tutup, foto_url')
        .order('nama');
    return (data as List)
        .map((e) => Wisata.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Ambil detail satu wisata
  Future<Wisata> getDetailWisata(int idWisata) async {
    final data = await _supabase
        .from('wisata')
        .select(
            'id, nama, alamat, kota, deskripsi, tarif, jam_buka, jam_tutup, foto_url')
        .eq('id', idWisata)
        .single();
    return Wisata.fromMap(data);
  }

  // Ambil rute yang melewati wisata ini (relasi melalui rute_wisata)
  Future<List<Rute>> getRuteByWisata(int idWisata) async {
    final data = await _supabase.from('rute_wisata').select('''
          rute(
            id, kode, nama,
            terminal_awal:halte!rute_terminal_awal_fkey(id, nama, tipe, alamat, latitude, longitude),
            terminal_akhir:halte!rute_terminal_akhir_fkey(id, nama, tipe, alamat, latitude, longitude)
          )
        ''').eq('id_wisata', idWisata);
    return (data as List)
        .where((e) => e['rute'] != null)
        .map((e) => Rute.fromMap(e['rute'] as Map<String, dynamic>))
        .toList();
  }
}
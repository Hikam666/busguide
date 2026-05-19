import 'package:supabase_flutter/supabase_flutter.dart';

class PerjalananService {
  final _supabase = Supabase.instance.client;

  // ─── PERJALANAN AKTIF ────────────────────────────────────

  // Mulai perjalanan baru
  Future<Map<String, dynamic>> mulaiPerjalanan({
    required int idRute,
    required int idHalteAsal,
    required int idHalteTujuan,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    final data = await _supabase
        .from('perjalanan')
        .insert({
          'id_pengguna': userId,
          'id_rute': idRute,
          'halte_asal': idHalteAsal,
          'halte_tujuan': idHalteTujuan,
          'status': 'aktif',
          'alarm_aktif': true,
        })
        .select()
        .single();
    return data;
  }

  // Ambil perjalanan aktif user saat ini (jika ada)
  Future<Map<String, dynamic>?> getPerjalananAktif() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('perjalanan')
        .select('''
          id, waktu_mulai, alarm_aktif, status,
          rute(id, kode, nama),
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama)
        ''')
        .eq('id_pengguna', userId)
        .eq('status', 'aktif')
        .maybeSingle();
    return data;
  }

  // Selesaikan perjalanan + simpan ke riwayat
  Future<void> selesaikanPerjalanan({
    required int idPerjalanan,
    required int durasiMenit,
    int? estimasiBiaya,
    String? catatan,
  }) async {
    // Update status perjalanan menjadi selesai
    await _supabase
        .from('perjalanan')
        .update({
          'status': 'selesai',
          'waktu_selesai': DateTime.now().toIso8601String(),
          'alarm_aktif': false,
        })
        .eq('id', idPerjalanan);

    // Simpan ke riwayat_perjalanan
    await _supabase.from('riwayat_perjalanan').insert({
      'id_perjalanan': idPerjalanan,
      'durasi_menit': durasiMenit,
      'estimasi_biaya': estimasiBiaya,
      'catatan': catatan,
    });
  }

  // Batalkan perjalanan
  Future<void> batalkanPerjalanan(int idPerjalanan) async {
    await _supabase
        .from('perjalanan')
        .update({
          'status': 'dibatalkan',
          'waktu_selesai': DateTime.now().toIso8601String(),
          'alarm_aktif': false,
        })
        .eq('id', idPerjalanan);
  }

  // Toggle alarm halte tujuan
  Future<void> toggleAlarm({
    required int idPerjalanan,
    required bool aktif,
  }) async {
    await _supabase
        .from('perjalanan')
        .update({'alarm_aktif': aktif})
        .eq('id', idPerjalanan);
  }

  // ─── RIWAYAT PERJALANAN ──────────────────────────────────

  // Ambil semua riwayat perjalanan user
  Future<List<Map<String, dynamic>>> getRiwayatPerjalanan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('perjalanan')
        .select('''
          id, waktu_mulai, waktu_selesai, status,
          rute(id, kode, nama),
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama),
          riwayat_perjalanan(durasi_menit, estimasi_biaya, catatan)
        ''')
        .eq('id_pengguna', userId)
        .neq('status', 'aktif')
        .order('waktu_mulai', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
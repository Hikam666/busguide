import 'package:supabase_flutter/supabase_flutter.dart';
import 'perjalanan.dart';

class PerjalananService {
  final _supabase = Supabase.instance.client;

  // ─── PERJALANAN AKTIF ────────────────────────────────────

  // Mulai perjalanan baru
  Future<Perjalanan> mulaiPerjalanan({
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
        .select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          rute(id, kode, nama, estimasi_menit),
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama, tipe, alamat, latitude, longitude)
        ''')
        .single();
    return Perjalanan.fromMap(data);
  }

  // Ambil perjalanan aktif user saat ini (jika ada)
  Future<Perjalanan?> getPerjalananAktif() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('perjalanan')
        .select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          rute(id, kode, nama, estimasi_menit),
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama, tipe, alamat, latitude, longitude)
        ''')
        .eq('id_pengguna', userId)
        .eq('status', 'aktif')
        .maybeSingle();
    if (data == null) return null;
    return Perjalanan.fromMap(data);
  }

  // Selesaikan perjalanan + simpan ke riwayat
  Future<void> selesaikanPerjalanan({
    required int idPerjalanan,
    required int durasiMenit,
    int? estimasiBiaya,
    String? catatan,
  }) async {
    await _supabase.from('perjalanan').update({
      'status': 'selesai',
      'waktu_selesai': DateTime.now().toIso8601String(),
      'alarm_aktif': false,
    }).eq('id', idPerjalanan);

    await _supabase.from('riwayat_perjalanan').insert({
      'id_perjalanan': idPerjalanan,
      'durasi_menit': durasiMenit,
      'estimasi_biaya': estimasiBiaya,
      'catatan': catatan,
    });
  }

  // Batalkan perjalanan
  Future<void> batalkanPerjalanan(int idPerjalanan) async {
    await _supabase.from('perjalanan').update({
      'status': 'dibatalkan',
      'waktu_selesai': DateTime.now().toIso8601String(),
      'alarm_aktif': false,
    }).eq('id', idPerjalanan);
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

  // Ambil semua riwayat perjalanan user (ringkas, untuk home)
  Future<List<Perjalanan>> getRiwayatPerjalanan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('perjalanan')
        .select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          rute(id, kode, nama, estimasi_menit),
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama, tipe, alamat, latitude, longitude),
          riwayat_perjalanan(id, id_perjalanan, durasi_menit, estimasi_biaya, catatan)
        ''')
        .eq('id_pengguna', userId)
        .neq('status', 'aktif')
        .order('waktu_mulai', ascending: false);

    return (data as List)
        .map((e) => Perjalanan.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Ambil riwayat lengkap dengan join po_bus (untuk layar riwayat)
  Future<List<Perjalanan>> getRiwayatLengkap({String? filterStatus}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _supabase.from('perjalanan').select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          halte_asal:halte!perjalanan_halte_asal_fkey(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte!perjalanan_halte_tujuan_fkey(id, nama, tipe, alamat, latitude, longitude),
          rute:rute!perjalanan_id_rute_fkey(id, kode, nama, estimasi_menit),
          riwayat_perjalanan(id, id_perjalanan, durasi_menit, estimasi_biaya, catatan)
        ''').eq('id_pengguna', userId);

    if (filterStatus != null && filterStatus != 'semua') {
      query = query.eq('status', filterStatus);
    }

    final data = await query.order('waktu_mulai', ascending: false);

    return (data as List)
        .map((e) => Perjalanan.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
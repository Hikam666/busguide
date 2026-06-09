import 'package:supabase_flutter/supabase_flutter.dart';
import 'perjalanan.dart';
import '../utils/temp_cache.dart';

class PerjalananService {
  final _supabase = Supabase.instance.client;

  // ─── PERJALANAN AKTIF ────────────────────────────────────

  // Mulai perjalanan baru
  Future<Perjalanan> mulaiPerjalanan({
    int? idRute,
    int? idHalteAsal,
    int? idHalteTujuan,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    // Auto-cancel any existing active journeys for this user to prevent multiple active journeys
    try {
      await _supabase
          .from('perjalanan')
          .update({
            'status': 'dibatalkan',
            'waktu_selesai': DateTime.now().toUtc().toIso8601String(),
            'alarm_aktif': false,
          })
          .eq('id_pengguna', userId)
          .eq('status', 'aktif');
    } catch (_) {
      // Ignore if there are no existing active journeys or if updating fails
    }

    final data = await _supabase
        .from('perjalanan')
        .insert({
          'id_pengguna': userId,
          'id_rute': idRute == 0 || idRute == -1 ? null : idRute,
          'halte_asal': idHalteAsal == 0 || idHalteAsal == -1 ? null : idHalteAsal,
          'halte_tujuan': idHalteTujuan == 0 || idHalteTujuan == -1 ? null : idHalteTujuan,
          'status': 'aktif',
          'alarm_aktif': true,
        })
        .select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          rute(id, kode, nama, estimasi_menit),
          halte_asal:halte_asal(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte_tujuan(id, nama, tipe, alamat, latitude, longitude)
        ''')
        .single();
    return Perjalanan.fromMap(data);
  }

  // Ambil perjalanan aktif user saat ini (jika ada)
  Future<Perjalanan?> getPerjalananAktif() async {
    if (TempCache.inMemoryPerjalanan != null) {
      return TempCache.inMemoryPerjalanan;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('perjalanan')
        .select('''
          id, status, waktu_mulai, waktu_selesai, alarm_aktif,
          rute(id, kode, nama, estimasi_menit),
          halte_asal:halte_asal(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte_tujuan(id, nama, tipe, alamat, latitude, longitude)
        ''')
        .eq('id_pengguna', userId)
        .eq('status', 'aktif')
        .maybeSingle();
    if (data == null) return null;
    return Perjalanan.fromMap(data);
  }

  // Selesaikan perjalanan
  Future<void> selesaikanPerjalanan({
    required int idPerjalanan,
    required int durasiMenit,
  }) async {
    if (idPerjalanan < 0) {
      if (TempCache.inMemoryPerjalanan?.id == idPerjalanan) {
        TempCache.inMemoryPerjalanan = null;
      }
      return;
    }

    final waktuSelesai = DateTime.now().toUtc().toIso8601String();
    
    // Update status perjalanan
    await _supabase.from('perjalanan').update({
      'status': 'selesai',
      'waktu_selesai': waktuSelesai,
      'alarm_aktif': false,
    }).eq('id', idPerjalanan);

    // Sisipkan ke riwayat_perjalanan (Try catch agar tidak nge-block jika ada RLS error di database)
    try {
      await _supabase.from('riwayat_perjalanan').insert({
        'id_perjalanan': idPerjalanan,
        'durasi_menit': durasiMenit,
        'estimasi_biaya': null,
        'catatan': 'Perjalanan diselesaikan.',
      });
    } catch (e) {
      // Abaikan jika terjadi error log atau RLS
    }
  }

  // Batalkan perjalanan
  Future<void> batalkanPerjalanan(int idPerjalanan) async {
    if (idPerjalanan < 0) {
      if (TempCache.inMemoryPerjalanan?.id == idPerjalanan) {
        TempCache.inMemoryPerjalanan = null;
      }
      return;
    }

    await _supabase.from('perjalanan').update({
      'status': 'dibatalkan',
      'waktu_selesai': DateTime.now().toUtc().toIso8601String(),
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
          rute:rute!perjalanan_id_rute_fkey(id, kode, nama, estimasi_menit),
          halte_asal:halte_asal(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte_tujuan(id, nama, tipe, alamat, latitude, longitude),
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
          halte_asal:halte_asal(id, nama, tipe, alamat, latitude, longitude),
          halte_tujuan:halte_tujuan(id, nama, tipe, alamat, latitude, longitude),
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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifikasi.dart';

class NotifikasiService {
  final _supabase = Supabase.instance.client;

  // Fetch all notifications from the database for the current logged-in user
  Future<List<Notifikasi>> getNotifikasi() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from('notifikasi')
          .select('*')
          .or('id_pengguna.eq.$userId,id_pengguna.is.null')
          .order('tanggal_kirim', ascending: false);

      return (data as List)
          .map((e) => Notifikasi.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback: return empty list on any database or RLS error
      return [];
    }
  }

  // Mark a single notification as read in the database
  Future<void> tandaiDibaca(int idNotifikasi) async {
    try {
      await _supabase
          .from('notifikasi')
          .update({'status_baca': true})
          .eq('id', idNotifikasi);
    } catch (_) {}
  }

  // Mark all notifications as read in the database
  Future<void> tandaiSemuaDibaca() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('notifikasi')
          .update({'status_baca': true})
          .or('id_pengguna.eq.$userId,id_pengguna.is.null')
          .eq('status_baca', false);
    } catch (_) {}
  }
}

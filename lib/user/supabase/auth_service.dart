import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ─── LOGIN ───────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Login gagal');

      // Ambil role dari tabel profiles
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return {
        'user': user,
        'role': profile['role'] ?? 'pengguna',
      };
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ─── REGISTER ────────────────────────────────────────────
  Future<User?> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nama': nama},
      );

      final user = response.user;
      if (user == null) throw Exception('Register gagal');

      // CATATAN:
      // Insert ke tabel 'profiles' tidak lagi dilakukan dari sisi aplikasi (Flutter)
      // karena sudah ditangani secara otomatis oleh Database Trigger di Supabase.

      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ─── CEK SESSION AKTIF ───────────────────────────────────
  // Dipanggil di main.dart untuk cek apakah user sudah login sebelumnya
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return {
        'user': user,
        'role': profile['role'] ?? 'pengguna',
      };
    } catch (e) {
      return null;
    }
  }

  // ─── GET CURRENT USER ────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;
}
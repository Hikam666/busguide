import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile.dart';

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
      final profileData = await _supabase
          .from('profiles')
          .select('id, nama, email, role')
          .eq('id', user.id)
          .single();

      final profile = UserProfile.fromMap(profileData);

      return {
        'user': user,
        'profile': profile,
        'role': profile.role,
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

      // Insert ke tabel 'profiles' ditangani oleh Database Trigger di Supabase.
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

  // ─── GET PROFILE DARI SUPABASE ───────────────────────────
  Future<UserProfile?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select('id, nama, email, role')
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ─── CEK SESSION AKTIF ───────────────────────────────────
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profileData = await _supabase
          .from('profiles')
          .select('id, nama, email, role')
          .eq('id', user.id)
          .single();

      final profile = UserProfile.fromMap(profileData);

      return {
        'user': user,
        'profile': profile,
        'role': profile.role,
      };
    } catch (e) {
      return null;
    }
  }

  // ─── GET CURRENT USER ────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;
}
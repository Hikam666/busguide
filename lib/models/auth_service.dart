import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn(
    serverClientId: '611504260934-7b8h32720mfejra325be3s3kaeuil1cr.apps.googleusercontent.com',
  );

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
          .select('id, nama, email, role, avatar_url')
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

  // ─── LOGIN GOOGLE ──────────────────────────────────────────────
  Future<Map<String, dynamic>> loginGoogle({bool isRegister = false}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Dibatalkan oleh pengguna');

      // Cek apakah email sudah terdaftar menggunakan RPC
      final emailExists = await _supabase.rpc('check_email_exists', params: {
        'check_email': googleUser.email,
      }) as bool;

      if (!isRegister && !emailExists) {
        await _googleSignIn.signOut();
        throw Exception('Akun belum terdaftar. Silakan daftar terlebih dahulu.');
      }

      if (isRegister && emailExists) {
        await _googleSignIn.signOut();
        throw Exception('Akun sudah terdaftar. Silakan masuk (login).');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Tidak ada ID Token dari Google');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) throw Exception('Login Supabase gagal');

      // Ambil profile dengan retry karena DB trigger insert ke 'profiles' butuh waktu
      Map<String, dynamic>? profileData;
      for (int i = 0; i < 3; i++) {
        profileData = await _supabase
            .from('profiles')
            .select('id, nama, email, role, avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (profileData != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (profileData == null) {
        // Fallback: Coba insert manual jika trigger Supabase gagal (mungkin karena field nama null pada metadata Google)
        final newProfile = {
          'id': user.id,
          'nama': googleUser.displayName ?? 'Pengguna Google',
          'email': user.email ?? googleUser.email,
          'role': 'pengguna',
          'avatar_url': googleUser.photoUrl,
        };
        try {
          await _supabase.from('profiles').insert(newProfile);
          profileData = newProfile;
        } catch (e) {
          throw Exception('Gagal memuat profil, pastikan trigger database berjalan. Error manual insert: $e');
        }
      }

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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  // ─── GET PROFILE DARI SUPABASE ───────────────────────────
  Future<UserProfile?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select('id, nama, email, role, avatar_url')
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ─── UPDATE PROFILE ────────────────────────────────────────
  Future<void> updateProfile({required String nama}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    await _supabase
        .from('profiles')
        .update({'nama': nama})
        .eq('id', user.id);
  }

  // ─── UPLOAD AVATAR ───────────────────────────────────────
  Future<String> uploadAvatar(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final ext = file.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'avatars/$fileName';

    // Upload file ke storage bucket 'avatars'
    await _supabase.storage.from('avatars').upload(path, file);

    // Ambil Public URL
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

    // Update profil table dengan avatar_url baru
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', user.id);

    return publicUrl;
  }

  // ─── CEK SESSION AKTIF ───────────────────────────────────
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profileData = await _supabase
          .from('profiles')
          .select('id, nama, email, role, avatar_url')
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
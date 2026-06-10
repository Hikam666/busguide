import 'dart:io';
import 'package:flutter/material.dart';
import 'package:busguide/models/auth_service.dart';
import 'package:busguide/models/user_profile.dart';

//Penghubung UI dan model
class ProfilController extends ChangeNotifier {
  final _authService = AuthService();

  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  // ─── GETTERS ─────────────────────────────────────────────
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get nama => _profile?.nama ?? 'Pengguna';
  String get email => _profile?.email ?? '';
  String get initials => _profile?.initials ?? '?';
  bool get isAdmin => _profile?.isAdmin ?? false;
  String get noHp => _profile?.noHp ?? '';
  String get alamat => _profile?.alamat ?? '';

  // ─── LOAD PROFIL ──────────────────────────────────────────
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    //Memberitahu widget untuk rebuild
    notifyListeners();

    try {
      final profile = await _authService.getProfile();
      _profile = profile;
    } catch (_) {
      _error = 'Gagal memuat profil. Coba lagi.';
    } finally {
      _isLoading = false;
      //Memperbarui UI dgn data baru
      notifyListeners();
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _profile = null;
    notifyListeners();
  }
  // ─── UPDATE PROFIL ───────────────────────────────────────
  Future<void> updateProfile({
    required String newNama,
    String? newNoHp,
    String? newAlamat,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      //Mengirim data profil yang baru ke backend
      await _authService.updateProfile(
        nama: newNama,
        noHp: newNoHp,
        alamat: newAlamat,
      );
      await loadProfile(); // Muat ulang profil dari server
    } catch (e) {
      _error = 'Gagal memperbarui profil: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── UPLOAD AVATAR ───────────────────────────────────────
  Future<void> uploadAvatar(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.uploadAvatar(imageFile);
      await loadProfile(); // Muat ulang dari server
    } catch (e) {
      _error = 'Gagal mengunggah foto: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}

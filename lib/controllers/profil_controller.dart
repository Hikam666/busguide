import 'package:flutter/material.dart';
import 'package:busguide/models/auth_service.dart';
import 'package:busguide/models/user_profile.dart';

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

  // ─── LOAD PROFIL ──────────────────────────────────────────
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _authService.getProfile();
      _profile = profile;
    } catch (_) {
      _error = 'Gagal memuat profil. Coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _profile = null;
    notifyListeners();
  }
}

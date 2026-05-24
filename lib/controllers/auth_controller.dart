import 'package:flutter/material.dart';
import 'package:busguide/models/auth_service.dart';

class AuthController extends ChangeNotifier {
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // ─── GETTERS ─────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── LOGIN ───────────────────────────────────────────────
  /// Mengembalikan role user ('admin' | 'pengguna') atau null jika gagal
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email dan password tidak boleh kosong');
      return null;
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(
        email: email.trim(),
        password: password.trim(),
      );
      return result['role'] as String?;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGIN GOOGLE ────────────────────────────────────────
  Future<String?> loginGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.loginGoogle();
      return result['role'] as String?;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── REGISTER ────────────────────────────────────────────
  /// Mengembalikan true jika berhasil
  Future<bool> register({
    required String nama,
    required String email,
    required String password,
    required String konfirmasiPassword,
  }) async {
    if (nama.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      _setError('Semua field wajib diisi');
      return false;
    }

    if (password != konfirmasiPassword) {
      _setError('Password dan konfirmasi password tidak sama');
      return false;
    }

    if (password.length < 6) {
      _setError('Password minimal 6 karakter');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _authService.register(
        nama: nama.trim(),
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}

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
    // Validasi form tidak boleh kosong
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email dan password tidak boleh kosong');
      return null;
    }

    // Nyalakan loading UI
    _setLoading(true);
    _setError(null);

    try {
      // Panggil Model (AuthService)
      final result = await _authService.login(
        email: email.trim(),
        password: password.trim(),
      );
      return result['role'] as String?;
    } catch (e) {
      // Bersihkan teks error bawaan sistem agar rapi dibaca user
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
      final result = await _authService.loginGoogle(isRegister: false);
      return result['role'] as String?;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── REGISTER GOOGLE ─────────────────────────────────────
  Future<String?> registerGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.loginGoogle(isRegister: true);
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
    // Validasi input tidak boleh ada yang kosong
    if (nama.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      _setError('Semua field wajib diisi');
      return false;
    }

    // Validasi kecocokan konfirmasi sandi
    if (password != konfirmasiPassword) {
      _setError('Password dan konfirmasi password tidak sama');
      return false;
    }

    // Standar keamanan Supabase minimal 6 karakter
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

  // ─── RESET PASSWORD ──────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      _setError('Email tidak boleh kosong');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Meminta server mengirim OTP ke email
      await _authService.resetPassword(email: email.trim());
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── VERIFIKASI OTP & UPDATE PASSWORD ───────────────────
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (email.trim().isEmpty || otp.trim().isEmpty || newPassword.trim().isEmpty) {
      _setError('Semua field wajib diisi');
      return false;
    }
    
    if (newPassword.length < 6) {
      _setError('Password minimal 6 karakter');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Tukar OTP dengan Sesi, lalu timpa password
      await _authService.verifyOtpAndResetPassword(
        email: email.trim(),
        otp: otp.trim(),
        newPassword: newPassword.trim(),
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

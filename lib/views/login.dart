import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final ctrl = context.read<AuthController>();
    final role = await ctrl.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ctrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.errorMessage!)),
      );
      return;
    }

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/user');
    }
  }

  Future<void> _handleLoginGoogle() async {
    final ctrl = context.read<AuthController>();
    final role = await ctrl.loginGoogle();

    if (!mounted) return;

    if (ctrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.errorMessage!)),
      );
      return;
    }

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role != null) {
      Navigator.pushReplacementNamed(context, '/user');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BagianHeader(),
                const SizedBox(height: 32),
                
                _FieldEmail(controller: _emailController),
                const SizedBox(height: 16),
                
                _FieldPassword(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                
                const _TombolLupaSandi(),
                
                _TombolLogin(
                  isLoading: context.watch<AuthController>().isLoading,
                  onPressed: context.watch<AuthController>().isLoading ? null : _handleLogin,
                ),
                
                const _BagianDivider(),
                _TombolGoogle(
                  isLoading: context.watch<AuthController>().isLoading,
                  onPressed: context.watch<AuthController>().isLoading ? null : _handleLoginGoogle,
                ),
                const SizedBox(height: 24),
                const _BagianDaftar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG (DI FILE YANG SAMA)
// ==========================================

class _BagianHeader extends StatelessWidget {
  const _BagianHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/img/logo.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'BusGuide',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _FieldEmail extends StatelessWidget {
  final TextEditingController controller;

  const _FieldEmail({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email_outlined),
        hintText: 'Email',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}

class _FieldPassword extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;

  const _FieldPassword({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        hintText: 'Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _TombolLupaSandi extends StatelessWidget {
  const _TombolLupaSandi({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Menyiapkan controller input untuk pop-up Lupa Sandi
          final emailController = TextEditingController();
          final otpController = TextEditingController();
          final passwordController = TextEditingController();
          // Variabel state lokal (khusus untuk pop-up ini)
          bool isEmailSent = false;
          bool isLoading = false;

          showDialog(
            context: context,
            barrierDismissible: false,
            // Menggunakan StatefulBuilder agar dialog bisa re-render UI-nya sendiri
            builder: (ctx) => StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  // Judul dinamis bergantung pada tahap pengiriman email
                  title: Text(isEmailSent ? 'Masukkan OTP' : 'Reset Password'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── TAHAP 1: SEBELUM EMAIL DIKIRIM ───
                      if (!isEmailSent) ...[
                        const Text('Kode OTP 6-digit akan dikirimkan ke email Anda.'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan email terdaftar',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      // ─── TAHAP 2: SETELAH EMAIL DIKIRIM (INPUT OTP) ───
                      ] else ...[
                        const Text('Cek kotak masuk email Anda untuk kode OTP.'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: otpController,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(letterSpacing: 8, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Kode 6 Digit',
                            hintStyle: const TextStyle(letterSpacing: 0, fontSize: 14, fontWeight: FontWeight.normal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password Baru',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final ctrl = context.read<AuthController>();
                              setStateDialog(() => isLoading = true);

                              if (!isEmailSent) {
                                // ─── TAHAP 1: PROSES KIRIM EMAIL ───
                                final success = await ctrl.resetPassword(emailController.text);
                                setStateDialog(() {
                                  isLoading = false;
                                  if (success) isEmailSent = true;
                                });
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ctrl.errorMessage ?? 'Gagal mengirim email'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // ─── TAHAP 2: VERIFIKASI OTP & RESET PASSWORD ───
                                final success = await ctrl.verifyOtpAndResetPassword(
                                  email: emailController.text,
                                  otp: otpController.text,
                                  newPassword: passwordController.text,
                                );
                                setStateDialog(() => isLoading = false);
                                
                                if (context.mounted) {
                                  if (success) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password berhasil direset! Anda telah login.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Karena Supabase otomatis memvalidasi sesi jika OTP benar,
                                    // user bisa langsung dilempar ke Beranda tanpa login ulang.
                                    Navigator.pushReplacementNamed(context, '/user');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ctrl.errorMessage ?? 'Gagal verifikasi OTP'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
                      child: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEmailSent ? 'Simpan' : 'Kirim OTP', style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
          );
        },
        child: const Text('Lupa kata sandi?', style: TextStyle(color: Color(0xFF0D6EFD))),
      ),
    );
  }
}

class _TombolLogin extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _TombolLogin({super.key, required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D6EFD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
            : const Text('Masuk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _BagianDivider extends StatelessWidget {
  const _BagianDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('atau', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _TombolGoogle extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _TombolGoogle({super.key, required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset('assets/img/google.jpg', width: 24, height: 24),
        label: const Text('Masuk dengan Google', style: TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _BagianDaftar extends StatelessWidget {
  const _BagianDaftar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Belum punya akun? '),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          child: const Text('Daftar sekarang', style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
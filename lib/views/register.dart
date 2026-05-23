import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _handleRegister() async {
    final ctrl = context.read<AuthController>();
    
    final success = await ctrl.register(
      email: _emailController.text,
      password: _passwordController.text,
      konfirmasiPassword: _confirmPasswordController.text,
      nama: _namaController.text,
    );

    if (!mounted) return;

    if (!success) {
      if (ctrl.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.errorMessage!)),
        );
      }
      return;
    }

    // Login setelah registrasi berhasil
    final role = await ctrl.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (role == null) {
      if (ctrl.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.errorMessage!)),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi berhasil! Selamat datang.')),
    );
        
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/user');
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BagianHeader(),
                const SizedBox(height: 24),
                
                _FieldInput(
                  controller: _namaController,
                  hintText: 'Nama lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                _FieldInput(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                _FieldPassword(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                _FieldPassword(
                  controller: _confirmPasswordController,
                  hintText: 'Konfirmasi password',
                  obscureText: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 24),
                
                _TombolDaftar(
                  isLoading: context.watch<AuthController>().isLoading, 
                  onPressed: context.watch<AuthController>().isLoading ? null : _handleRegister
                ),
                const _BagianDivider(),
                const _TombolGoogle(),
                const SizedBox(height: 24),
                const _BagianMasuk(),
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
          'Buat akun baru',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lengkapi data untuk mulai perjalanan Anda.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FieldInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _FieldPassword extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggle;

  const _FieldPassword({
    super.key,
    required this.controller,
    required this.hintText,
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
        hintText: hintText,
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

class _TombolDaftar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _TombolDaftar({super.key, required this.isLoading, this.onPressed});

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
            : const Text('Daftar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
  const _TombolGoogle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Image.asset('assets/img/google.jpg', width: 24, height: 24),
        label: const Text('Daftar dengan Google', style: TextStyle(color: Colors.black87)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _BagianMasuk extends StatelessWidget {
  const _BagianMasuk({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Sudah punya akun? '),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Masuk', style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
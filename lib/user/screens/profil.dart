import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../supabase/auth_service.dart';
import '../templates/header.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Profil', showBack: false),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            // Panggil fungsi logout dari AuthService
            await AuthService().logout();
            
            if (context.mounted) {
              // Arahkan ke /login dan hapus riwayat halaman sebelumnya agar tidak bisa di-back
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          label: const Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'login.dart';

// ==========================================
// 1. CLASS UTAMA
// ==========================================
class PerizinanPage extends StatelessWidget {
  const PerizinanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _IkonLokasi(),
              const SizedBox(height: 32),
              const _JudulPerizinan(),
              const SizedBox(height: 16),
              const _DeskripsiPerizinan(),
              const SizedBox(height: 48),
              const _TombolIzinkan(),
              const SizedBox(height: 16),
              const _TombolNanti(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. WIDGET-WIDGET PENDUKUNG (DI FILE YANG SAMA)
// ==========================================

class _IkonLokasi extends StatelessWidget {
  const _IkonLokasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on_rounded,
      size: 100,
      color: Color(0xFF0D6EFD),
    );
  }
}

class _JudulPerizinan extends StatelessWidget {
  const _JudulPerizinan({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Izinkan Akses Lokasi',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _DeskripsiPerizinan extends StatelessWidget {
  const _DeskripsiPerizinan({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'BusGuide membutuhkan akses lokasi Anda untuk menemukan halte terdekat dan memberikan navigasi yang akurat.',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _TombolIzinkan extends StatelessWidget {
  const _TombolIzinkan({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implementasi logika meminta izin lokasi (contoh: permission_handler)
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D6EFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Izinkan Lokasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TombolNanti extends StatelessWidget {
  const _TombolNanti({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      child: const Text(
        'Nanti Saja',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }
}
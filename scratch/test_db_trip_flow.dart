import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;
  final email = 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'TestPassword123!';

  try {
    print('Registering test user: $email');
    final signUpRes = await client.auth.signUp(email: email, password: password);
    final userId = signUpRes.user?.id;
    if (userId == null) {
      print('Sign up failed: User ID is null');
      exit(1);
    }
    print('User registered with ID: $userId');

    // Create profile manually since db trigger might be async or missing in local env
    try {
      await client.from('profiles').insert({
        'id': userId,
        'nama': 'Test User',
        'email': email,
        'role': 'pengguna',
      });
      print('Profile created.');
    } catch (pe) {
      print('Profile insert error (might be okay if trigger exists): $pe');
    }

    print('Starting a new journey...');
    final tripRes = await client.from('perjalanan').insert({
      'id_pengguna': userId,
      'status': 'aktif',
      'alarm_aktif': true,
    }).select().single();
    final tripId = tripRes['id'] as int;
    print('Journey started with ID: $tripId');

    print('Completing journey (updating status in perjalanan)...');
    final updateRes = await client.from('perjalanan').update({
      'status': 'selesai',
      'waktu_selesai': DateTime.now().toIso8601String(),
      'alarm_aktif': false,
    }).eq('id', tripId).select();
    print('Journey status update response: $updateRes');

    print('Inserting history into riwayat_perjalanan...');
    try {
      final historyRes = await client.from('riwayat_perjalanan').insert({
        'id_perjalanan': tripId,
        'durasi_menit': 1,
        'estimasi_biaya': null,
        'catatan': 'Test Perjalanan diselesaikan.',
      }).select();
      print('riwayat_perjalanan insert success: $historyRes');
    } catch (he) {
      print('riwayat_perjalanan insert FAILED with error: $he');
    }

  } catch (e) {
    print('General error: $e');
  } finally {
    exit(0);
  }
}

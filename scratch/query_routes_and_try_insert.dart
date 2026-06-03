import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  print('Querying all routes...');
  try {
    final routes = await client.from('rute').select('id, kode, nama');
    print('Routes in database:');
    for (var r in routes) {
      print(' - ID: ${r['id']}, Kode: ${r['kode']}, Nama: ${r['nama']}');
    }

    if (routes.isNotEmpty) {
      print('\nAttempting to insert test jadwal...');
      // Try to insert schedules for the first route
      final firstRouteId = routes.first['id'];
      
      // Let's check if we can insert a schedule
      final newJadwal = {
        'id_rute': firstRouteId,
        'id_bus': 1, // Let's hope there is a bus ID 1 or we can omit it if nullable, let's see. Let's try id_bus: 1 first.
        'hari': 'Setiap Hari',
        'jam_berangkat': '08:00',
        'tarif': 10000,
      };

      final response = await client.from('jadwal').insert(newJadwal).select();
      print('Insert response: $response');
    }
  } catch (e) {
    print('Error during test: $e');
  }

  exit(0);
}

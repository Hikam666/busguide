import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  // Try selecting various column names to see if they exist
  final columnsToTest = [
    'id, id_rute, id_bus, hari, jam_berangkat',
    'id, id_rute, id_bus, hari, jam_berangkat, tarif',
    'id, id_rute, id_bus, hari, jam_berangkat, harga_tiket',
    'id, id_rute, id_bus, hari, jam_berangkat, biaya',
  ];

  for (final cols in columnsToTest) {
    print('Testing query with columns: $cols');
    try {
      final res = await client.from('jadwal').select(cols).limit(1);
      print('SUCCESS! Response: $res');
    } catch (e) {
      print('FAILED! Error: $e');
    }
    print('-----------------------------------------');
  }

  exit(0);
}

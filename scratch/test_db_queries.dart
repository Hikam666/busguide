import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  print('Querying riwayat_perjalanan...');
  try {
    final response = await client.from('riwayat_perjalanan').select().limit(5);
    print('riwayat_perjalanan response: $response');
  } catch (e) {
    print('riwayat_perjalanan error: $e');
  }

  print('Querying perjalanan...');
  try {
    final response = await client.from('perjalanan').select().limit(5);
    print('perjalanan response: $response');
  } catch (e) {
    print('perjalanan error: $e');
  }

  print('Querying jadwal...');
  try {
    final response = await client.from('jadwal').select().limit(5);
    print('jadwal response: $response');
  } catch (e) {
    print('jadwal error: $e');
  }

  print('Finished queries. Exiting.');
  exit(0);
}

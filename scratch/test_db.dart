import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  print('Querying jadwal...');
  try {
    final response = await client.from('jadwal').select().limit(5);
    print('jadwal response: $response');
  } catch (e) {
    print('jadwal error: $e');
  }

  print('Querying rute_halte...');
  try {
    final response = await client.from('rute_halte').select('id_rute, id_halte, urutan').limit(5);
    print('rute_halte response: $response');
  } catch (e) {
    print('rute_halte error: $e');
  }

  print('Querying jadwal_keberangkatan...');
  try {
    final response = await client.from('jadwal_keberangkatan').select().limit(5);
    print('jadwal_keberangkatan response: $response');
  } catch (e) {
    print('jadwal_keberangkatan error: $e');
  }

  print('Querying keberangkatan...');
  try {
    final response = await client.from('keberangkatan').select().limit(5);
    print('keberangkatan response: $response');
  } catch (e) {
    print('keberangkatan error: $e');
  }

  print('Done.');
}

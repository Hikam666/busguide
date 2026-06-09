import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  print('Querying notifikasi...');
  try {
    // Attempting query using anon client
    final response = await client.from('notifikasi').select();
    print('Found ${response.length} notification(s):');
    for (var row in response) {
      print('Notification: $row');
    }
  } catch (e) {
    print('Error querying notifikasi: $e');
  }

  print('Finished queries. Exiting.');
  exit(0);
}

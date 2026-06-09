import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
    anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
  );

  final client = Supabase.instance.client;

  print('Subscribing to notifikasi table inserts...');
  final channel = client.channel('public:notifikasi');
  
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'notifikasi',
    callback: (payload) {
      print('REALTIME INSERT DETECTED: ${payload.newRecord}');
    },
  ).subscribe((status, [error]) {
    print('Subscription status: $status');
    if (error != null) {
      print('Subscription error: $error');
    }
  });

  print('Waiting 15 seconds for realtime events... Try inserting a notification now!');
  await Future.delayed(const Duration(seconds: 15));
  
  print('Exiting.');
  exit(0);
}

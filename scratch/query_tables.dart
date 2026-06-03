import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $apikey',
  };

  final tables = [
    'jadwal',
    'keberangkatan',
    'jadwal_keberangkatan',
    'schedule',
    'departure',
    'halte_keberangkatan',
    'rute_keberangkatan',
    'bus_schedule'
  ];

  for (final table in tables) {
    print('Querying $table...');
    try {
      final res = await http.get(Uri.parse('$url/$table?limit=5'), headers: headers);
      print('$table status: ${res.statusCode}');
      print('$table body: ${res.body}');
      print('-----------------------------------------');
    } catch (e) {
      print('$table error: $e');
    }
  }
}

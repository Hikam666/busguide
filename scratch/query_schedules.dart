import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1/jadwal';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Content-Type': 'application/json',
  };

  print('Querying all rows in the jadwal table...');
  try {
    final res = await http.get(Uri.parse('$url?select=*'), headers: headers);
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

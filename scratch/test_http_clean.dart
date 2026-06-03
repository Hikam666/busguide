import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Content-Type': 'application/json',
  };

  print('Querying rute with apikey header only...');
  try {
    final res = await http.get(Uri.parse('$url/rute?select=*'), headers: headers);
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nQuerying halte with apikey header only...');
  try {
    final res = await http.get(Uri.parse('$url/halte?select=*'), headers: headers);
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

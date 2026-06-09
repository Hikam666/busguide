import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1/rute';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Content-Type': 'application/json',
  };

  try {
    final res = await http.get(Uri.parse('$url?select=*'), headers: headers);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      print('Route data rows:');
      for (var row in data) {
        print(json.encode(row));
      }
    } else {
      print('Body: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

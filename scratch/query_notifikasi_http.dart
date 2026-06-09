import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  print('Querying notifikasi where id_pengguna is null...');
  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $apikey',
    'Content-Type': 'application/json',
  };

  try {
    final res = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/notifikasi?id_pengguna=is.null'),
      headers: headers,
    );
    print('Status Code: ${res.statusCode}');
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      print('Found ${list.length} notifications where id_pengguna is null:');
      for (var row in list) {
        print('Row: $row');
      }
    } else {
      print('Error Body: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}

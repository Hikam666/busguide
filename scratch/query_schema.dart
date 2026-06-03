import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1/';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Content-Type': 'application/json',
  };

  print('Querying OpenAPI schema from Supabase REST endpoint...');
  try {
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) {
      final schema = jsonDecode(res.body);
      final definitions = schema['definitions'] as Map<String, dynamic>;
      
      print('\nAvailable tables in schema:');
      definitions.keys.forEach((k) => print(' - $k'));

      if (definitions.containsKey('rute')) {
        print('\n--- rute columns ---');
        final ruteProps = definitions['rute']['properties'] as Map<String, dynamic>;
        ruteProps.forEach((name, val) {
          print('  $name: ${val['type']} (${val['description'] ?? 'no desc'})');
        });
      }

      if (definitions.containsKey('jadwal')) {
        print('\n--- jadwal columns ---');
        final jadwalProps = definitions['jadwal']['properties'] as Map<String, dynamic>;
        jadwalProps.forEach((name, val) {
          print('  $name: ${val['type']} (${val['description'] ?? 'no desc'})');
        });
      }
    } else {
      print('Failed: ${res.statusCode} - ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

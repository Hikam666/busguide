import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1/';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $apikey',
  };

  try {
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final definitions = data['definitions'] as Map<String, dynamic>;
      print('Tables found in Supabase schema:');
      for (final tableName in definitions.keys) {
        print('- $tableName');
        final properties = definitions[tableName]['properties'] as Map<String, dynamic>;
        print('  Columns:');
        for (final col in properties.keys) {
          final type = properties[col]['type'];
          final format = properties[col]['format'];
          print('    * $col ($type, $format)');
        }
      }
    } else {
      print('Status: ${res.statusCode}');
      print('Body: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

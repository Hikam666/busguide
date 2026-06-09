import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final email = 'rute_inspector_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'TestPassword123!';

  print('1. Registering temp user...');
  final signUpRes = await http.post(
    Uri.parse('$supabaseUrl/auth/v1/signup'),
    headers: {
      'apikey': apikey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (signUpRes.statusCode != 200 && signUpRes.statusCode != 201) {
    print('Failed to register: ${signUpRes.body}');
    return;
  }

  final signUpData = jsonDecode(signUpRes.body);
  final token = signUpData['access_token'];

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  print('2. Querying raw rute rows...');
  try {
    final res = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/rute?select=*'),
      headers: headers,
    );
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      print('Found ${list.length} routes:');
      for (var r in list) {
        print(jsonEncode(r));
      }
    } else {
      print('Query failed: ${res.body}');
    }
  } catch (e) {
    print('Query error: $e');
  }
  exit(0);
}

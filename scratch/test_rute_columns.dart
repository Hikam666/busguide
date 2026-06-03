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

  final columnsToTest = [
    'id,kode,nama,terminal_awal,terminal_akhir',
    'id,kode,nama,id_terminal_awal,id_terminal_akhir',
    'id,kode,nama,terminal_awal_id,terminal_akhir_id',
    'id,kode,nama,status_operasi',
  ];

  for (final cols in columnsToTest) {
    print('Testing columns: $cols');
    try {
      final res = await http.get(Uri.parse('$url?select=$cols&limit=0'), headers: headers);
      print('Status: ${res.statusCode}');
      print('Body: ${res.body}');
    } catch (e) {
      print('Error: $e');
    }
    print('-----------------------------------------');
  }

  exit(0);
}

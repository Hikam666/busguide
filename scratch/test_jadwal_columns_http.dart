import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1/jadwal';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $apikey',
  };

  final columnsToTest = [
    'id,id_rute,id_bus,hari,jam_berangkat',
    'id,id_rute,id_bus,hari,jam_berangkat,tarif',
    'id,id_rute,id_bus,hari,jam_berangkat,harga_tiket',
    'id,id_rute,id_bus,hari,jam_berangkat,biaya',
  ];

  for (final cols in columnsToTest) {
    print('Testing query with columns: $cols');
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

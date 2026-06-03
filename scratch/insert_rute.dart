import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const url = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co/rest/v1';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final headers = {
    'apikey': apikey,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  print('Attempting to insert routes into rute table...');
  final testRoutes = [
    {
      'kode': 'AL',
      'nama': 'Terminal Arjosari - Landungsari',
      'terminal_awal': 1,
      'terminal_akhir': 2,
    },
    {
      'kode': 'LD',
      'nama': 'Terminal Landungsari - Dinoyo',
      'terminal_awal': 2,
      'terminal_akhir': 11,
    },
    {
      'kode': 'AB',
      'nama': 'Terminal Arjosari - Batu',
      'terminal_awal': 1,
      'terminal_akhir': 4,
    }
  ];

  try {
    final res = await http.post(
      Uri.parse('$url/rute'),
      headers: headers,
      body: jsonEncode(testRoutes),
    );
    print('Rute insert status: ${res.statusCode}');
    print('Rute insert body: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final insertedRoutes = jsonDecode(res.body) as List;
      print('Successfully inserted ${insertedRoutes.length} routes!');
      
      // Let's seed rute_halte mapping
      final List<Map<String, dynamic>> ruteHalteList = [];
      for (var r in insertedRoutes) {
        final ruteId = r['id'];
        final startHalt = r['terminal_awal'];
        final endHalt = r['terminal_akhir'];
        
        // Add start halt (urutan 1)
        ruteHalteList.add({
          'id_rute': ruteId,
          'id_halte': startHalt,
          'urutan': 1,
          'jarak_meter': 0,
        });

        // Add end halt (urutan 2)
        ruteHalteList.add({
          'id_rute': ruteId,
          'id_halte': endHalt,
          'urutan': 2,
          'jarak_meter': 5000,
        });
      }

      print('Attempting to insert rute_halte mapping...');
      final rhRes = await http.post(
        Uri.parse('$url/rute_halte'),
        headers: headers,
        body: jsonEncode(ruteHalteList),
      );
      print('rute_halte insert status: ${rhRes.statusCode}');
      print('rute_halte insert body: ${rhRes.body}');
    }
  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

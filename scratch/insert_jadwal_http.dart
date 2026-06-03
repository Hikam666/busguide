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

  print('Querying routes from database...');
  try {
    final routesRes = await http.get(Uri.parse('$url/rute?select=id,kode,nama'), headers: headers);
    if (routesRes.statusCode != 200) {
      print('Failed to get routes: ${routesRes.statusCode} - ${routesRes.body}');
      exit(1);
    }
    final routes = jsonDecode(routesRes.body) as List;
    print('Found ${routes.length} routes:');
    for (var r in routes) {
      print(' - ID: ${r['id']}, Kode: ${r['kode']}, Nama: ${r['nama']}');
    }

    if (routes.isEmpty) {
      print('No routes to seed.');
      exit(0);
    }

    print('\nChecking existing schedules...');
    final checkJadwalRes = await http.get(Uri.parse('$url/jadwal?select=id'), headers: headers);
    print('Schedules status: ${checkJadwalRes.statusCode}');
    print('Schedules body: ${checkJadwalRes.body}');
    
    final existingSchedules = jsonDecode(checkJadwalRes.body) as List;
    if (existingSchedules.isNotEmpty) {
      print('Jadwal table already has ${existingSchedules.length} rows. Seeding skipped.');
      exit(0);
    }

    print('\nSeeding schedules into jadwal table...');
    final List<Map<String, dynamic>> schedulesToSeed = [];

    // Let's seed departures throughout the day:
    final List<String> times = [
      '07:00', '08:30', '10:00', '11:30', '13:00',
      '14:30', '16:00', '17:30', '19:00', '20:30'
    ];

    for (var r in routes) {
      final routeId = r['id'];
      final routeName = (r['nama'] as String).toLowerCase();
      final isEkonomi = routeName.contains('ekonomi') || routeId % 2 == 1;
      final tarif = isEkonomi ? 10000 : 15000;

      for (var t in times) {
        schedulesToSeed.add({
          'id_rute': routeId,
          'id_bus': 1, // fallback id_bus
          'hari': 'Setiap Hari',
          'jam_berangkat': t,
          'tarif': tarif,
        });
      }
    }

    print('Sending ${schedulesToSeed.length} insert records...');
    final insertRes = await http.post(
      Uri.parse('$url/jadwal'),
      headers: headers,
      body: jsonEncode(schedulesToSeed),
    );

    print('Insert status: ${insertRes.statusCode}');
    print('Insert body: ${insertRes.body}');

  } catch (e) {
    print('Error: $e');
  }

  exit(0);
}

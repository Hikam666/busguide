import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect Database Tables Unauthenticated', () async {
    print('Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
      anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
    );

    final client = Supabase.instance.client;

    try {
      print('=== GETTING ALL ROUTES ===');
      final routes = await client.from('rute').select('id, kode, nama');
      print('Found ${routes.length} routes:');
      for (var r in routes) {
        print('Route ID: ${r['id']}, Kode: ${r['kode']}, Nama: ${r['nama']}');
        
        final halts = await client.from('rute_halte')
            .select('urutan, halte(id, nama, latitude, longitude)')
            .eq('id_rute', r['id'])
            .order('urutan');
        
        print('  Halts count: ${halts.length}');
        for (var rh in halts) {
          final h = rh['halte'];
          print('    Urutan: ${rh['urutan']}, ID: ${h['id']}, Nama: ${h['nama']}, Lat: ${h['latitude']}, Lng: ${h['longitude']}');
        }

        final points = await client.from('titik_rute')
            .select('urutan, latitude, longitude')
            .eq('id_rute', r['id'])
            .order('urutan');
        
        print('  titik_rute points count: ${points.length}');
        if (points.isNotEmpty) {
          print('    First: ${points.first}');
          print('    Last: ${points.last}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}

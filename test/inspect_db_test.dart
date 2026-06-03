import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect Database Tables', () async {
    await Supabase.initialize(
      url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
      anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    final client = Supabase.instance.client;
    final tables = ['rute', 'halte', 'profiles', 'perjalanan', 'riwayat_perjalanan', 'jadwal', 'titik_rute'];

    for (var table in tables) {
      try {
        final res = await client.from(table).select().limit(5);
        print('Table: $table, Count queried: ${res.length}');
        if (res.isNotEmpty) {
          print('Sample Row: ${res.first}');
        }
      } catch (e) {
        print('Table: $table, Error: $e');
      }
    }
  });
}

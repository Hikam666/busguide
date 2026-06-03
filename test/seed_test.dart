import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getItem({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Seed Jadwal Table Authenticated', () async {
    print('Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://bgvwhsbpoxgkmrcygpvg.supabase.co',
      anonKey: 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: MockGotrueAsyncStorage(),
      ),
    );

    final client = Supabase.instance.client;

    final email = 'test_seeder_admin_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const password = 'TestSeederPassword123!';

    print('Authenticating...');
    try {
      final signUpRes = await client.auth.signUp(
        email: email,
        password: password,
      );
      print('Authenticated as new user: ${signUpRes.user?.id}');
    } catch (e) {
      print('Auth failed: $e');
      return;
    }

    print('Querying all routes...');
    try {
      final routes = await client.from('rute').select('id, kode, nama');
      print('Routes in database: ${routes.length}');
      for (var r in routes) {
        print(' - ID: ${r['id']}, Kode: ${r['kode']}, Nama: ${r['nama']}');
      }

      if (routes.isEmpty) {
        print('No routes found.');
        return;
      }

      print('Checking existing schedules...');
      final existing = await client.from('jadwal').select('id');
      print('Existing schedules count: ${existing.length}');
      
      if (existing.isNotEmpty) {
        print('Jadwal table already seeded.');
        return;
      }

      print('Seeding schedules into jadwal table...');
      final List<Map<String, dynamic>> schedulesToSeed = [];
      
      // Let's seed 10 departures throughout the day for each route
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
            'id_bus': 1,
            'hari': 'Setiap Hari',
            'jam_berangkat': t,
            'tarif': tarif,
          });
        }
      }

      print('Inserting ${schedulesToSeed.length} schedule rows...');
      final insertRes = await client.from('jadwal').insert(schedulesToSeed).select();
      print('Inserted schedules successfully: ${insertRes.length} rows.');
    } catch (e) {
      print('Error during seeding: $e');
    }
  });
}

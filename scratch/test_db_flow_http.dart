import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final email = 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'TestPassword123!';

  print('1. Registering test user via HTTP: $email');
  try {
    final signupRes = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
      headers: {
        'apikey': apikey,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (signupRes.statusCode != 200) {
      print('Signup failed: ${signupRes.statusCode} - ${signupRes.body}');
      exit(1);
    }

    final signupData = json.decode(signupRes.body);
    final accessToken = signupData['access_token'];
    final userId = signupData['user']['id'];
    print('Signup success. User ID: $userId');

    final authHeaders = {
      'apikey': apikey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };

    // Create profile
    print('2. Creating profile...');
    final profileRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/profiles'),
      headers: authHeaders,
      body: json.encode({
        'id': userId,
        'nama': 'Test User',
        'email': email,
        'role': 'pengguna',
      }),
    );
    print('Profile response: ${profileRes.statusCode} - ${profileRes.body}');

    // Start Journey
    print('3. Starting active journey in perjalanan...');
    final startRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/perjalanan'),
      headers: authHeaders,
      body: json.encode({
        'id_pengguna': userId,
        'status': 'aktif',
        'alarm_aktif': true,
      }),
    );

    if (startRes.statusCode != 201 && startRes.statusCode != 200) {
      print('Failed to start journey: ${startRes.statusCode} - ${startRes.body}');
      exit(1);
    }

    final journeyList = json.decode(startRes.body) as List;
    if (journeyList.isEmpty) {
      print('No journey data returned');
      exit(1);
    }
    final journeyId = journeyList[0]['id'];
    print('Journey started. ID: $journeyId');

    // Complete Journey
    print('4. Completing journey in perjalanan...');
    final completeRes = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/perjalanan?id=eq.$journeyId'),
      headers: authHeaders,
      body: json.encode({
        'status': 'selesai',
        'waktu_selesai': DateTime.now().toIso8601String(),
        'alarm_aktif': false,
      }),
    );
    print('Journey completion response: ${completeRes.statusCode} - ${completeRes.body}');

    // Insert history
    print('5. Inserting history into riwayat_perjalanan...');
    final historyRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/riwayat_perjalanan'),
      headers: authHeaders,
      body: json.encode({
        'id_perjalanan': journeyId,
        'durasi_menit': 1,
        'estimasi_biaya': null,
        'catatan': 'Perjalanan diselesaikan.',
      }),
    );
    print('riwayat_perjalanan response: ${historyRes.statusCode} - ${historyRes.body}');

  } catch (e) {
    print('Error: $e');
  } finally {
    exit(0);
  }
}

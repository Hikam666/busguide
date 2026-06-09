import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final email = 'notifuser_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'TestPassword123!';

  print('1. Registering user...');
  final signUpRes = await http.post(
    Uri.parse('$supabaseUrl/auth/v1/signup'),
    headers: {
      'apikey': apikey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
      'data': {'nama': 'Notif Tester'},
    }),
  );

  if (signUpRes.statusCode != 200 && signUpRes.statusCode != 201) {
    print('Failed to register: ${signUpRes.body}');
    return;
  }

  final signUpData = jsonDecode(signUpRes.body);
  final userId = signUpData['id'] ?? signUpData['user']?['id'];
  final token = signUpData['access_token'];
  print('User registered successfully with ID: $userId');

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // Wait a moment for profiles trigger to run
  await Future.delayed(const Duration(seconds: 1));

  print('2. Creating active journey...');
  int? tripId;
  try {
    final tripRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/perjalanan'),
      headers: headers,
      body: jsonEncode({
        'id_pengguna': userId,
        'status': 'aktif',
        'alarm_aktif': true,
      }),
    );
    if (tripRes.statusCode == 201 || tripRes.statusCode == 200) {
      final tripData = jsonDecode(tripRes.body);
      tripId = (tripData is List) ? tripData[0]['id'] : tripData['id'];
      print('Journey started with ID: $tripId');
    } else {
      print('Journey insert failed: ${tripRes.body}');
    }
  } catch (e) {
    print('Journey error: $e');
  }

  if (tripId == null) return;

  print('3. Updating journey to selesai...');
  try {
    final updateRes = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/perjalanan?id=eq.$tripId'),
      headers: headers,
      body: jsonEncode({
        'status': 'selesai',
        'waktu_selesai': DateTime.now().toIso8601String(),
        'alarm_aktif': false,
      }),
    );
    print('Update status: ${updateRes.statusCode}');
  } catch (e) {
    print('Update error: $e');
  }

  print('4. Inserting into riwayat_perjalanan...');
  try {
    final historyRes = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/riwayat_perjalanan'),
      headers: headers,
      body: jsonEncode({
        'id_perjalanan': tripId,
        'durasi_menit': 15,
        'catatan': 'Perjalanan diselesaikan.',
      }),
    );
    print('History insert status: ${historyRes.statusCode}');
  } catch (e) {
    print('History error: $e');
  }

  print('5. Waiting 2 seconds for database triggers to execute...');
  await Future.delayed(const Duration(seconds: 2));

  print('6. Querying notifications from notifikasi table...');
  try {
    final queryRes = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/notifikasi?select=*'),
      headers: headers,
    );
    if (queryRes.statusCode == 200) {
      final List<dynamic> notifs = jsonDecode(queryRes.body);
      print('Found ${notifs.length} notifications:');
      for (var n in notifs) {
        print(' - ID: ${n['id']}, Judul: ${n['judul']}, Pesan: ${n['pesan']}, Status Baca: ${n['status_baca']}, Tipe: ${n['tipe']}');
      }
    } else {
      print('Query failed: ${queryRes.body}');
    }
  } catch (e) {
    print('Query error: $e');
  }
}

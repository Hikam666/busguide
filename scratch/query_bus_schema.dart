import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  const apikey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  final email = 'bus_q_${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'TestPassword123!';

  final signUpRes = await http.post(
    Uri.parse('$supabaseUrl/auth/v1/signup'),
    headers: {'apikey': apikey, 'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (signUpRes.statusCode != 200 && signUpRes.statusCode != 201) {
    print('Failed: ${signUpRes.body}');
    return;
  }
  final token = jsonDecode(signUpRes.body)['access_token'];
  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // 1. Query jadwal for route 7 (MK-1) with bus join
  print('--- Jadwal route 7 (MK-1) with bus+po join ---');
  var res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/jadwal?select=id,id_rute,jam_berangkat,tarif,hari,estimasi_menit,bus:id_bus(id,nomor_polisi,tipe,nama_bus,po_bus:id_po(id,nama))&id_rute=eq.7&order=jam_berangkat'),
    headers: headers,
  );
  print('Status: ${res.statusCode}');
  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List;
    print('Found ${list.length} schedules:');
    for (var j in list) print(jsonEncode(j));
  } else {
    print('Error: ${res.body}');
  }

  // 2. Query jadwal for route 10 (MH-1) with bus join
  print('\n--- Jadwal route 10 (MH-1) with bus+po join ---');
  res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/jadwal?select=id,id_rute,jam_berangkat,tarif,hari,estimasi_menit,bus:id_bus(id,nomor_polisi,tipe,nama_bus,po_bus:id_po(id,nama))&id_rute=eq.10&order=jam_berangkat'),
    headers: headers,
  );
  print('Status: ${res.statusCode}');
  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List;
    print('Found ${list.length} schedules:');
    for (var j in list) print(jsonEncode(j));
  } else {
    print('Error: ${res.body}');
  }

  // 3. Query jadwal for route 4 (AB-1) with bus join
  print('\n--- Jadwal route 4 (AB-1) with bus+po join ---');
  res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/jadwal?select=id,id_rute,jam_berangkat,tarif,hari,estimasi_menit,bus:id_bus(id,nomor_polisi,tipe,nama_bus,po_bus:id_po(id,nama))&id_rute=eq.4&order=jam_berangkat'),
    headers: headers,
  );
  print('Status: ${res.statusCode}');
  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List;
    print('Found ${list.length} schedules:');
    for (var j in list) print(jsonEncode(j));
  } else {
    print('Error: ${res.body}');
  }

  exit(0);
}

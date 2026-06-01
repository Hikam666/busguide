import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_config.dart';

class ApiClient {
  static const String _baseUrl = SupabaseConfig.supabaseUrl;
  static const String _anonKey = SupabaseConfig.supabaseAnonKey;

  /// Mengembalikan header standar yang dibutuhkan Supabase REST API
  static Map<String, String> _getHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    
    return {
      'apikey': _anonKey,
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Melakukan HTTP GET ke Supabase REST API
  /// [table] adalah nama tabel (misal: 'wisata')
  /// [query] adalah query parameter (misal: 'select=*&limit=5')
  static Future<List<dynamic>> get({
    required String table,
    String? query,
  }) async {
    final urlString = '$_baseUrl/rest/v1/$table${query != null ? '?$query' : ''}';
    final url = Uri.parse(urlString);

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Decode data JSON (array)
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('HTTP GET Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Melakukan HTTP POST ke Supabase REST API
  static Future<Map<String, dynamic>?> post({
    required String table,
    required Map<String, dynamic> body,
    bool returnMinimal = false,
  }) async {
    final url = Uri.parse('$_baseUrl/rest/v1/$table');
    final headers = _getHeaders();
    
    // Header prefer: return=representation agar Supabase me-return record yang baru saja dibuat
    if (!returnMinimal) {
      headers['Prefer'] = 'return=representation';
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first as Map<String, dynamic>;
        }
        return decoded as Map<String, dynamic>?;
      }
      return null;
    } else {
      throw Exception('HTTP POST Error ${response.statusCode}: ${response.body}');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://bgvwhsbpoxgkmrcygpvg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_EbGKB6w1l0VoiVH8FSz93w_dBnggZw7';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static final client = Supabase.instance.client;
}
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Getter sederhana untuk mengambil instance global
  static SupabaseClient get instance => Supabase.instance.client;
}
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = 'https://fdvxklhxluajzyvvtxwt.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdnhrbGh4bHVhanp5dnZ0eHd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUzNDksImV4cCI6MjA3OTc0MTM0OX0.hs4qM0bcixcXf347QkNG0ji96FpBySt4iZFLvKqNSDA';
  
  static late final SupabaseClient client;
  
  static Future<void> initialize() async {
    client = SupabaseClient(_url, _anonKey);
  }
  
  static SupabaseClient get instance => client;
}
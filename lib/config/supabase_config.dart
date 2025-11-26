import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = 'https://qoevzthqdwizvnxfcnic.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFvZXZ6dGhxZHdpenZueGZjbmljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjI2NTIsImV4cCI6MjA3OTczODY1Mn0.4JuVYl8WmxiMr_l125927jFg4nkG1PpfnxPEsBM-jvQ';
  
  static late final SupabaseClient client;
  
  static Future<void> initialize() async {
    client = SupabaseClient(_url, _anonKey);
  }
  
  static SupabaseClient get instance => client;
}
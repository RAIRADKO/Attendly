import 'package:supabase_flutter/supabase_flutter.dart' hide User; // [Ubah baris ini]
import '../config/supabase_config.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.instance;

  Future<User?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', session.user.id)
        .single();

    return User.fromJson(response);
  }

  Future<bool> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      throw Exception('Login gagal: ${e.toString()}');
    }
  }

  Future<bool> logout() async {
    try {
      await _client.auth.signOut();
      return true;
    } catch (e) {
      throw Exception('Logout gagal: ${e.toString()}');
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      throw Exception('Reset password gagal: ${e.toString()}');
    }
  }
}
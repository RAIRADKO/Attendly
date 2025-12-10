import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/supabase_config.dart';
import '../models/user.dart';
import '../utils/app_exception.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.instance;

  /// PERBAIKAN: Get current user dengan error handling yang lebih baik
  Future<User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        print('[AUTH] No active session');
        return null;
      }

      print('[AUTH] Fetching user data for: ${session.user.id}');
      
      final response = await _client
          .from('users')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (response == null) {
        print('[AUTH] User not found in database');
        return null;
      }

      return User.fromJson(response);
    } catch (e) {
      print('[AUTH ERROR] Failed to get current user: $e');
      // Jangan throw error, return null saja agar tidak crash
      return null;
    }
  }

  /// PERBAIKAN: Login dengan validasi dan error handling yang lebih baik
  Future<bool> login(String email, String password) async {
    try {
      // Validasi input
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();

      if (normalizedEmail.isEmpty) {
        throw AppException('Email tidak boleh kosong');
      }

      if (normalizedPassword.isEmpty) {
        throw AppException('Password tidak boleh kosong');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalizedEmail)) {
        throw AppException('Format email tidak valid');
      }

      if (normalizedPassword.length < 6) {
        throw AppException('Password minimal 6 karakter');
      }

      print('[AUTH] Attempting login for: $normalizedEmail');

      // Login ke Supabase
      final response = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );

      if (response.session == null) {
        throw AppException('Login gagal. Session tidak dibuat.');
      }

      print('[AUTH] ✓ Login successful for: ${response.user.email}');
      return true;
    } on AuthException catch (e) {
      print('[AUTH ERROR] AuthException: ${e.message}');
      throw AppException.fromSupabase(e);
    } on AppException {
      rethrow;
    } catch (e) {
      print('[AUTH ERROR] Unexpected error: $e');
      throw AppException('Terjadi kesalahan saat login. Silakan coba lagi.');
    }
  }

  /// PERBAIKAN: Logout dengan error handling
  Future<bool> logout() async {
    try {
      print('[AUTH] Logging out...');
      await _client.auth.signOut();
      print('[AUTH] ✓ Logout successful');
      return true;
    } on AuthException catch (e) {
      print('[AUTH ERROR] Logout failed: ${e.message}');
      throw AppException.fromSupabase(e);
    } catch (e) {
      print('[AUTH ERROR] Logout error: $e');
      throw AppException('Terjadi kesalahan saat logout. Silakan coba lagi.');
    }
  }

  /// PERBAIKAN: Forgot password dengan validasi dan error handling
  Future<bool> forgotPassword(String email) async {
    try {
      // Validasi email
      final normalizedEmail = email.trim().toLowerCase();

      if (normalizedEmail.isEmpty) {
        throw AppException('Email tidak boleh kosong');
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalizedEmail)) {
        throw AppException('Format email tidak valid');
      }

      print('[AUTH] Sending password reset email to: $normalizedEmail');

      await _client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: null, // Bisa disesuaikan jika ada redirect URL
      );

      print('[AUTH] ✓ Password reset email sent');
      return true;
    } on AuthException catch (e) {
      print('[AUTH ERROR] Password reset failed: ${e.message}');
      throw AppException.fromSupabase(e);
    } on AppException {
      rethrow;
    } catch (e) {
      print('[AUTH ERROR] Password reset error: $e');
      throw AppException('Terjadi kesalahan saat mengirim email reset password. Silakan coba lagi.');
    }
  }
}
// lib/utils/app_exception.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;

  factory AppException.fromSupabase(dynamic error) {
    if (error is PostgrestException) {
      return AppException(
        _getReadableMessage(error.code, error.message),
        code: error.code,
        originalError: error,
      );
    }
    
    if (error is AuthException) {
      return AppException(
        _getAuthErrorMessage(error.message),
        code: error.statusCode,
        originalError: error,
      );
    }

    return AppException(
      error.toString(),
      originalError: error,
    );
  }

  static String _getReadableMessage(String? code, String message) {
    switch (code) {
      case '23505': // Unique violation
        return 'Data sudah ada. Silakan gunakan data yang berbeda.';
      case '23503': // Foreign key violation
        return 'Data terkait tidak ditemukan.';
      case 'PGRST116': // No rows found
        return 'Data tidak ditemukan.';
      case 'PGRST301': // Invalid request
        return 'Permintaan tidak valid.';
      default:
        return message.isNotEmpty ? message : 'Terjadi kesalahan pada database';
    }
  }

  static String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum diverifikasi';
    }
    if (message.contains('User already registered')) {
      return 'Email sudah terdaftar';
    }
    return message.isNotEmpty ? message : 'Terjadi kesalahan autentikasi';
  }
}

// Usage example in auth_service.dart:
/*
Future<bool> login(String email, String password) async {
  try {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return true;
  } on AuthException catch (e) {
    throw AppException.fromSupabase(e);
  } catch (e) {
    throw AppException('Login gagal: ${e.toString()}');
  }
}
*/
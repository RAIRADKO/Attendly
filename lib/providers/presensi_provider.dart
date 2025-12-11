import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/mata_kuliah.dart';
import '../models/absensi.dart';
import '../services/otp_service.dart';

class PresensiProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MataKuliah> _mataKuliahList = [];
  List<MataKuliah> get mataKuliahList => _mataKuliahList;

  List<Absensi> _presensiList = [];
  List<Absensi> get presensiList => _presensiList;

  Future<void> fetchMataKuliahAktif(String userId, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      dynamic response;
      
      if (role == 'dosen') {
        response = await _supabase
            .from('mata_kuliah')
            .select()
            .eq('dosen_id', userId);
      } else {
        response = await _supabase
            .from('mata_kuliah')
            .select();
      }

      // FIX: Hapus null check yang tidak perlu
      final List<dynamic> data = response as List<dynamic>;
      _mataKuliahList = data.map((e) => MataKuliah.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching mata kuliah: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRiwayatPresensi(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('absensi')
          .select()
          .eq('mahasiswa_id', userId)
          .order('waktu_presensi', ascending: false);

      // FIX: Hapus null check yang tidak perlu
      final List<dynamic> data = response as List<dynamic>;
      _presensiList = data.map((e) => Absensi.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching riwayat: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPresensi(int mataKuliahId, String inputOtp, double lat, double long) async {
    _isLoading = true;
    notifyListeners();

    try {
      final normalizedOtp = inputOtp.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      if (normalizedOtp.length != 6) {
        throw Exception('OTP harus terdiri dari 6 digit angka.');
      }

      print('[PRESENSI] Submitting presensi...');
      print('[PRESENSI] MK ID: $mataKuliahId, OTP: $normalizedOtp (original: $inputOtp)');
      print('[PRESENSI] Location: ($lat, $long)');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Session kedaluwarsa. Silakan login ulang.');
      }

      final sesiResponse = await _supabase
          .from('absen_sesi')
          .select()
          .eq('mata_kuliah_id', mataKuliahId)
          .eq('status', 'dibuka')
          .order('waktu_mulai', ascending: false)
          .limit(1);

      // FIX: Hapus null check yang tidak perlu
      final List<dynamic> sesiData = sesiResponse as List<dynamic>;
      if (sesiData.isEmpty) {
        throw Exception('Tidak ada sesi presensi yang aktif.');
      }

      final Map<String, dynamic> sesi = sesiData.first as Map<String, dynamic>;
      final int sesiId = sesi['id'] as int;
      final String? secretKeyRaw = sesi['secret_key_otp'] as String?;
      
      if (secretKeyRaw == null || secretKeyRaw.isEmpty) {
        print('[PRESENSI ERROR] Secret key kosong untuk sesi $sesiId');
        throw Exception('Sesi presensi tidak valid. Silakan hubungi dosen.');
      }
      
      final String secretKey = secretKeyRaw.trim();

      print('[PRESENSI] Secret key (OTP): $secretKey');
      print('[PRESENSI] Validating OTP: $normalizedOtp');

      // Validasi OTP sederhana - bandingkan langsung
      final isValidOtp = OtpService.validateOTP(secretKey, normalizedOtp);
      if (!isValidOtp) {
        print('[PRESENSI] OTP validation failed');
        throw Exception('OTP salah. Pastikan kode yang dimasukkan benar.');
      }
      
      print('[PRESENSI] ✓ OTP validated successfully');

      final existing = await _supabase
          .from('absensi')
          .select()
          .eq('sesi_id', sesiId)
          .eq('mahasiswa_id', userId);

      // FIX: Hapus null check yang tidak perlu
      final List<dynamic> existingData = existing as List<dynamic>;
      if (existingData.isNotEmpty) {
        throw Exception('Anda sudah presensi pada sesi ini.');
      }

      await _supabase.from('absensi').insert({
        'sesi_id': sesiId,
        'mahasiswa_id': userId,
        'waktu_presensi': DateTime.now().toIso8601String(),
        'latitude': lat,
        'longitude': long,
        'status': 'hadir',
      });

      _isLoading = false;
      notifyListeners();
      
      print('[PRESENSI] ✓ Success!');
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      print('[PRESENSI] ✗ Error: $e');
      
      String errorMessage = e.toString();
      
      errorMessage = errorMessage
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '')
          .trim();
      
      throw Exception(errorMessage);
    }
  }
}
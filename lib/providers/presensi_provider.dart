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

      if (response != null) {
        final List<dynamic> data = response as List<dynamic>;
        _mataKuliahList = data.map((e) => MataKuliah.fromJson(e)).toList();
      }
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

      if (response != null) {
        final List<dynamic> data = response as List<dynamic>;
        _presensiList = data.map((e) => Absensi.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching riwayat: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PERBAIKAN: Submit presensi dengan validasi OTP di sisi server
  /// Menggunakan RPC function yang aman
  Future<bool> submitPresensi(int mataKuliahId, String inputOtp, double lat, double long) async {
    _isLoading = true;
    notifyListeners();

    try {
      // PERBAIKAN: Normalisasi dan validasi input OTP
      final normalizedOtp = inputOtp.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      if (normalizedOtp.length != 6) {
        throw Exception('OTP harus terdiri dari 6 digit angka.');
      }

      print('[PRESENSI] Submitting presensi...');
      print('[PRESENSI] MK ID: $mataKuliahId, OTP: $normalizedOtp (original: $inputOtp)');
      print('[PRESENSI] Location: ($lat, $long)');

      // Pastikan user terautentikasi
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Session kedaluwarsa. Silakan login ulang.');
      }

      // Ambil sesi presensi yang masih dibuka untuk mata kuliah ini
      final sesiResponse = await _supabase
          .from('absen_sesi')
          .select()
          .eq('mata_kuliah_id', mataKuliahId)
          .eq('status', 'dibuka')
          .order('waktu_mulai', ascending: false)
          .limit(1);

      if (sesiResponse == null || (sesiResponse as List).isEmpty) {
        throw Exception('Tidak ada sesi presensi yang aktif.');
      }

      final List<dynamic> sesiData = sesiResponse as List<dynamic>;
      final Map<String, dynamic> sesi = sesiData.first as Map<String, dynamic>;
      final int sesiId = sesi['id'] as int;
      final String? secretKeyRaw = sesi['secret_key_otp'] as String?;
      
      // PERBAIKAN: Validasi secret key
      if (secretKeyRaw == null || secretKeyRaw.isEmpty) {
        print('[PRESENSI ERROR] Secret key kosong untuk sesi $sesiId');
        throw Exception('Sesi presensi tidak valid. Silakan hubungi dosen.');
      }
      
      final String secretKey = secretKeyRaw.trim();

      print('[PRESENSI] Secret key length: ${secretKey.length}');
      print('[PRESENSI] Validating OTP: $normalizedOtp');

      // Validasi OTP dengan secret key sesi
      final isValidOtp = OtpService.validateOTP(secretKey, normalizedOtp);
      if (!isValidOtp) {
        print('[PRESENSI] OTP validation failed');
        throw Exception('OTP salah atau sudah kedaluwarsa. Pastikan kode yang dimasukkan benar.');
      }
      
      print('[PRESENSI] ✓ OTP validated successfully');

      // Cegah presensi ganda
      final existing = await _supabase
          .from('absensi')
          .select()
          .eq('sesi_id', sesiId)
          .eq('mahasiswa_id', userId);

      if (existing != null && (existing as List).isNotEmpty) {
        throw Exception('Anda sudah presensi pada sesi ini.');
      }

      // Catat presensi
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
      
      // Parse error message untuk ditampilkan ke user
      String errorMessage = e.toString();
      
      // Bersihkan error message dari prefix yang tidak perlu
      errorMessage = errorMessage
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '')
          .trim();
      
      throw Exception(errorMessage);
    }
  }
}
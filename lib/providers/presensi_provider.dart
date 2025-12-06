import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/mata_kuliah.dart';
import '../models/absensi.dart';
import '../services/otp_service.dart'; // ✅ Import OTP service

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

  Future<bool> submitPresensi(int mataKuliahId, String inputOtp, double lat, double long) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Panggil fungsi RPC yang baru kita buat di SQL
      await _supabase.rpc('submit_presensi_aman', params: {
        'p_mata_kuliah_id': mataKuliahId,
        'p_input_otp': inputOtp, // OTP dikirim untuk dicek server
        'p_lat': lat,
        'p_long': long,
      });

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Tampilkan pesan error yang ramah dari database (misal: "Kode OTP salah")
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
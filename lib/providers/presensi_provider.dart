import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart'; 

// [FIX] Import model yang dibutuhkan
import '../models/mata_kuliah.dart';
import '../models/absensi.dart';

class PresensiProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // [FIX] Menambahkan variabel State untuk List Mata Kuliah dan Riwayat
  List<MataKuliah> _mataKuliahList = [];
  List<MataKuliah> get mataKuliahList => _mataKuliahList;

  List<Absensi> _presensiList = [];
  List<Absensi> get presensiList => _presensiList;

  // ---------------------------------------------------------------------------
  // [FIX] Implementasi fetchMataKuliahAktif
  // Mengambil data mata kuliah berdasarkan User ID dan Role
  // ---------------------------------------------------------------------------
  Future<void> fetchMataKuliahAktif(String userId, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Catatan: Query ini diasumsikan standar. Sesuaikan nama tabel 'mata_kuliah'
      // dan relasinya jika struktur database Anda berbeda.
      
      dynamic response;
      
      if (role == 'dosen') {
        // Jika dosen, ambil MK yang diajar oleh dosen tersebut
        response = await _supabase
            .from('mata_kuliah')
            .select()
            .eq('dosen_id', userId);
      } else {
        // Jika mahasiswa, ambil MK yang diambil (misal lewat tabel junction 'krs' atau 'kelas')
        // Untuk saat ini kita ambil semua atau sesuaikan dengan query KRS Anda
        // Contoh sederhana: Mengambil semua mata kuliah (logic perlu disesuaikan dengan DB Anda)
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
      // Opsional: throw e; jika ingin handle error di UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // [FIX] Implementasi fetchRiwayatPresensi
  // Mengambil histori absensi mahasiswa
  // ---------------------------------------------------------------------------
  Future<void> fetchRiwayatPresensi(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mengambil data dari tabel absensi, join dengan sesi/mata_kuliah jika perlu nama MK
      // Asumsi: tabel 'absensi' memiliki kolom yang sesuai dengan model Absensi.fromJson
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

  // ---------------------------------------------------------------------------
  // Logika Submit Presensi (Sudah ada sebelumnya)
  // ---------------------------------------------------------------------------
  Future<bool> submitPresensi(
      int mataKuliahId, String inputOtp, double lat, double long) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User tidak ditemukan");

      // 1. AMBIL SESI TERBUKA
      final responseSesi = await _supabase
          .from("absen_sesi")
          .select("*")
          .eq("mata_kuliah_id", mataKuliahId)
          .eq("status", "dibuka")
          .order("waktu_mulai", ascending: false)
          .limit(1)
          .maybeSingle();

      if (responseSesi == null) {
        throw Exception("Tidak ada sesi aktif");
      }

      final sesiId = responseSesi['id'];
      final secretKey = responseSesi['secret_key_otp'];

      // 2. VALIDASI TOTP
      bool isValidOtp = await _validateCustomTOTP(secretKey, inputOtp);
      
      if (!isValidOtp) {
        throw Exception("OTP tidak valid/kadaluarsa");
      }

      // 3. CEK APAKAH SUDAH PRESENSI
      final cekPresensi = await _supabase
          .from("absensi")
          .select("id")
          .eq("sesi_id", sesiId)
          .eq("mahasiswa_id", user.id)
          .maybeSingle();

      if (cekPresensi != null) {
        throw Exception("Anda sudah presensi untuk sesi ini");
      }

      // 4. INSERT PRESENSI
      await _supabase.from("absensi").insert({
        "sesi_id": sesiId,
        "mahasiswa_id": user.id,
        "waktu_presensi": DateTime.now().toIso8601String(),
        "latitude": lat,
        "longitude": long,
        "status": "hadir",
      });

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Fungsi Helper: TOTP
  Future<bool> _validateCustomTOTP(String secret, String inputOtp) async {
    final currentTime = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final period = 30;
    final currentCounter = (currentTime / period).floor();

    final validPeriods = [
      currentCounter,
      currentCounter - 1,
      currentCounter - 2,
      currentCounter + 1,
    ];

    for (final p in validPeriods) {
      final generated = await _generateHash(secret, p);
      if (generated == inputOtp) {
        return true;
      }
    }
    return false;
  }

  Future<String> _generateHash(String secret, int counter) async {
    List<int> secretBytes = base64Decode(secret);
    final counterList = Uint8List(8);
    final counterView = ByteData.view(counterList.buffer);
    counterView.setUint64(0, counter); 

    final dataToHash = [...secretBytes, ...counterList];
    final digest = sha1.convert(dataToHash).bytes;

    final offset = digest[digest.length - 1] & 0xf;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    return (binary % 1000000).toString().padLeft(6, "0");
  }
}
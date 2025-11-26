import 'package:supabase_flutter/supabase_flutter.dart'; // [Tambahkan ini]
import '../config/supabase_config.dart';
import '../models/mata_kuliah.dart';
import '../models/absen_sesi.dart';
import '../models/absensi.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseConfig.instance;

  Future<List<MataKuliah>> getMataKuliahByDosen(String dosenId) async {
    final response = await _client
        .from('mata_kuliah')
        .select('*, users(nama)')
        .eq('dosen_id', dosenId);

    return (response as List).map((json) => MataKuliah.fromJson({
      'id': json['id'],
      'nama_mk': json['nama_mk'],
      'kode_mk': json['kode_mk'],
      'dosen_id': json['dosen_id'],
      'nama_dosen': json['users'] != null ? json['users']['nama'] : 'Unknown',
    })).toList();
  }

  Future<List<MataKuliah>> getMataKuliahByMahasiswa(String mahasiswaId) async {
    final response = await _client
        .from('mata_kuliah')
        .select('*, users(nama)');

    return (response as List).map((json) => MataKuliah.fromJson({
      'id': json['id'],
      'nama_mk': json['nama_mk'],
      'kode_mk': json['kode_mk'],
      'dosen_id': json['dosen_id'],
      'nama_dosen': json['users'] != null ? json['users']['nama'] : 'Unknown',
    })).toList();
  }

  // PERBAIKAN: Menambahkan parameter secretKey
  Future<AbsenSesi> createSesiPresensi(int mataKuliahId, String dosenId, String secretKey) async {
    final response = await _client
        .from('absen_sesi')
        .insert({
          'mata_kuliah_id': mataKuliahId,
          'dosen_id': dosenId,
          'waktu_mulai': DateTime.now().toIso8601String(),
          'status': 'dibuka',
          'secret_key_otp': secretKey // Menggunakan secretKey yang dinamis
        })
        .select()
        .single();

    return AbsenSesi.fromJson(response);
  }

  Future<void> closeSesiPresensi(int sesiId) async {
    await _client
        .from('absen_sesi')
        .update({'waktu_selesai': DateTime.now().toIso8601String(), 'status': 'ditutup'})
        .eq('id', sesiId);
  }

  Future<List<Absensi>> getPresensiBySesi(int sesiId) async {
    final response = await _client
        .from('absensi')
        .select('*, users(nama)')
        .eq('sesi_id', sesiId);

    return (response as List).map((json) => Absensi.fromJson({
      'id': json['id'],
      'sesi_id': json['sesi_id'],
      'mahasiswa_id': json['mahasiswa_id'],
      'nama_mahasiswa': json['users'] != null ? json['users']['nama'] : 'Unknown',
      'waktu_presensi': json['waktu_presensi'],
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'status': json['status'],
    })).toList();
  }

  Future<List<Absensi>> getRiwayatPresensi(String userId) async {
    final response = await _client
        .from('absensi')
        .select('*, absen_sesi(mata_kuliah(nama_mk))')
        .eq('mahasiswa_id', userId)
        .order('waktu_presensi', ascending: false);

    return (response as List).map((json) => Absensi.fromJson({
      'id': json['id'],
      'sesi_id': json['sesi_id'],
      'mahasiswa_id': json['mahasiswa_id'],
      'nama_mahasiswa': json['absen_sesi']?['mata_kuliah']?['nama_mk'] ?? 'Unknown',
      'waktu_presensi': json['waktu_presensi'],
      'latitude': json['latitude'],
      'longitude': json['longitude'],
      'status': json['status'],
    })).toList();
  }
}
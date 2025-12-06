import 'package:supabase_flutter/supabase_flutter.dart' hide User; // <--- TAMBAHKAN 'hide User'
import '../config/supabase_config.dart';
import '../models/mata_kuliah.dart';
import '../models/absen_sesi.dart';
import '../models/absensi.dart';
import '../models/user.dart'; // Model User Anda sekarang akan digunakan

class DatabaseService {
  final SupabaseClient _client = SupabaseConfig.instance;

  // --- EXISTING METHODS (Biarkan, jangan dihapus) ---

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

  Future<AbsenSesi> createSesiPresensi(int mataKuliahId, String dosenId, String secretKey) async {
    final response = await _client
        .from('absen_sesi')
        .insert({
          'mata_kuliah_id': mataKuliahId,
          'dosen_id': dosenId,
          'waktu_mulai': DateTime.now().toIso8601String(),
          'status': 'dibuka',
          'secret_key_otp': secretKey
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

  // --- FITUR ADMIN & LAPORAN ---

  Future<void> addUser(User user, String password) async {
    final authResponse = await _client.auth.signUp(
      email: user.email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Gagal membuat user Auth');
    }

    final newUserId = authResponse.user!.id;

    await _client.from('users').insert({
      'id': newUserId,
      'email': user.email,
      'nama': user.nama,
      'role': user.role,
      'nim': user.nim,
      'nidn': user.nidn,
    });
  }

  Future<List<User>> getAllDosen() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'dosen');

    return (response as List).map((e) => User.fromJson(e)).toList();
  }

  Future<void> addMataKuliah(String namaMk, String kodeMk, String dosenId) async {
    await _client.from('mata_kuliah').insert({
      'nama_mk': namaMk,
      'kode_mk': kodeMk,
      'dosen_id': dosenId,
    });
  }

  Future<List<Map<String, dynamic>>> getAllPresensiRaw() async {
    final response = await _client
        .from('absensi')
        .select('''
          *,
          users:mahasiswa_id (nama, nim),
          absen_sesi (
            waktu_mulai,
            mata_kuliah (nama_mk, kode_mk)
          )
        ''')
        .order('waktu_presensi', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  // --- [BARU] JADWAL KULIAH ---

  // 5. Ambil Semua Mata Kuliah (Untuk Dropdown Jadwal)
  Future<List<MataKuliah>> getAllMataKuliah() async {
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

  // 6. Tambah Jadwal Kuliah
  Future<void> addJadwal(int mataKuliahId, String hari, String jamMulai, String jamSelesai) async {
    await _client.from('kelas_jadwal').insert({
      'mata_kuliah_id': mataKuliahId,
      'hari': hari,
      'jam_mulai': jamMulai, // Format HH:mm
      'jam_selesai': jamSelesai,
    });
  }
}
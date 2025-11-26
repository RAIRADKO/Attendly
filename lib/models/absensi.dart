class Absensi {
  final int id;
  final int sesiId;
  final String mahasiswaId;
  final String namaMahasiswa;
  final DateTime waktuPresensi;
  final double? latitude;
  final double? longitude;
  final String status; // 'hadir' / 'otp_salah' / 'terlambat'

  Absensi({
    required this.id,
    required this.sesiId,
    required this.mahasiswaId,
    required this.namaMahasiswa,
    required this.waktuPresensi,
    this.latitude,
    this.longitude,
    required this.status,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'],
      sesiId: json['sesi_id'],
      mahasiswaId: json['mahasiswa_id'],
      namaMahasiswa: json['nama_mahasiswa'] ?? 'Mahasiswa',
      waktuPresensi: DateTime.parse(json['waktu_presensi']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sesi_id': sesiId,
      'mahasiswa_id': mahasiswaId,
      'nama_mahasiswa': namaMahasiswa,
      'waktu_presensi': waktuPresensi.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
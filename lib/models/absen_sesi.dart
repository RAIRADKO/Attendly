class AbsenSesi {
  final int id;
  final int mataKuliahId;
  final String dosenId;
  final DateTime waktuMulai;
  final DateTime? waktuSelesai;
  final String secretKeyOtp;
  final String status; // 'dibuka' / 'ditutup'

  AbsenSesi({
    required this.id,
    required this.mataKuliahId,
    required this.dosenId,
    required this.waktuMulai,
    this.waktuSelesai,
    required this.secretKeyOtp,
    required this.status,
  });

  factory AbsenSesi.fromJson(Map<String, dynamic> json) {
    return AbsenSesi(
      id: json['id'],
      mataKuliahId: json['mata_kuliah_id'],
      dosenId: json['dosen_id'],
      waktuMulai: DateTime.parse(json['waktu_mulai']),
      waktuSelesai: json['waktu_selesai'] != null 
        ? DateTime.parse(json['waktu_selesai']) 
        : null,
      secretKeyOtp: json['secret_key_otp'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mata_kuliah_id': mataKuliahId,
      'dosen_id': dosenId,
      'waktu_mulai': waktuMulai.toIso8601String(),
      'waktu_selesai': waktuSelesai?.toIso8601String(),
      'secret_key_otp': secretKeyOtp,
      'status': status,
    };
  }
}
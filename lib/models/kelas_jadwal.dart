import 'package:flutter/material.dart';

class KelasJadwal {
  final int id;
  final int mataKuliahId;
  final String hari;
  final TimeOfDay jamMulai;
  final TimeOfDay jamSelesai;

  KelasJadwal({
    required this.id,
    required this.mataKuliahId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory KelasJadwal.fromJson(Map<String, dynamic> json) {
    return KelasJadwal(
      id: json['id'],
      mataKuliahId: json['mata_kuliah_id'],
      hari: json['hari'],
      jamMulai: _parseTime(json['jam_mulai']),
      jamSelesai: _parseTime(json['jam_selesai']),
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mata_kuliah_id': mataKuliahId,
      'hari': hari,
      'jam_mulai': '${jamMulai.hour.toString().padLeft(2, '0')}:${jamMulai.minute.toString().padLeft(2, '0')}',
      'jam_selesai': '${jamSelesai.hour.toString().padLeft(2, '0')}:${jamSelesai.minute.toString().padLeft(2, '0')}',
    };
  }
}
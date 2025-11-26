class MataKuliah {
  final int id;
  final String namaMk;
  final String kodeMk;
  final String? dosenId;
  final String? namaDosen;

  MataKuliah({
    required this.id,
    required this.namaMk,
    required this.kodeMk,
    this.dosenId,
    this.namaDosen,
  });

  factory MataKuliah.fromJson(Map<String, dynamic> json) {
    return MataKuliah(
      id: json['id'],
      namaMk: json['nama_mk'],
      kodeMk: json['kode_mk'],
      dosenId: json['dosen_id'],
      namaDosen: json['nama_dosen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_mk': namaMk,
      'kode_mk': kodeMk,
      'dosen_id': dosenId,
      'nama_dosen': namaDosen,
    };
  }
}
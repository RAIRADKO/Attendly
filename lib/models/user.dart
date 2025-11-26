class User {
  final String id;
  final String email;
  final String nama;
  final String role;
  final String? nim;
  final String? nidn;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
    this.nim,
    this.nidn,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nama: json['nama'],
      role: json['role'],
      nim: json['nim'],
      nidn: json['nidn'],
      lastLogin: json['last_login'] != null 
        ? DateTime.parse(json['last_login']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nama': nama,
      'role': role,
      'nim': nim,
      'nidn': nidn,
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}
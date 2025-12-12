# Attendly - Aplikasi Presensi Perkuliahan Mobile

**Attendly** adalah aplikasi presensi mobile berbasis Flutter yang menggunakan **Supabase** sebagai backend. Aplikasi ini menangani validasi kehadiran mahasiswa menggunakan Geolocation (GPS) dengan fitur keamanan anti-fake GPS, serta membagi akses pengguna menjadi tiga role: **Admin**, **Dosen**, dan **Mahasiswa**.

---

## 📂 Struktur & Penjelasan Kode Utama

Berikut adalah penjelasan teknis mengenai bagaimana fitur-fitur utama diimplementasikan dalam kode, disertai cuplikan kode penting.

### 1. Gerbang Autentikasi & Routing (`lib/main.dart`)
Aplikasi tidak menggunakan *routing* statis biasa untuk halaman awal. Alih-alih, aplikasi menggunakan widget `AuthGate` yang secara cerdas mengecek apakah pengguna sudah login dan apa perannya (Admin/Dosen/Mahasiswa) sebelum menampilkan halaman dashboard yang sesuai.

**Cuplikan Kode (`_AuthGateState`):**
```dart
// Mengecek sesi user saat aplikasi dibuka
Future<void> _checkCurrentSession() async {
  final session = Supabase.instance.client.auth.currentSession;
  
  if (session != null) {
    final userId = session.user.id;
    // Mengambil data role dari tabel 'users' berdasarkan ID auth
    final response = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    
    // Set state role untuk menentukan dashboard mana yang dibuka
    if (response != null) {
      setState(() {
        _userRole = (response['role'] as String?)?.toLowerCase().trim();
        _isLoading = false;
      });
      return;
    }
```
### 2. Keamanan Lokasi & Anti-Fake GPS (lib/services/location_service.dart)
Fitur presensi mewajibkan mahasiswa berada di lokasi. Layanan ini tidak hanya mengambil koordinat, tapi juga memiliki mekanisme timeout (agar tidak loading selamanya) dan validasi keamanan untuk mendeteksi penggunaan aplikasi "Mock Location" (Fake GPS).

**Cuplikan Kode (getCurrentLocation):**
```dart
static Future<Position?> getCurrentLocation() async {
  // ... (pengecekan permission)

  try {
    // Mencoba akurasi tinggi dengan batas waktu 5 detik
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 5), 
    );
  } on TimeoutException {
    // Fallback ke akurasi medium jika terlalu lama
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 5),
    );
  }

  // FITUR KEAMANAN: Deteksi Fake GPS (Android)
  if (position.isMocked) {
    throw Exception('Terdeteksi penggunaan Lokasi Palsu (Fake GPS). Mohon matikan aplikasi tambahan tersebut.');
  }

  return position;
}
  }
  // Jika tidak ada sesi, arahkan ke Login
}
```
### 3. Layanan Autentikasi (lib/services/auth_service.dart)
Menangani komunikasi ke Supabase Auth. Kode ini melakukan validasi input (email/password) di sisi aplikasi sebelum mengirim request ke server untuk menghemat bandwidth dan memberikan feedback cepat.

**Cuplikan Kode (login):**
```dart
Future<bool> login(String email, String password) async {
  // Validasi format email menggunakan Regex
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalizedEmail)) {
    throw AppException('Format email tidak valid');
  }

  // Login ke Supabase
  final response = await _client.auth.signInWithPassword(
    email: normalizedEmail,
    password: normalizedPassword,
  );

  if (response.session == null) {
    throw AppException('Login gagal. Session tidak dibuat.');
  }
  return true;
}
```
### 4. Model Data Pengguna (lib/models/user.dart)
Mengubah data JSON mentah dari database menjadi objek Dart yang aman (User).

**Cuplikan Kode:**
```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'],
    email: json['email'],
    nama: json['nama'],
    role: json['role'],
    // Parsing tanggal login terakhir jika ada
    lastLogin: json['last_login'] != null 
      ? DateTime.parse(json['last_login']) 
      : null,
  );
}
```
### Cara Pakai Aplikasi
**1. Persiapan Awal (Instalasi)**
Environment Setup: Pastikan file .env sudah dibuat di root folder project dengan isi:
```
SUPABASE_URL=[https://your-project.supabase.co](https://your-project.supabase.co)
SUPABASE_ANON_KEY=your-anon-key
```

**2. Install Library:** Jalankan perintah berikut di terminal:
```
flutter pub get
```
**3. Jalankan Aplikasi:**
```
flutter run
```

---

### Panduan Pengguna (User Guide)
Berikut versi **README.md** yang rapi, terstruktur, dan siap digunakan:

---

## 🎓 Untuk Mahasiswa

### 🔐 Login

Masuk menggunakan **email** dan **password** yang telah diberikan oleh admin.

### 🏠 Dashboard

Halaman utama menampilkan **jadwal kuliah hari ini**.

### 📝 Melakukan Presensi

1. Pilih mata kuliah yang sedang **aktif**.
2. Pastikan Anda **berada di dalam kelas** atau dalam **jangkauan lokasi yang valid**.
3. Tekan tombol **"Hadir"** untuk melakukan presensi.
4. Sistem akan **menolak** presensi jika terdeteksi menggunakan **Fake GPS**.

### 📄 Riwayat Kehadiran

Lihat seluruh rekap kehadiran melalui menu **Riwayat**.

---

## 👨‍🏫 Untuk Dosen

### ▶️ Membuka Sesi Presensi

* Dari dashboard, pilih mata kuliah yang ingin diajar.
* Tekan **"Buka Sesi Presensi"**.

### 🔑 Kode/Token Sesi *(opsional)*

Jika digunakan, bagikan kode sesi kepada mahasiswa untuk proses absensi.

### 📊 Monitoring Kehadiran

Dosen dapat melihat **daftar mahasiswa yang sudah absen secara real-time**.

### ⏹ Menutup Sesi

Saat perkuliahan selesai, tutup sesi agar mahasiswa tidak dapat melakukan presensi lagi.

---

## 🛠 Untuk Admin

### 👥 Kelola User

* Menambahkan akun **Dosen** dan **Mahasiswa**.

### 🎓 Kelola Akademik

* Menambahkan **Mata Kuliah**, **Kelas**, dan menyusun **Jadwal** (hari dan jam).

### 📈 Laporan

* Melihat atau mengunduh **rekapitulasi presensi seluruh kampus**.

---

## 🧰 Tech Stack

| Fitur            | Teknologi                                   |
| ---------------- | ------------------------------------------- |
| Framework        | Flutter (Dart)                              |
| Backend          | Supabase (PostgreSQL + Auth)                |
| State Management | Provider                                    |
| Location         | Geolocator (High Accuracy + Mock Detection) |
| Config           | Flutter Dotenv                              |

import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Import Dashboard Baru
import 'screens/mahasiswa/dashboard_screen.dart';
import 'screens/dosen/dashboard_screen.dart';

// Import screen lain yang masih dibutuhkan untuk navigasi langsung (seperti detail presensi)
import 'screens/mahasiswa/presensi_screen.dart';
import 'screens/mahasiswa/riwayat_screen.dart';
import 'screens/dosen/sesi_presensi_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/laporan_screen.dart';
import 'models/mata_kuliah.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      
      // Mahasiswa
      case '/mahasiswa/home':
        // [UPDATE] Mengarah ke Dashboard (yang punya Bottom Nav Bar)
        return MaterialPageRoute(builder: (_) => MahasiswaDashboardScreen());
        
      case '/mahasiswa/presensi':
        // Route ini tetap dibutuhkan jika user klik "Isi Presensi" dari list mata kuliah
        final mataKuliah = settings.arguments as MataKuliah;
        return MaterialPageRoute(builder: (_) => PresensiScreen(mataKuliah: mataKuliah));
        
      case '/mahasiswa/riwayat':
        // Route ini opsional jika riwayat sudah ada di tab dashboard, 
        // tapi tetap disimpan untuk akses langsung jika perlu
        return MaterialPageRoute(builder: (_) => RiwayatPresensiScreen());
      
      // Dosen
      case '/dosen/home':
        // [UPDATE] Mengarah ke Dashboard Dosen
        return MaterialPageRoute(builder: (_) => DosenDashboardScreen());
        
      case '/dosen/sesi':
        final mataKuliah = settings.arguments as MataKuliah;
        return MaterialPageRoute(builder: (_) => SesiPresensiScreen(mataKuliah: mataKuliah));
      
      // Admin
      case '/admin/dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case '/admin/laporan':
        return MaterialPageRoute(builder: (_) => LaporanScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
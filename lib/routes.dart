import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/mahasiswa/home_screen.dart';
import 'screens/mahasiswa/presensi_screen.dart';
import 'screens/mahasiswa/riwayat_screen.dart';
import 'screens/dosen/home_screen.dart';
import 'screens/dosen/sesi_presensi_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/laporan_screen.dart';
import 'models/mata_kuliah.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      
      case '/mahasiswa/home':
        return MaterialPageRoute(builder: (_) => MahasiswaHomeScreen());
      case '/mahasiswa/presensi':
        final mataKuliah = settings.arguments as MataKuliah;
        return MaterialPageRoute(builder: (_) => PresensiScreen(mataKuliah: mataKuliah));
      case '/mahasiswa/riwayat':
        return MaterialPageRoute(builder: (_) => RiwayatPresensiScreen());
      
      case '/dosen/home':
        return MaterialPageRoute(builder: (_) => DosenHomeScreen());
      case '/dosen/sesi':
        final mataKuliah = settings.arguments as MataKuliah;
        return MaterialPageRoute(builder: (_) => SesiPresensiScreen(mataKuliah: mataKuliah));
      
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
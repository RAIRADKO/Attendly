import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Hindari memanggil openAppSettings langsung di sini agar UX lebih baik
      return false;
    }
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    bool permissionGranted = await checkLocationPermission();
    if (!permissionGranted) {
      return null;
    }

    try {
      // PERBAIKAN: Menambahkan timeout 10 detik untuk akurasi tinggi
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), 
      );
    } catch (e) {
      // Fallback: Coba dengan akurasi medium dan timeout lebih singkat jika yang pertama gagal
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        );
      } catch (e) {
        return null;
      }
    }
  }
}
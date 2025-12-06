import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Tambahkan untuk TimeoutException

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
      return false;
    }
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    // 1. Cek service & permission (kode lama Anda sudah oke)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    bool permissionGranted = await checkLocationPermission();
    if (!permissionGranted) return null;

    try {
      // PERBAIKAN: Kurangi waktu timeout agar user tidak menunggu terlalu lama
      // 30 detik terlalu lama, 5-10 detik cukup untuk High Accuracy di gedung
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), 
        );
      } on TimeoutException {
        // Fallback langsung ke Medium
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        );
      }

      // FITUR KEAMANAN BARU: Cek Fake GPS (Mock Location)
      // Catatan: isMocked hanya valid di Android
      if (position.isMocked) {
        throw Exception('Terdeteksi penggunaan Lokasi Palsu (Fake GPS). Mohon matikan aplikasi tambahan tersebut.');
      }

      return position;

    } catch (e) {
      // Jika semua gagal, coba last known position
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  // ✅ TAMBAHAN: Get location with progress callback
  static Future<Position?> getCurrentLocationWithProgress(
    Function(String message)? onProgress,
  ) async {
    onProgress?.call("Memeriksa layanan lokasi...");
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onProgress?.call("GPS tidak aktif. Silakan aktifkan GPS.");
      return null;
    }

    onProgress?.call("Memeriksa izin lokasi...");
    bool permissionGranted = await checkLocationPermission();
    if (!permissionGranted) {
      onProgress?.call("Izin lokasi ditolak");
      return null;
    }

    onProgress?.call("Mengambil lokasi akurat...");
    return await getCurrentLocation();
  }
}
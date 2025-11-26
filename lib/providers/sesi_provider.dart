import 'package:flutter/foundation.dart';
import '../models/absensi.dart';
import '../models/absen_sesi.dart';
import '../services/database_service.dart';

class SesiProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Absensi> _presensiList = [];
  AbsenSesi? _currentSesi;

  bool get isLoading => _isLoading;
  List<Absensi> get presensiList => _presensiList;
  AbsenSesi? get currentSesi => _currentSesi;

  // PERBAIKAN: Menambahkan parameter secretKey
  Future<AbsenSesi> createSesiPresensi(int mataKuliahId, String dosenId, String secretKey) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Pass secretKey ke service
      _currentSesi = await DatabaseService().createSesiPresensi(mataKuliahId, dosenId, secretKey);
      _isLoading = false;
      notifyListeners();
      return _currentSesi!;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Gagal membuat sesi presensi: $e');
    }
  }

  Future<void> tutupSesi(int sesiId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseService().closeSesiPresensi(sesiId);
      _currentSesi = null;
    } catch (e) {
      throw Exception('Gagal menutup sesi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> listenToPresensi(int sesiId) async {
    // Implement real-time listening for presensi updates
  }
}
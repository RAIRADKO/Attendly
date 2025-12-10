import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/app_exception.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// PERBAIKAN: Login dengan error handling dan validasi yang lebih baik
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService().login(email, password);
      
      if (success) {
        // Ambil data user setelah login berhasil
        _currentUser = await AuthService().getCurrentUser();
        
        if (_currentUser == null) {
          _errorMessage = 'Gagal mengambil data pengguna. Silakan coba lagi.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        print('[AUTH PROVIDER] Login successful. Role: ${_currentUser!.role}');
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _errorMessage = 'Login gagal. Silakan periksa email dan password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      throw AppException(_errorMessage!);
    }
  }

  /// PERBAIKAN: Forgot password dengan error handling
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await AuthService().forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return success;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      throw AppException(_errorMessage!);
    }
  }

  /// PERBAIKAN: Logout dengan error handling
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService().logout();
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Tetap clear user meskipun logout error
      _currentUser = null;
      rethrow;
    }
  }

  /// PERBAIKAN: Check auth status dengan error handling
  Future<void> checkAuthStatus() async {
    try {
      _currentUser = await AuthService().getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('[AUTH PROVIDER] Error checking auth status: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await AuthService().login(email, password);
      if (success) {
        _currentUser = await AuthService().getCurrentUser();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      return await AuthService().forgotPassword(email);
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await AuthService().logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _currentUser = await AuthService().getCurrentUser();
    notifyListeners();
  }
}
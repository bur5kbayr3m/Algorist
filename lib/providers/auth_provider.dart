import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Authentication State Provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;
  String? get errorMessage => _errorMessage;

  /// Geçerli kullanıcı bilgilerini döndürür
  Map<String, String?>? get currentUser => _isLoggedIn
      ? {'email': _currentUserEmail, 'fullName': _currentUserName}
      : null;

  /// Uygulama başlangıcında oturum durumunu kontrol eder
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _currentUserName = await _authService.getCurrentUserName();
        _currentUserEmail = await _authService.getCurrentUserEmail();
      }
    } catch (e) {
      _errorMessage = 'Oturum kontrolü başarısız: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Kullanıcı kaydı yapar
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (success) {
        // Kayıt başarılı, otomatik giriş yap
        return await login(email: email, password: password);
      } else {
        _errorMessage = 'Bu email adresi zaten kullanılıyor';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Kayıt başarısız: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı girişi yapar
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.login(
        email: email,
        password: password,
      );

      if (success) {
        _isLoggedIn = true;
        _currentUserName = await _authService.getCurrentUserName();
        _currentUserEmail = await _authService.getCurrentUserEmail();
      } else {
        _errorMessage = 'Email veya şifre hatalı';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Giriş başarısız: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google ile giriş yapar
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithGoogle();

      if (success) {
        _isLoggedIn = true;
        _currentUserName = await _authService.getCurrentUserName();
        _currentUserEmail = await _authService.getCurrentUserEmail();
      } else {
        _errorMessage = 'Google ile giriş başarısız';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Google girişi başarısız: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı oturumunu kapatır
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoggedIn = false;
      _currentUserName = null;
      _currentUserEmail = null;
    } catch (e) {
      _errorMessage = 'Çıkış başarısız: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Hata mesajını temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

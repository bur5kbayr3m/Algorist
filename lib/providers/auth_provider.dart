import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Authentication State Provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  /// Geçerli kullanıcı bilgilerini döndürür
  Map<String, String?>? get currentUser {
    if (!_isLoggedIn) return null;
    return {
      'email': _currentUserEmail,
      'fullName': _currentUserName,
      'phone': _currentUserPhone,
      'profileImage': _currentUserProfileImage,
    };
  }

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _currentUserPhone;
  String? _currentUserProfileImage;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail;
  String? get errorMessage => _errorMessage;

  /// Kullanıcı bilgilerini günceller
  void updateCurrentUser(Map<String, dynamic> userData) {
    _currentUserEmail = userData['email'];
    _currentUserName = userData['fullName'];
    _currentUserPhone = userData['phone'];
    _currentUserProfileImage = userData['profileImage'];
    notifyListeners();
  }

  /// Uygulama başlangıcında oturum durumunu kontrol eder
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _currentUserEmail = await _authService.getCurrentUserEmail();
        if (_currentUserEmail != null) {
          // Veritabanından tüm kullanıcı bilgilerini al
          final userData = await _authService.getUserData(_currentUserEmail!);
          if (userData != null) {
            _currentUserName = userData['fullName'];
            _currentUserPhone = userData['phone'];
            _currentUserProfileImage = userData['profileImage'];
          } else {
            _currentUserName = await _authService.getCurrentUserName();
          }
        }
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
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (success) {
        // Kayıt başarılı, otomatik giriş yap
        return await login(email: email, password: password);
      } else {
        _errorMessage = 'Bu email adresi zaten kullanılıyor';
        return false;
      }
    } catch (e) {
      // Exception'dan gelen mesajı kullan
      final errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        _errorMessage = errorMsg.split('Exception:')[1].trim();
      } else {
        _errorMessage = 'Kayıt başarısız: $e';
      }
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
        _currentUserEmail = email;
        // Veritabanından tüm kullanıcı bilgilerini al
        final userData = await _authService.getUserData(email);
        if (userData != null) {
          _currentUserName = userData['fullName'];
          _currentUserPhone = userData['phone'];
          _currentUserProfileImage = userData['profileImage'];
        } else {
          _currentUserName = await _authService.getCurrentUserName();
        }
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

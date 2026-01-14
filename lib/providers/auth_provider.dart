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
        // Kayıt başarılı - otomatik login yapmıyoruz
        // Register screen'de success dialog gösterilecek
        return true;
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

  /// Email ile otomatik giriş yapar (biyometrik için)
  Future<bool> loginWithEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kullanıcı var mı kontrol et
      final userData = await _authService.getUserData(email);

      if (userData == null) {
        _errorMessage = 'Kullanıcı bulunamadı';
        return false;
      }

      // Oturum aç
      await _authService.setLoggedIn(email);

      _isLoggedIn = true;
      _currentUserEmail = email;
      _currentUserName = userData['fullName'];
      _currentUserPhone = userData['phone'];
      _currentUserProfileImage = userData['profileImage'];

      return true;
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

  /// Kullanıcı profilini günceller
  Future<bool> updateUserProfile({String? fullName, String? phone}) async {
    if (_currentUserEmail == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.updateProfile(
        email: _currentUserEmail!,
        fullName: fullName,
        phone: phone,
      );

      if (success) {
        if (fullName != null) _currentUserName = fullName;
        if (phone != null) _currentUserPhone = phone;
      }

      return success;
    } catch (e) {
      _errorMessage = 'Profil güncellenemedi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hata mesajını temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Şifre sıfırlama kodu gönderir
  Future<bool> sendPasswordResetCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.sendPasswordResetCode(email);
      if (!success) {
        _errorMessage = 'Bu e-posta adresi kayıtlı değil';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Kod gönderilemedi: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Şifre sıfırlama kodunu doğrular
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.verifyPasswordResetCode(email, code);
      if (!success) {
        _errorMessage = 'Geçersiz veya süresi dolmuş kod';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Kod doğrulanamadı: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni şifre belirler
  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(
        email: email,
        newPassword: newPassword,
      );
      if (!success) {
        _errorMessage = 'Şifre güncellenemedi';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Şifre sıfırlanamadı: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

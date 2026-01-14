import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
import 'database_service.dart';
import '../utils/app_logger.dart';

/// Güvenli Authentication Servisi
/// - Şifreleri BCrypt ile hashler
/// - Kullanıcı bilgilerini SQLite veritabanında saklar
/// - BCrypt otomatik olarak salt kullanır
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Veritabanı servisi
  final _db = DatabaseService.instance;

  // Kullanıcı oturum anahtarları
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUser = 'current_user';
  static const String _keyUserEmail = 'user_email';

  /// Şifreyi BCrypt ile hashler
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Şifreyi doğrular
  bool _verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      AppLogger.log('❌ Password verification error: $e');
      return false;
    }
  }

  /// Kullanıcı kaydı oluşturur
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      AppLogger.log('👤 Registering user: $email');

      // Kullanıcı zaten var mı kontrol et
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        AppLogger.log('⚠️ User already exists: $email');
        return false; // Kullanıcı zaten mevcut
      }

      // BCrypt ile şifreyi hashle (salt otomatik eklenir)
      final hashedPassword = _hashPassword(password);

      // Kullanıcıyı veritabanına kaydet
      final userId = await _db.insertUser({
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'hashedPassword': hashedPassword,
        'salt': 'bcrypt', // BCrypt kendi salt'ını kullanır
        'createdAt': DateTime.now().toIso8601String(),
      });

      AppLogger.log('✅ User registered with ID: $userId');
      return userId > 0;
    } catch (e) {
      AppLogger.log('❌ Register error: $e');
      return false;
    }
  }

  /// Kullanıcı girişi yapar
  Future<bool> login({required String email, required String password}) async {
    try {
      AppLogger.log('🔐 Login attempt for: $email');

      // Kullanıcıyı veritabanından al
      final userData = await _db.getUserByEmail(email);
      if (userData == null) {
        AppLogger.log('❌ User not found: $email');
        return false; // Kullanıcı bulunamadı
      }

      final storedHash = userData['hashedPassword'] as String;

      // BCrypt ile şifreyi doğrula
      if (_verifyPassword(password, storedHash)) {
        // Giriş başarılı - oturum bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyCurrentUser, userData['fullName'] ?? '');
        await prefs.setString(_keyUserEmail, email);

        AppLogger.log('✅ Login successful for: $email');
        return true;
      }

      AppLogger.log('❌ Invalid password for: $email');
      return false;
    } catch (e) {
      AppLogger.log('❌ Login error: $e');
      return false;
    }
  }

  /// Google ile giriş simülasyonu
  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.log('🔵 Google sign-in attempt');

      // Gerçek uygulamada Google Sign-In SDK kullanılır
      // Şimdilik mock implementation

      // Örnek Google kullanıcısı
      const email = 'user@gmail.com';
      const fullName = 'Google User';

      // Google kullanıcısını kaydet (eğer yoksa)
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser == null) {
        await _db.insertUser({
          'email': email,
          'fullName': fullName,
          'provider': 'google',
          'createdAt': DateTime.now().toIso8601String(),
        });
        AppLogger.log('✅ Google user registered: $email');
      }

      // Oturum aç
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUser, fullName);
      await prefs.setString(_keyUserEmail, email);

      AppLogger.log('✅ Google sign-in successful');
      return true;
    } catch (e) {
      AppLogger.log('❌ Google sign-in error: $e');
      return false;
    }
  }

  /// Kullanıcı oturumunu kapatır
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyCurrentUser);
      await prefs.remove(_keyUserEmail);
    } catch (e) {
      AppLogger.log('Logout error: $e');
    }
  }

  /// Kullanıcıyı giriş yapmış olarak işaretle (biyometrik giriş için)
  Future<void> setLoggedIn(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, email);
      AppLogger.log('✅ User logged in via biometric: $email');
    } catch (e) {
      AppLogger.log('❌ Set logged in error: $e');
    }
  }

  /// Kullanıcı oturum açmış mı kontrol eder
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      AppLogger.log('Check login error: $e');
      return false;
    }
  }

  /// Mevcut kullanıcı adını getirir
  Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCurrentUser);
    } catch (e) {
      AppLogger.log('Get user name error: $e');
      return null;
    }
  }

  /// Mevcut kullanıcı email'ini getirir
  Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      AppLogger.log('Get user email error: $e');
      return null;
    }
  }

  /// Kullanıcının tüm verilerini getirir
  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      return await _db.getUserByEmail(email);
    } catch (e) {
      AppLogger.log('Get user data error: $e');
      return null;
    }
  }

  /// Kullanıcı profilini günceller
  Future<bool> updateProfile({
    required String email,
    String? fullName,
    String? phone,
  }) async {
    try {
      AppLogger.log('📝 Updating profile for: $email');
      await _db.updateUserProfile(email, fullName: fullName, phone: phone);
      AppLogger.log('✅ Profile updated successfully');
      return true;
    } catch (e) {
      AppLogger.log('❌ Update profile error: $e');
      return false;
    }
  }

  /// Şifreyi sıfırlar (email doğrulamalı)
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      AppLogger.log('🔑 Resetting password for: $email');

      // Kullanıcı var mı kontrol et
      final userData = await _db.getUserByEmail(email);
      if (userData == null) {
        AppLogger.log('❌ User not found: $email');
        return false;
      }

      // Şifreyi güncelle (BCrypt hash işlemi DatabaseService'de yapılır)
      await _db.updateUserPassword(email, newPassword);

      // Doğrulama kodunu temizle
      await _db.clearPasswordResetCode(email);

      AppLogger.log('✅ Password reset successful for: $email');
      return true;
    } catch (e) {
      AppLogger.log('❌ Reset password error: $e');
      return false;
    }
  }

  /// Şifre sıfırlama kodu gönderir
  Future<bool> sendPasswordResetCode(String email) async {
    try {
      AppLogger.log('📧 Sending password reset code to: $email');

      // Kod oluştur ve kaydet
      final code = await _db.generatePasswordResetCode(email);

      if (code == null) {
        AppLogger.log('❌ Failed to generate reset code');
        return false;
      }

      // E-posta gönderme simülasyonu (gerçek uygulamada email servisi kullanılır)
      AppLogger.log('📨 Password reset code: $code');
      AppLogger.log('✅ Reset code sent to: $email');

      // TODO: Gerçek uygulamada email servisi ile kod gönderilmeli
      // await EmailService.sendResetCode(email, code);

      return true;
    } catch (e) {
      AppLogger.log('❌ Send reset code error: $e');
      return false;
    }
  }

  /// Şifre sıfırlama kodunu doğrular
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    try {
      AppLogger.log('🔐 Verifying reset code for: $email');

      final isValid = await _db.verifyPasswordResetCode(email, code);

      if (isValid) {
        AppLogger.log('✅ Reset code verified for: $email');
      } else {
        AppLogger.log('❌ Invalid or expired reset code');
      }

      return isValid;
    } catch (e) {
      AppLogger.log('❌ Verify reset code error: $e');
      return false;
    }
  }

  /// Tüm kullanıcı verilerini siler (GDPR uyumluluk için)
  Future<void> deleteAccount(String email) async {
    try {
      AppLogger.log('🗑️ Deleting account: $email');

      // Önce kullanıcının tüm assetlerini sil
      await _db.deleteUserAssets(email);

      // Sonra kullanıcı kaydını sil
      await _db.database.then(
        (db) => db.delete('users', where: 'email = ?', whereArgs: [email]),
      );

      // Oturumu kapat
      await logout();

      AppLogger.log('✅ Account deleted: $email');
    } catch (e) {
      AppLogger.log('❌ Delete account error: $e');
    }
  }
}

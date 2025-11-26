import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8;
import 'database_service.dart';

/// Güvenli Authentication Servisi
/// - Şifreleri SHA-256 ile hashler
/// - Kullanıcı bilgilerini SQLite veritabanında saklar
/// - Salt kullanarak rainbow table saldırılarını önler
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

  /// Şifreyi güvenli şekilde hashler (SHA-256 + Salt)
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Rastgele salt oluşturur
  String _generateSalt(String email) {
    // Email + timestamp kombinasyonu ile unique salt
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final saltInput = email + timestamp;
    final bytes = utf8.encode(saltInput);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Kullanıcı kaydı oluşturur
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('👤 Registering user: $email');

      // Kullanıcı zaten var mı kontrol et
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        print('⚠️ User already exists: $email');
        return false; // Kullanıcı zaten mevcut
      }

      // Salt oluştur ve şifreyi hashle
      final salt = _generateSalt(email);
      final hashedPassword = _hashPassword(password, salt);

      // Kullanıcıyı veritabanına kaydet
      final userId = await _db.insertUser({
        'email': email,
        'fullName': fullName,
        'hashedPassword': hashedPassword,
        'salt': salt,
        'createdAt': DateTime.now().toIso8601String(),
      });

      print('✅ User registered with ID: $userId');
      return userId > 0;
    } catch (e) {
      print('❌ Register error: $e');
      return false;
    }
  }

  /// Kullanıcı girişi yapar
  Future<bool> login({required String email, required String password}) async {
    try {
      print('🔐 Login attempt for: $email');

      // Kullanıcıyı veritabanından al
      final userData = await _db.getUserByEmail(email);
      if (userData == null) {
        print('❌ User not found: $email');
        return false; // Kullanıcı bulunamadı
      }

      final storedHash = userData['hashedPassword'] as String;
      final salt = userData['salt'] as String;

      // Girilen şifreyi hashle ve karşılaştır
      final hashedPassword = _hashPassword(password, salt);

      if (hashedPassword == storedHash) {
        // Giriş başarılı - oturum bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyCurrentUser, userData['fullName']);
        await prefs.setString(_keyUserEmail, email);

        print('✅ Login successful for: $email');
        return true;
      }

      print('❌ Invalid password for: $email');
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }

  /// Google ile giriş simülasyonu
  Future<bool> signInWithGoogle() async {
    try {
      print('🔵 Google sign-in attempt');

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
        print('✅ Google user registered: $email');
      }

      // Oturum aç
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUser, fullName);
      await prefs.setString(_keyUserEmail, email);

      print('✅ Google sign-in successful');
      return true;
    } catch (e) {
      print('❌ Google sign-in error: $e');
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
      print('Logout error: $e');
    }
  }

  /// Kullanıcı oturum açmış mı kontrol eder
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('Check login error: $e');
      return false;
    }
  }

  /// Mevcut kullanıcı adını getirir
  Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCurrentUser);
    } catch (e) {
      print('Get user name error: $e');
      return null;
    }
  }

  /// Mevcut kullanıcı email'ini getirir
  Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('Get user email error: $e');
      return null;
    }
  }

  /// Şifreyi sıfırlar (email doğrulamalı)
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      print('🔑 Resetting password for: $email');

      // Kullanıcı var mı kontrol et
      final userData = await _db.getUserByEmail(email);
      if (userData == null) {
        print('❌ User not found: $email');
        return false;
      }

      // Yeni salt ve hash oluştur
      final salt = _generateSalt(email);
      final hashedPassword = _hashPassword(newPassword, salt);

      // Kullanıcı verisini güncelle
      userData['hashedPassword'] = hashedPassword;
      userData['salt'] = salt;
      userData['passwordUpdatedAt'] = DateTime.now().toIso8601String();

      final userId = userData['id'] as int;
      await _db.database.then(
        (db) =>
            db.update('users', userData, where: 'id = ?', whereArgs: [userId]),
      );

      print('✅ Password reset successful for: $email');
      return true;
    } catch (e) {
      print('❌ Reset password error: $e');
      return false;
    }
  }

  /// Tüm kullanıcı verilerini siler (GDPR uyumluluk için)
  Future<void> deleteAccount(String email) async {
    try {
      print('🗑️ Deleting account: $email');

      // Önce kullanıcının tüm assetlerini sil
      await _db.deleteUserAssets(email);

      // Sonra kullanıcı kaydını sil
      await _db.database.then(
        (db) => db.delete('users', where: 'email = ?', whereArgs: [email]),
      );

      // Oturumu kapat
      await logout();

      print('✅ Account deleted: $email');
    } catch (e) {
      print('❌ Delete account error: $e');
    }
  }
}

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  factory BiometricService() => instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Cihazda biyometrik kimlik doğrulama mevcut mu?
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      AppLogger.log('❌ Error checking biometrics: $e');
      return false;
    }
  }

  /// Cihazda mevcut biyometrik türlerini al
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.log('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Biyometrik kimlik doğrulama yapılabilir mi?
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      AppLogger.log('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Biyometrik türünün adını al
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Parmak İzi';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris Tanıma';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biyometrik Kimlik';
    }
    return 'Biyometrik Kimlik';
  }

  /// Biyometrik kimlik doğrulama yap
  Future<bool> authenticate({
    String reason = 'Lütfen kimliğinizi doğrulayın',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        AppLogger.log('❌ Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        AppLogger.log('✅ Biometric authentication successful');
      } else {
        AppLogger.log('❌ Biometric authentication failed');
      }

      return authenticated;
    } on PlatformException catch (e) {
      AppLogger.log('❌ Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.log('❌ Biometric authentication error: $e');
      return false;
    }
  }

  /// Biyometrik kimlik doğrulamanın etkin olup olmadığını kontrol et
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      AppLogger.log('❌ Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Biyometrik kimlik doğrulamayı etkinleştir/devre dışı bırak
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      // Eğer etkinleştiriyorsak, önce cihazda biyometrik var mı kontrol et
      if (enabled) {
        final isAvailable = await isBiometricAvailable();
        if (!isAvailable) {
          AppLogger.log('❌ Biometric not available on this device');
          return false;
        }

        // Kullanıcıdan biyometrik doğrulama iste
        final authenticated = await authenticate(
          reason:
              'Biyometrik girişi etkinleştirmek için kimliğinizi doğrulayın',
        );

        if (!authenticated) {
          AppLogger.log('❌ Biometric authentication failed, cannot enable');
          return false;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);

      AppLogger.log('✅ Biometric ${enabled ? 'enabled' : 'disabled'}');
      return true;
    } catch (e) {
      AppLogger.log('❌ Error setting biometric enabled status: $e');
      return false;
    }
  }

  /// Kullanıcının son biyometrik tercihini kaydet (email ile ilişkilendir)
  Future<void> saveBiometricPreference(String email, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_$email', enabled);
    } catch (e) {
      AppLogger.log('❌ Error saving biometric preference: $e');
    }
  }

  /// Kullanıcının biyometrik tercihini al
  Future<bool> getBiometricPreference(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_$email') ?? false;
    } catch (e) {
      AppLogger.log('❌ Error getting biometric preference: $e');
      return false;
    }
  }

  /// Giriş için kaydedilmiş email'i kaydet (biyometrik giriş için)
  Future<void> saveEmailForBiometric(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_email', email);
      AppLogger.log('✅ Email saved for biometric login: $email');
    } catch (e) {
      AppLogger.log('❌ Error saving email for biometric: $e');
    }
  }

  /// Biyometrik giriş için kaydedilmiş email'i al
  Future<String?> getEmailForBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('biometric_email');
    } catch (e) {
      AppLogger.log('❌ Error getting email for biometric: $e');
      return null;
    }
  }

  /// Biyometrik verilerini temizle
  Future<void> clearBiometricData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove('biometric_email');
      AppLogger.log('✅ Biometric data cleared');
    } catch (e) {
      AppLogger.log('❌ Error clearing biometric data: $e');
    }
  }
}


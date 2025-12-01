import 'dart:math';
import 'package:flutter/foundation.dart';
import 'database_service.dart';

/// Email Doğrulama Servisi
/// NOT: Bu development versiyonu. Production için gerçek email servisi
/// (SendGrid, AWS SES, Mailgun vb.) kullanılmalı.
class EmailVerificationService {
  static final EmailVerificationService instance =
      EmailVerificationService._internal();
  factory EmailVerificationService() => instance;
  EmailVerificationService._internal();

  // Geçici doğrulama kodları (Development için)
  final Map<String, _VerificationData> _verificationStorage = {};

  /// Doğrulama kodu üretir ve email gönderir (simüle edilmiş)
  Future<bool> sendVerificationCode(String email) async {
    try {
      // 6 haneli random kod üret
      final code = _generateVerificationCode();

      // Kodu sakla (5 dakika geçerlilik)
      _verificationStorage[email] = _VerificationData(
        code: code,
        expiryTime: DateTime.now().add(const Duration(minutes: 5)),
      );

      // Veritabanına da kaydet
      await DatabaseService.instance.database.then((db) async {
        await db.update(
          'users',
          {'verificationCode': code},
          where: 'email = ?',
          whereArgs: [email],
        );
      });

      // Development: Console'a yazdır
      if (kDebugMode) {
        print('📧 Email Gönderildi: $email');
        print('🔐 Doğrulama Kodu: $code');
        print('⏰ Geçerlilik: 5 dakika');
      }

      // Production'da burası gerçek email API çağrısı olacak:
      // await _sendRealEmail(email, code);

      // Simüle edilmiş gecikme
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email gönderme hatası: $e');
      }
      return false;
    }
  }

  /// Doğrulama kodunu kontrol eder
  Future<bool> verifyCode(String email, String code) async {
    try {
      final verificationData = _verificationStorage[email];

      if (verificationData == null) {
        if (kDebugMode) {
          print('❌ Bu email için doğrulama kodu bulunamadı');
        }
        return false;
      }

      // Süre kontrolü
      if (DateTime.now().isAfter(verificationData.expiryTime)) {
        _verificationStorage.remove(email);
        if (kDebugMode) {
          print('⏰ Doğrulama kodu süresi dolmuş');
        }
        return false;
      }

      // Kod kontrolü
      final isValid = verificationData.code == code;

      if (isValid) {
        // Doğrulama başarılı, veritabanını güncelle
        await _markEmailAsVerified(email);

        // Kodu temizle
        _verificationStorage.remove(email);

        if (kDebugMode) {
          print('✅ Email doğrulandı: $email');
        }
      } else {
        if (kDebugMode) {
          print('❌ Doğrulama kodu yanlış');
        }
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Doğrulama hatası: $e');
      }
      return false;
    }
  }

  /// Email'i doğrulanmış olarak işaretle
  Future<void> _markEmailAsVerified(String email) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {'emailVerified': 1, 'verificationCode': null},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  /// Email doğrulanmış mı kontrol et
  Future<bool> isEmailVerified(String email) async {
    try {
      final db = await DatabaseService.instance.database;
      final result = await db.query(
        'users',
        columns: ['emailVerified'],
        where: 'email = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) return false;

      final verified = result.first['emailVerified'] as int?;
      return verified == 1;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email doğrulama kontrolü hatası: $e');
      }
      return false;
    }
  }

  /// Doğrulama kodunu yeniden gönder
  Future<bool> resendVerificationCode(String email) async {
    // Eski kodu temizle
    _verificationStorage.remove(email);

    // Yeni kod gönder
    return await sendVerificationCode(email);
  }

  /// 6 haneli random doğrulama kodu üretir
  String _generateVerificationCode() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    return code;
  }

  /// Development: Verilen email için kodu döndür (test için)
  String? getCodeForTesting(String email) {
    if (kDebugMode) {
      return _verificationStorage[email]?.code;
    }
    return null;
  }

  /// Doğrulama kodunu temizle
  void clearCode(String email) {
    _verificationStorage.remove(email);
  }

  /// Tüm kodları temizle
  void clearAllCodes() {
    _verificationStorage.clear();
  }

  // Production için email gönderme örneği (SendGrid, AWS SES vb.)
  /*
  Future<void> _sendRealEmail(String email, String code) async {
    // Örnek: SendGrid API
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [{'email': email}],
            'subject': 'Algorist Email Doğrulama',
          }
        ],
        'from': {'email': 'noreply@algorist.app'},
        'content': [
          {
            'type': 'text/html',
            'value': '''
              <h2>Email Doğrulama</h2>
              <p>Merhaba,</p>
              <p>Algorist hesabınızı doğrulamak için aşağıdaki kodu kullanın:</p>
              <h1 style="color: #4B2BEE; font-size: 32px;">$code</h1>
              <p>Bu kod 5 dakika geçerlidir.</p>
              <p>Eğer bu işlemi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.</p>
            '''
          }
        ],
      }),
    );
    
    if (response.statusCode != 202) {
      throw Exception('Email gönderilemedi: ${response.body}');
    }
  }
  */
}

/// Doğrulama verisi için sınıf
class _VerificationData {
  final String code;
  final DateTime expiryTime;

  _VerificationData({required this.code, required this.expiryTime});
}

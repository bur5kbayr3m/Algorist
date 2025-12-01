import 'dart:math';
import 'package:flutter/foundation.dart';

/// SMS Doğrulama Servisi
/// NOT: Bu development versiyonu. Production için Firebase Auth, Twilio,
/// veya Türkiye'de Netgsm, İleti Merkezi gibi servisler kullanılmalı.
class SmsService {
  static final SmsService instance = SmsService._internal();
  factory SmsService() => instance;
  SmsService._internal();

  // Geçici OTP saklama (Development için)
  final Map<String, _OtpData> _otpStorage = {};

  /// OTP üretir ve SMS gönderir (simüle edilmiş)
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      // 6 haneli random OTP üret
      final otp = _generateOtp();

      // OTP'yi sakla (5 dakika geçerlilik)
      _otpStorage[phoneNumber] = _OtpData(
        otp: otp,
        expiryTime: DateTime.now().add(const Duration(minutes: 5)),
      );

      // Development: Console'a yazdır
      if (kDebugMode) {
        print('📱 SMS Gönderildi: $phoneNumber');
        print('🔐 OTP Kodu: $otp');
        print('⏰ Geçerlilik: 5 dakika');
      }

      // Production'da burası gerçek SMS API çağrısı olacak:
      // await _sendRealSms(phoneNumber, otp);

      // Simüle edilmiş gecikme
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SMS gönderme hatası: $e');
      }
      return false;
    }
  }

  /// OTP'yi doğrular
  bool verifyOtp(String phoneNumber, String otp) {
    final otpData = _otpStorage[phoneNumber];

    if (otpData == null) {
      if (kDebugMode) {
        print('❌ Bu telefon numarası için OTP bulunamadı');
      }
      return false;
    }

    // Süre kontrolü
    if (DateTime.now().isAfter(otpData.expiryTime)) {
      _otpStorage.remove(phoneNumber);
      if (kDebugMode) {
        print('⏰ OTP süresi dolmuş');
      }
      return false;
    }

    // OTP kontrolü
    final isValid = otpData.otp == otp;

    if (isValid) {
      // Doğrulama başarılı, OTP'yi temizle
      _otpStorage.remove(phoneNumber);
      if (kDebugMode) {
        print('✅ OTP doğrulandı');
      }
    } else {
      if (kDebugMode) {
        print('❌ OTP yanlış');
      }
    }

    return isValid;
  }

  /// OTP yeniden gönder
  Future<bool> resendOtp(String phoneNumber) async {
    // Eski OTP'yi temizle
    _otpStorage.remove(phoneNumber);

    // Yeni OTP gönder
    return await sendOtp(phoneNumber);
  }

  /// 6 haneli random OTP üretir
  String _generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Development: Verilen telefon için OTP'yi döndür (test için)
  String? getOtpForTesting(String phoneNumber) {
    if (kDebugMode) {
      return _otpStorage[phoneNumber]?.otp;
    }
    return null;
  }

  /// OTP storage'ı temizle
  void clearOtp(String phoneNumber) {
    _otpStorage.remove(phoneNumber);
  }

  /// Tüm OTP'leri temizle
  void clearAllOtps() {
    _otpStorage.clear();
  }

  // Production için SMS gönderme örneği (Twilio, Netgsm vb.)
  /*
  Future<void> _sendRealSms(String phoneNumber, String otp) async {
    // Örnek: Twilio API
    final accountSid = 'YOUR_ACCOUNT_SID';
    final authToken = 'YOUR_AUTH_TOKEN';
    final twilioNumber = 'YOUR_TWILIO_NUMBER';
    
    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'
    );
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ' + 
          base64Encode(utf8.encode('$accountSid:$authToken')),
      },
      body: {
        'From': twilioNumber,
        'To': phoneNumber,
        'Body': 'Algorist doğrulama kodunuz: $otp\nKod 5 dakika geçerlidir.',
      },
    );
    
    if (response.statusCode != 201) {
      throw Exception('SMS gönderilemedi: ${response.body}');
    }
  }
  */
}

/// OTP verisi için sınıf
class _OtpData {
  final String otp;
  final DateTime expiryTime;

  _OtpData({required this.otp, required this.expiryTime});
}

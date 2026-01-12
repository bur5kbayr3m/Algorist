import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import '../utils/app_logger.dart';

/// Bildirim Servisi - Push ve Email bildirimleri yönetir
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // SMTP Ayarları (Gmail örneği - gerçek uygulamada env variable kullanın)
  // Gmail için "App Password" oluşturmanız gerekir
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = ''; // Gmail adresiniz
  static const String _smtpPassword = ''; // App Password

  /// Bildirim servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android ayarları
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Genel ayarlar
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için bildirim kanalı oluştur
    await _createNotificationChannel();

    _isInitialized = true;
    AppLogger.log('🔔 Notification service initialized');
  }

  /// Android bildirim kanalı oluştur
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'algorist_main_channel',
      'Algorist Bildirimleri',
      description: 'Algorist uygulama bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.log('🔔 Notification tapped: ${response.payload}');
    // Burada bildirime tıklandığında yapılacak işlemler
  }

  /// Basit bildirim göster
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'algorist_main_channel',
      'Algorist Bildirimleri',
      channelDescription: 'Algorist uygulama bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4F46E5),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    AppLogger.log('🔔 Notification shown: $title');
  }

  /// Portföy değişikliği bildirimi
  Future<void> showPortfolioChangeNotification({
    required double changePercent,
    required double changeAmount,
    required String period,
  }) async {
    final isPositive = changePercent >= 0;
    final emoji = isPositive ? '📈' : '📉';
    final sign = isPositive ? '+' : '';

    await showNotification(
      title: '$emoji Portföy Güncellemesi',
      body:
          '$period: $sign${changePercent.toStringAsFixed(2)}% ($sign₺${changeAmount.toStringAsFixed(2)})',
      payload: 'portfolio_change',
    );
  }

  /// Fiyat uyarısı bildirimi
  Future<void> showPriceAlertNotification({
    required String assetName,
    required double currentPrice,
    required double targetPrice,
    required bool isAboveTarget,
  }) async {
    final emoji = isAboveTarget ? '🚀' : '⚠️';
    final direction = isAboveTarget ? 'üzerine çıktı' : 'altına düştü';

    await showNotification(
      title: '$emoji Fiyat Uyarısı: $assetName',
      body:
          'Fiyat ₺${currentPrice.toStringAsFixed(2)} ile hedef fiyatın $direction!',
      payload: 'price_alert_$assetName',
    );
  }

  /// Varlık ekleme bildirimi
  Future<void> showAssetAddedNotification({
    required String assetName,
    required String assetType,
    required double amount,
  }) async {
    await showNotification(
      title: '✅ Varlık Eklendi',
      body: '$assetName ($assetType) - ₺${amount.toStringAsFixed(2)}',
      payload: 'asset_added',
    );
  }

  /// Güvenlik bildirimi (şifre değişikliği vb.)
  Future<void> showSecurityNotification({required String message}) async {
    await showNotification(
      title: '🔐 Güvenlik Bildirimi',
      body: message,
      payload: 'security',
    );
  }

  /// Güvenlik uyarısı - Push bildirim
  Future<void> showSecurityAlert({
    required String title,
    required String body,
  }) async {
    await showNotification(
      title: '🔐 $title',
      body: body,
      payload: 'security_alert',
    );
  }

  /// Basit email gönderme (text formatında)
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    return await sendEmailNotification(
      toEmail: to,
      subject: subject,
      body: body,
      isHtml: false,
    );
  }

  /// Email bildirimi gönder
  Future<bool> sendEmailNotification({
    required String toEmail,
    required String subject,
    required String body,
    bool isHtml = false,
  }) async {
    try {
      // SMTP ayarları boşsa email gönderme
      if (_smtpUsername.isEmpty || _smtpPassword.isEmpty) {
        AppLogger.log('⚠️ SMTP credentials not configured');
        // Geliştirme ortamında simüle et
        AppLogger.log('📧 [SIMULATED] Email to: $toEmail');
        AppLogger.log('   Subject: $subject');
        AppLogger.log('   Body: $body');
        return true;
      }

      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: true,
      );

      final message = mailer.Message()
        ..from = mailer.Address(_smtpUsername, 'Algorist')
        ..recipients.add(toEmail)
        ..subject = subject
        ..text = isHtml ? null : body
        ..html = isHtml ? body : null;

      await mailer.send(message, smtpServer);
      AppLogger.log('✅ Email sent to: $toEmail');
      return true;
    } catch (e) {
      AppLogger.log('❌ Error sending email: $e');
      return false;
    }
  }

  /// Şifre sıfırlama emaili gönder
  Future<bool> sendPasswordResetEmail({
    required String toEmail,
    required String verificationCode,
  }) async {
    final subject = 'Algorist - Şifre Sıfırlama Kodu';
    final body =
        '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #0B0A12; color: #ffffff; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background-color: #1E293B; border-radius: 16px; padding: 32px; }
    .header { text-align: center; margin-bottom: 24px; }
    .logo { font-size: 32px; font-weight: bold; color: #4F46E5; }
    .code-box { background-color: #0B0A12; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
    .code { font-size: 36px; font-weight: bold; color: #4F46E5; letter-spacing: 8px; }
    .message { color: #94A3B8; line-height: 1.6; }
    .footer { text-align: center; margin-top: 24px; color: #64748B; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">Algorist</div>
    </div>
    <p class="message">Merhaba,</p>
    <p class="message">Şifre sıfırlama talebinizi aldık. Aşağıdaki doğrulama kodunu kullanarak şifrenizi sıfırlayabilirsiniz:</p>
    <div class="code-box">
      <div class="code">$verificationCode</div>
    </div>
    <p class="message">Bu kod 10 dakika boyunca geçerlidir.</p>
    <p class="message">Bu işlemi siz yapmadıysanız, bu emaili görmezden gelebilirsiniz.</p>
    <div class="footer">
      <p>© 2025 Algorist. Tüm hakları saklıdır.</p>
    </div>
  </div>
</body>
</html>
''';

    return await sendEmailNotification(
      toEmail: toEmail,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Email doğrulama kodu gönder
  Future<bool> sendVerificationEmail({
    required String toEmail,
    required String verificationCode,
  }) async {
    final subject = 'Algorist - Email Doğrulama Kodu';
    final body =
        '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #0B0A12; color: #ffffff; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background-color: #1E293B; border-radius: 16px; padding: 32px; }
    .header { text-align: center; margin-bottom: 24px; }
    .logo { font-size: 32px; font-weight: bold; color: #4F46E5; }
    .code-box { background-color: #0B0A12; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
    .code { font-size: 36px; font-weight: bold; color: #10B981; letter-spacing: 8px; }
    .message { color: #94A3B8; line-height: 1.6; }
    .footer { text-align: center; margin-top: 24px; color: #64748B; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">Algorist</div>
    </div>
    <p class="message">Algorist'e hoş geldiniz! 🎉</p>
    <p class="message">Email adresinizi doğrulamak için aşağıdaki kodu kullanın:</p>
    <div class="code-box">
      <div class="code">$verificationCode</div>
    </div>
    <p class="message">Bu kod 10 dakika boyunca geçerlidir.</p>
    <div class="footer">
      <p>© 2025 Algorist. Tüm hakları saklıdır.</p>
    </div>
  </div>
</body>
</html>
''';

    return await sendEmailNotification(
      toEmail: toEmail,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Portföy raporu emaili gönder
  Future<bool> sendPortfolioReportEmail({
    required String toEmail,
    required String userName,
    required double totalValue,
    required double changePercent,
    required List<Map<String, dynamic>> topAssets,
  }) async {
    final isPositive = changePercent >= 0;
    final changeColor = isPositive ? '#10B981' : '#EF4444';
    final changeSign = isPositive ? '+' : '';

    var assetsHtml = '';
    for (var asset in topAssets.take(5)) {
      assetsHtml +=
          '''
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #334155;">${asset['name']}</td>
          <td style="padding: 12px; border-bottom: 1px solid #334155;">${asset['type']}</td>
          <td style="padding: 12px; border-bottom: 1px solid #334155; text-align: right;">₺${(asset['totalCost'] as num).toStringAsFixed(2)}</td>
        </tr>
      ''';
    }

    final subject = 'Algorist - Haftalık Portföy Raporu';
    final body =
        '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #0B0A12; color: #ffffff; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background-color: #1E293B; border-radius: 16px; padding: 32px; }
    .header { text-align: center; margin-bottom: 24px; }
    .logo { font-size: 32px; font-weight: bold; color: #4F46E5; }
    .summary { background-color: #0B0A12; border-radius: 12px; padding: 24px; margin: 24px 0; }
    .total { font-size: 28px; font-weight: bold; color: #ffffff; text-align: center; }
    .change { font-size: 18px; color: $changeColor; text-align: center; margin-top: 8px; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th { text-align: left; padding: 12px; background-color: #334155; color: #94A3B8; }
    td { color: #ffffff; }
    .message { color: #94A3B8; line-height: 1.6; }
    .footer { text-align: center; margin-top: 24px; color: #64748B; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">Algorist</div>
    </div>
    <p class="message">Merhaba $userName,</p>
    <p class="message">İşte bu haftaki portföy özetiniz:</p>
    <div class="summary">
      <div class="total">₺${totalValue.toStringAsFixed(2)}</div>
      <div class="change">$changeSign${changePercent.toStringAsFixed(2)}% bu hafta</div>
    </div>
    <h3 style="color: #94A3B8;">En Değerli Varlıklarınız</h3>
    <table>
      <tr>
        <th>Varlık</th>
        <th>Tür</th>
        <th style="text-align: right;">Değer</th>
      </tr>
      $assetsHtml
    </table>
    <div class="footer">
      <p>© 2025 Algorist. Tüm hakları saklıdır.</p>
    </div>
  </div>
</body>
</html>
''';

    return await sendEmailNotification(
      toEmail: toEmail,
      subject: subject,
      body: body,
      isHtml: true,
    );
  }

  /// Tüm bildirimleri temizle
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    AppLogger.log('🔔 All notifications cancelled');
  }

  /// Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Bildirim izni kontrolü
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }
}


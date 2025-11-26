import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Database Viewer Script
/// Bu script'i VS Code terminal'inden çalıştırarak database'i görüntüleyin
///
/// Kullanım:
/// 1. Emülatörde uygulamayı çalıştırın
/// 2. Terminal'de: dart run lib/tools/view_database.dart
///
/// NOT: Bu script sadece geliştirme aşamasında kullanılmalıdır!

Future<void> main() async {
  print('🔍 Algorist Database Viewer\n');
  print('=' * 80);

  try {
    const storage = FlutterSecureStorage();
    final allData = await storage.readAll();

    // Kullanıcıları filtrele
    final users = allData.entries
        .where((e) => e.key.startsWith('user_'))
        .toList();

    print('\n📊 TOPLAM KAYITLI KULLANICI: ${users.length}\n');

    if (users.isEmpty) {
      print('⚠️  Henüz kayıtlı kullanıcı yok.\n');
      return;
    }

    // Tablo başlığı
    print('┌${'─' * 30}┬${'─' * 25}┬${'─' * 20}┐');
    print(
      '│ ${'EMAIL'.padRight(28)} │ ${'AD SOYAD'.padRight(23)} │ ${'KAYIT TARİHİ'.padRight(18)} │',
    );
    print('├${'─' * 30}┼${'─' * 25}┼${'─' * 20}┤');

    for (var entry in users) {
      try {
        final email = entry.key.replaceFirst('user_', '');
        final userData = jsonDecode(entry.value);

        final fullName = userData['fullName'] ?? userData['email'] ?? 'N/A';
        final createdAt = userData['createdAt'] ?? 'N/A';
        final hashedPassword = userData['hashedPassword'] ?? '';
        final salt = userData['salt'] ?? '';

        // Tarih formatla
        String formattedDate = 'N/A';
        if (createdAt != 'N/A') {
          try {
            final date = DateTime.parse(createdAt);
            formattedDate =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (_) {}
        }

        // Tablo satırı
        print(
          '│ ${_truncate(email, 28).padRight(28)} │ ${_truncate(fullName, 23).padRight(23)} │ ${formattedDate.padRight(18)} │',
        );

        // Detaylar
        print(
          '│ ${'└─ Hash: ${_truncate(hashedPassword, 60)}'.padRight(78)} │',
        );
        print('│ ${'└─ Salt: ${_truncate(salt, 60)}'.padRight(78)} │');
        print('├${'─' * 30}┼${'─' * 25}┼${'─' * 20}┤');
      } catch (e) {
        print('│ ${'ERROR: ${entry.key}'.padRight(78)} │');
        print('├${'─' * 30}┼${'─' * 25}┼${'─' * 20}┤');
      }
    }

    print('└${'─' * 30}┴${'─' * 25}┴${'─' * 20}┘\n');

    // Güvenlik bilgisi
    print('🔒 GÜVENLİK BİLGİSİ:');
    print('   • Şifreler SHA-256 + unique salt ile hashlenmiştir');
    print('   • Veriler AES-256 ile şifrelenmiş olarak saklanır');
    print('   • Android Keystore kullanılarak korunur');
    print('   • Root olmadan dosyalara erişim mümkün değildir\n');

    // Database konumu
    print('📁 DATABASE KONUMU:');
    print('   • Android: /data/data/com.example.algorist/shared_prefs/');
    print('   • iOS: Library/Preferences/');
    print(
      '   • Storage: flutter_secure_storage (EncryptedSharedPreferences)\n',
    );

    print('=' * 80);
  } catch (e) {
    print('\n❌ HATA: $e');
    print(
      '\n⚠️  Bu script sadece Flutter uygulaması çalışırken kullanılabilir.',
    );
    print('   Emülatörde uygulamayı başlatın ve tekrar deneyin.\n');
  }
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

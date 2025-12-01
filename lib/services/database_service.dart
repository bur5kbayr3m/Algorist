import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bcrypt/bcrypt.dart';

/// SQLite Database Service - Kalıcı veri saklama
/// Kullanıcı bilgileri ve portföy verileri bu veritabanında saklanır
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'algorist.db');

    debugPrint('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🗄️ Creating database tables...');

    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT UNIQUE,
        phone TEXT UNIQUE,
        profileImage TEXT,
        emailVerified INTEGER DEFAULT 0,
        verificationCode TEXT,
        hashedPassword TEXT NOT NULL,
        salt TEXT NOT NULL,
        provider TEXT DEFAULT 'email',
        createdAt TEXT NOT NULL
      )
    ''');

    // Portföy varlıkları tablosu
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        userEmail TEXT NOT NULL,
        assetId TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        purchasePrice REAL NOT NULL,
        purchaseDate TEXT NOT NULL,
        totalCost REAL NOT NULL,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Kullanıcı tercihleri tablosu
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT UNIQUE NOT NULL,
        enabledWidgets TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userEmail) REFERENCES users (email) ON DELETE CASCADE
      )
    ''');

    // Index'ler
    await db.execute('CREATE INDEX idx_user_email ON users(email)');
    await db.execute('CREATE INDEX idx_asset_user_email ON assets(userEmail)');
    await db.execute('CREATE INDEX idx_asset_id ON assets(assetId)');
    await db.execute(
      'CREATE INDEX idx_preferences_email ON user_preferences(userEmail)',
    );

    debugPrint('✅ Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      // Version 2: user_preferences tablosu ekle
      debugPrint('➕ Adding user_preferences table...');
      await db.execute('''
        CREATE TABLE user_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userEmail TEXT UNIQUE NOT NULL,
          enabledWidgets TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (userEmail) REFERENCES users (email) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_preferences_email ON user_preferences(userEmail)',
      );
      debugPrint('✅ user_preferences table added');
    }

    if (oldVersion < 3) {
      // Version 3: users tablosuna phone ve profileImage kolonları ekle
      debugPrint('➕ Adding phone and profileImage columns to users table...');
      try {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN profileImage TEXT');
        debugPrint('✅ phone and profileImage columns added');
      } catch (e) {
        debugPrint('⚠️ Columns might already exist: $e');
      }
    }

    if (oldVersion < 4) {
      // Version 4: Email verification columns
      debugPrint('➕ Adding email verification columns to users table...');
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN emailVerified INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE users ADD COLUMN verificationCode TEXT');
        debugPrint('✅ Email verification columns added');
      } catch (e) {
        debugPrint('⚠️ Columns might already exist: $e');
      }
    }

    if (oldVersion < 5) {
      // Version 5: Add UNIQUE constraint to fullName and phone
      debugPrint('➕ Adding UNIQUE constraints to fullName and phone...');
      try {
        // SQLite doesn't support ALTER TABLE ADD CONSTRAINT
        // We need to recreate the table with the constraints

        // 1. Create a new table with UNIQUE constraints
        await db.execute('''
          CREATE TABLE users_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            fullName TEXT UNIQUE,
            phone TEXT UNIQUE,
            profileImage TEXT,
            emailVerified INTEGER DEFAULT 0,
            verificationCode TEXT,
            hashedPassword TEXT,
            salt TEXT,
            provider TEXT DEFAULT 'email',
            createdAt TEXT
          )
        ''');

        // 2. Copy data from old table to new table with default values
        await db.execute('''
          INSERT INTO users_new (id, email, fullName, phone, profileImage, emailVerified, verificationCode, hashedPassword, salt, provider, createdAt)
          SELECT id, email, fullName, phone, profileImage, 
                 COALESCE(emailVerified, 0), 
                 verificationCode, 
                 COALESCE(hashedPassword, ''), 
                 COALESCE(salt, ''),
                 COALESCE(provider, 'email'),
                 COALESCE(createdAt, datetime('now'))
          FROM users
        ''');

        // 3. Drop old table
        await db.execute('DROP TABLE users');

        // 4. Rename new table to users
        await db.execute('ALTER TABLE users_new RENAME TO users');

        // 5. Recreate indexes
        await db.execute('CREATE INDEX idx_user_email ON users(email)');

        debugPrint('✅ UNIQUE constraints added to fullName and phone');
      } catch (e) {
        debugPrint('⚠️ Error adding UNIQUE constraints: $e');
      }
    }
  } // ==================== USER OPERATIONS ====================

  /// Yeni kullanıcı kaydet
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      debugPrint('👤 Inserting user: ${user['email']}');
      final id = await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ User inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Error inserting user: $e');
      rethrow;
    }
  }

  /// Email ile kullanıcı bul
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await database;
      debugPrint('🔍 Searching user: $email');
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (results.isEmpty) {
        debugPrint('❌ User not found: $email');
        return null;
      }

      debugPrint('✅ User found: $email');
      return results.first;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  /// İsme göre kullanıcı getir
  Future<Map<String, dynamic>?> getUserByFullName(String fullName) async {
    try {
      final db = await database;
      debugPrint('🔍 Searching user by name: $fullName');
      final results = await db.query(
        'users',
        where: 'fullName = ?',
        whereArgs: [fullName],
        limit: 1,
      );

      if (results.isEmpty) {
        debugPrint('❌ User not found by name: $fullName');
        return null;
      }

      debugPrint('✅ User found by name: $fullName');
      return results.first;
    } catch (e) {
      debugPrint('❌ Error getting user by name: $e');
      return null;
    }
  }

  /// Telefona göre kullanıcı getir
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final db = await database;
      debugPrint('🔍 Searching user by phone: $phone');
      final results = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );

      if (results.isEmpty) {
        debugPrint('❌ User not found by phone: $phone');
        return null;
      }

      debugPrint('✅ User found by phone: $phone');
      return results.first;
    } catch (e) {
      debugPrint('❌ Error getting user by phone: $e');
      return null;
    }
  }

  /// Kullanıcı var mı kontrol et
  Future<bool> userExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  /// Kullanıcı sil
  Future<void> deleteUser(String email) async {
    try {
      final db = await database;
      debugPrint('🗑️ Deleting user: $email');
      await db.delete('users', where: 'email = ?', whereArgs: [email]);
      debugPrint('✅ User deleted');
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateUserProfile(
    String email, {
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final db = await database;
      debugPrint('✏️ Updating profile for: $email');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      if (updates.isEmpty) {
        debugPrint('⚠️ No updates provided');
        return;
      }

      await db.update('users', updates, where: 'email = ?', whereArgs: [email]);
      debugPrint('✅ Profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Kullanıcı şifresini güncelle
  Future<void> updateUserPassword(String email, String newPassword) async {
    try {
      final db = await database;
      debugPrint('🔐 Updating password for: $email');

      // Bcrypt ile şifreyi hashle
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      await db.update(
        'users',
        {'hashedPassword': hashedPassword, 'salt': 'bcrypt'},
        where: 'email = ?',
        whereArgs: [email],
      );
      debugPrint('✅ Password updated successfully with bcrypt');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  /// Şifre doğrulama (bcrypt)
  bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      debugPrint('❌ Error verifying password: $e');
      return false;
    }
  }

  /// Yeni kullanıcı için şifre hashle (bcrypt)
  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // ==================== ASSET OPERATIONS ====================

  /// Varlık ekle
  Future<int> insertAsset(Map<String, dynamic> asset) async {
    try {
      final db = await database;
      debugPrint(
        '💰 Inserting asset: ${asset['name']} for ${asset['userEmail']}',
      );
      final id = await db.insert(
        'assets',
        asset,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Asset inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Error inserting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını getir
  Future<List<Map<String, dynamic>>> getUserAssets(String userEmail) async {
    try {
      final db = await database;
      debugPrint('📊 Getting assets for: $userEmail');
      final results = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [userEmail],
        orderBy: 'addedAt DESC',
      );
      debugPrint('✅ Found ${results.length} assets');
      return results;
    } catch (e) {
      debugPrint('❌ Error getting assets: $e');
      return [];
    }
  }

  /// Varlık güncelle
  Future<void> updateAsset(String assetId, Map<String, dynamic> asset) async {
    try {
      final db = await database;
      debugPrint('📝 Updating asset: $assetId');
      await db.update(
        'assets',
        asset,
        where: 'assetId = ?',
        whereArgs: [assetId],
      );
      debugPrint('✅ Asset updated');
    } catch (e) {
      debugPrint('❌ Error updating asset: $e');
      rethrow;
    }
  }

  /// Varlık sil
  Future<void> deleteAsset(String assetId) async {
    try {
      final db = await database;
      debugPrint('🗑️ Deleting asset: $assetId');
      await db.delete('assets', where: 'assetId = ?', whereArgs: [assetId]);
      debugPrint('✅ Asset deleted');
    } catch (e) {
      debugPrint('❌ Error deleting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını sil
  Future<void> deleteUserAssets(String userEmail) async {
    try {
      final db = await database;
      debugPrint('🗑️ Deleting all assets for: $userEmail');
      await db.delete('assets', where: 'userEmail = ?', whereArgs: [userEmail]);
      debugPrint('✅ All assets deleted');
    } catch (e) {
      debugPrint('❌ Error deleting assets: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  /// Widget tercihlerini kaydet
  Future<void> saveWidgetPreferences(
    String userEmail,
    List<String> enabledWidgets,
  ) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final widgetsJson = enabledWidgets.join(',');

      // Önce mevcut tercihi kontrol et
      final existing = await db.query(
        'user_preferences',
        where: 'userEmail = ?',
        whereArgs: [userEmail],
      );

      if (existing.isEmpty) {
        // Yeni tercih ekle
        await db.insert('user_preferences', {
          'userEmail': userEmail,
          'enabledWidgets': widgetsJson,
          'updatedAt': now,
        });
        debugPrint('✅ Widget preferences created for: $userEmail');
      } else {
        // Mevcut tercihi güncelle
        await db.update(
          'user_preferences',
          {'enabledWidgets': widgetsJson, 'updatedAt': now},
          where: 'userEmail = ?',
          whereArgs: [userEmail],
        );
        debugPrint('✅ Widget preferences updated for: $userEmail');
      }
    } catch (e) {
      debugPrint('❌ Error saving widget preferences: $e');
      rethrow;
    }
  }

  /// Widget tercihlerini yükle
  Future<List<String>> loadWidgetPreferences(String userEmail) async {
    try {
      final db = await database;
      final result = await db.query(
        'user_preferences',
        where: 'userEmail = ?',
        whereArgs: [userEmail],
      );

      if (result.isEmpty) {
        debugPrint('ℹ️ No widget preferences found for: $userEmail');
        return [];
      }

      final widgetsJson = result.first['enabledWidgets'] as String;
      final widgets = widgetsJson.isEmpty ? <String>[] : widgetsJson.split(',');

      debugPrint(
        '✅ Loaded ${widgets.length} widget preferences for: $userEmail',
      );
      return widgets;
    } catch (e) {
      debugPrint('❌ Error loading widget preferences: $e');
      return [];
    }
  }

  // ==================== UTILITY ====================

  /// Veritabanı istatistikleri
  Future<Map<String, int>> getStats() async {
    try {
      final db = await database;
      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users'),
      );
      final assetCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM assets'),
      );

      return {'users': userCount ?? 0, 'assets': assetCount ?? 0};
    } catch (e) {
      debugPrint('❌ Error getting stats: $e');
      return {'users': 0, 'assets': 0};
    }
  }

  /// Tüm veritabanı verilerini listele (Debug için)
  Future<void> printAllData() async {
    try {
      final db = await database;

      debugPrint('\n${'=' * 60}');
      debugPrint('📊 VERITABANI DUMP - TÜM VERİLER');
      debugPrint('=' * 60);

      // Kullanıcıları listele
      final users = await db.query('users');
      debugPrint('\n👥 KULLANICILAR (${users.length} kayıt):');
      debugPrint('-' * 60);
      for (var user in users) {
        debugPrint('ID: ${user['id']}');
        debugPrint('  Email: ${user['email']}');
        debugPrint('  İsim: ${user['fullName']}');
        debugPrint('  Provider: ${user['provider']}');
        debugPrint('  Oluşturma: ${user['createdAt']}');
        debugPrint(
          '  Hash: ${(user['hashedPassword'] as String).substring(0, 20)}...',
        );
        debugPrint('  Salt: ${(user['salt'] as String).substring(0, 10)}...');
        debugPrint('-' * 60);
      }

      // Asset'leri listele
      final assets = await db.query('assets');
      debugPrint('\n💰 VARLIKLAR (${assets.length} kayıt):');
      debugPrint('-' * 60);
      for (var asset in assets) {
        debugPrint('ID: ${asset['id']}');
        debugPrint('  Asset ID: ${asset['assetId']}');
        debugPrint('  Kullanıcı: ${asset['userEmail']}');
        debugPrint('  Tip: ${asset['type']}');
        debugPrint('  İsim: ${asset['name']}');
        debugPrint('  Miktar: ${asset['quantity']}');
        debugPrint('  Alış Fiyatı: ₺${asset['purchasePrice']}');
        debugPrint('  Toplam Maliyet: ₺${asset['totalCost']}');
        debugPrint('  Alış Tarihi: ${asset['purchaseDate']}');
        debugPrint('  Eklenme: ${asset['addedAt']}');
        debugPrint('-' * 60);
      }

      debugPrint('\n📈 İSTATİSTİKLER:');
      debugPrint('  Toplam Kullanıcı: ${users.length}');
      debugPrint('  Toplam Varlık: ${assets.length}');
      debugPrint('=' * 60 + '\n');
    } catch (e) {
      debugPrint('❌ Error printing data: $e');
    }
  }

  /// Kullanıcıya ait tüm verileri listele
  Future<void> printUserData(String email) async {
    try {
      final db = await database;

      debugPrint('\n${'=' * 60}');
      debugPrint('📊 KULLANICI VERİLERİ: $email');
      debugPrint('=' * 60);

      // Kullanıcı bilgisi
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (users.isEmpty) {
        debugPrint('❌ Kullanıcı bulunamadı!');
        return;
      }

      final user = users.first;
      debugPrint('\n👤 KULLANICI BİLGİSİ:');
      debugPrint('  ID: ${user['id']}');
      debugPrint('  Email: ${user['email']}');
      debugPrint('  İsim: ${user['fullName']}');
      debugPrint('  Provider: ${user['provider']}');
      debugPrint('  Oluşturma: ${user['createdAt']}');

      // Kullanıcının varlıkları
      final assets = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [email],
      );
      debugPrint('\n💰 VARLIKLAR (${assets.length} adet):');
      debugPrint('-' * 60);

      if (assets.isEmpty) {
        debugPrint('  Henüz varlık eklenmemiş.');
      } else {
        double totalValue = 0;
        for (var asset in assets) {
          debugPrint('${asset['name']} (${asset['type']})');
          debugPrint('  Miktar: ${asset['quantity']}');
          debugPrint('  Alış: ₺${asset['purchasePrice']}');
          debugPrint('  Toplam: ₺${asset['totalCost']}');
          debugPrint('  Tarih: ${asset['purchaseDate']}');
          debugPrint('-' * 60);
          totalValue += (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
        }
        debugPrint(
          '\n💵 TOPLAM PORTFÖY DEĞERİ: ₺${totalValue.toStringAsFixed(2)}',
        );
      }

      debugPrint('=' * 60 + '\n');
    } catch (e) {
      debugPrint('❌ Error printing user data: $e');
    }
  }

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('🔒 Database closed');
  }

  /// Veritabanını sıfırla (sadece development için!)
  Future<void> resetDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'algorist.db');

      await close();
      await deleteDatabase(path);

      _database = null;
      debugPrint('🔄 Database reset completed');
    } catch (e) {
      debugPrint('❌ Error resetting database: $e');
    }
  }

  /// Kullanıcı tercihlerini getir
  Future<Map<String, bool>?> getUserPreferences(String email) async {
    try {
      final db = await database;
      final results = await db.query(
        'user_preferences',
        where: 'userEmail = ?',
        whereArgs: [email],
      );

      if (results.isEmpty) {
        // Varsayılan tercihler
        return {
          'pushNotifications': true,
          'emailNotifications': false,
          'darkMode': true,
        };
      }

      final prefs = results.first;
      final enabledWidgets = prefs['enabledWidgets'] as String? ?? '';

      // enabledWidgets alanını kullanarak tercihleri parse et
      // Format: "pushNotifications:true,emailNotifications:false,darkMode:true"
      final Map<String, bool> preferences = {
        'pushNotifications': true,
        'emailNotifications': false,
        'darkMode': true,
      };

      if (enabledWidgets.contains('preferences:')) {
        final prefPart = enabledWidgets
            .split('preferences:')
            .last
            .split(';')
            .first;
        final items = prefPart.split(',');
        for (var item in items) {
          if (item.contains(':')) {
            final parts = item.split(':');
            if (parts.length == 2) {
              preferences[parts[0]] = parts[1] == 'true';
            }
          }
        }
      }

      return preferences;
    } catch (e) {
      debugPrint('❌ Error getting user preferences: $e');
      return null;
    }
  }

  /// Tek bir tercihi kaydet
  Future<void> saveUserPreference(String email, String key, bool value) async {
    try {
      final db = await database;

      // Mevcut tercihleri getir
      final results = await db.query(
        'user_preferences',
        where: 'userEmail = ?',
        whereArgs: [email],
      );

      String enabledWidgets = '';
      Map<String, bool> preferences = {
        'pushNotifications': true,
        'emailNotifications': false,
        'darkMode': true,
      };

      if (results.isNotEmpty) {
        enabledWidgets = results.first['enabledWidgets'] as String? ?? '';

        // Mevcut widget tercihlerini koru
        final widgetsPart = enabledWidgets.split(';preferences:').first;

        // Mevcut preferences'ı parse et
        if (enabledWidgets.contains('preferences:')) {
          final prefPart = enabledWidgets
              .split('preferences:')
              .last
              .split(';')
              .first;
          final items = prefPart.split(',');
          for (var item in items) {
            if (item.contains(':')) {
              final parts = item.split(':');
              if (parts.length == 2) {
                preferences[parts[0]] = parts[1] == 'true';
              }
            }
          }
        }

        // Yeni tercihi güncelle
        preferences[key] = value;

        // Yeni formatı oluştur
        final prefsString = preferences.entries
            .map((e) => '${e.key}:${e.value}')
            .join(',');
        enabledWidgets = '$widgetsPart;preferences:$prefsString';

        await db.update(
          'user_preferences',
          {
            'enabledWidgets': enabledWidgets,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'userEmail = ?',
          whereArgs: [email],
        );
      } else {
        // Yeni kayıt oluştur
        preferences[key] = value;
        final prefsString = preferences.entries
            .map((e) => '${e.key}:${e.value}')
            .join(',');
        enabledWidgets = ';preferences:$prefsString';

        await db.insert('user_preferences', {
          'userEmail': email,
          'enabledWidgets': enabledWidgets,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ Preference saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Error saving user preference: $e');
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bcrypt/bcrypt.dart';
import '../utils/app_logger.dart';

/// SQLite Database Service - Kalıcı veri saklama
/// Kullanıcı bilgileri ve portföy verileri bu veritabanında saklanır
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _database;

  // Cache için
  final Map<String, Map<String, dynamic>?> _userCache = {};
  final Map<String, List<Map<String, dynamic>>> _assetsCache = {};
  Timer? _cacheTimer;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();

    // Cache temizleme timer'ı (5 dakikada bir)
    _cacheTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      _userCache.clear();
      _assetsCache.clear();
      AppLogger.log('🧹 Cache cleared');
    });

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'algorist.db');

    AppLogger.log('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.log('🗄️ Creating database tables...');

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

    AppLogger.log('✅ Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.log('🔄 Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      // Version 2: user_preferences tablosu ekle
      AppLogger.log('➕ Adding user_preferences table...');
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
      AppLogger.log('✅ user_preferences table added');
    }

    if (oldVersion < 3) {
      // Version 3: users tablosuna phone ve profileImage kolonları ekle
      AppLogger.log(
        '➕ Adding phone and profileImage columns to users table...',
      );
      try {
        await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN profileImage TEXT');
        AppLogger.log('✅ phone and profileImage columns added');
      } catch (e) {
        AppLogger.log('⚠️ Columns might already exist: $e');
      }
    }

    if (oldVersion < 4) {
      // Version 4: Email verification columns
      AppLogger.log('➕ Adding email verification columns to users table...');
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN emailVerified INTEGER DEFAULT 0',
        );
        await db.execute('ALTER TABLE users ADD COLUMN verificationCode TEXT');
        AppLogger.log('✅ Email verification columns added');
      } catch (e) {
        AppLogger.log('⚠️ Columns might already exist: $e');
      }
    }

    if (oldVersion < 5) {
      // Version 5: Add UNIQUE constraint to fullName and phone
      AppLogger.log('➕ Adding UNIQUE constraints to fullName and phone...');
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

        AppLogger.log('✅ UNIQUE constraints added to fullName and phone');
      } catch (e) {
        AppLogger.log('⚠️ Error adding UNIQUE constraints: $e');
      }
    }
  } // ==================== USER OPERATIONS ====================

  /// Yeni kullanıcı kaydet
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      AppLogger.log('👤 Inserting user: ${user['email']}');
      final id = await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.log('✅ User inserted with ID: $id');
      return id;
    } catch (e) {
      AppLogger.log('❌ Error inserting user: $e');
      rethrow;
    }
  }

  /// Email ile kullanıcı bul (Cache'li)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      // Cache'de var mı kontrol et
      if (_userCache.containsKey(email)) {
        AppLogger.log('💾 User found in cache: $email');
        return _userCache[email];
      }

      final db = await database;
      AppLogger.log('🔍 Searching user in DB: $email');
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (results.isEmpty) {
        _userCache[email] = null;
        return null;
      }

      // Cache'e ekle
      _userCache[email] = results.first;
      AppLogger.log('✅ User found and cached: $email');
      return results.first;
    } catch (e) {
      AppLogger.log('❌ Error getting user: $e');
      return null;
    }
  }

  /// İsme göre kullanıcı getir
  Future<Map<String, dynamic>?> getUserByFullName(String fullName) async {
    try {
      final db = await database;
      AppLogger.log('🔍 Searching user by name: $fullName');
      final results = await db.query(
        'users',
        where: 'fullName = ?',
        whereArgs: [fullName],
        limit: 1,
      );

      if (results.isEmpty) {
        AppLogger.log('❌ User not found by name: $fullName');
        return null;
      }

      AppLogger.log('✅ User found by name: $fullName');
      return results.first;
    } catch (e) {
      AppLogger.log('❌ Error getting user by name: $e');
      return null;
    }
  }

  /// Telefona göre kullanıcı getir
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final db = await database;
      AppLogger.log('🔍 Searching user by phone: $phone');
      final results = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );

      if (results.isEmpty) {
        AppLogger.log('❌ User not found by phone: $phone');
        return null;
      }

      AppLogger.log('✅ User found by phone: $phone');
      return results.first;
    } catch (e) {
      AppLogger.log('❌ Error getting user by phone: $e');
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
      AppLogger.log('🗑️ Deleting user: $email');
      await db.delete('users', where: 'email = ?', whereArgs: [email]);
      AppLogger.log('✅ User deleted');
    } catch (e) {
      AppLogger.log('❌ Error deleting user: $e');
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
      AppLogger.log('✏️ Updating profile for: $email');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      if (updates.isEmpty) {
        AppLogger.log('⚠️ No updates provided');
        return;
      }

      await db.update('users', updates, where: 'email = ?', whereArgs: [email]);
      AppLogger.log('✅ Profile updated successfully');
    } catch (e) {
      AppLogger.log('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Kullanıcı şifresini güncelle
  Future<void> updateUserPassword(String email, String newPassword) async {
    try {
      final db = await database;
      AppLogger.log('🔐 Updating password for: $email');

      // Bcrypt ile şifreyi hashle
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      await db.update(
        'users',
        {'hashedPassword': hashedPassword, 'salt': 'bcrypt'},
        where: 'email = ?',
        whereArgs: [email],
      );
      AppLogger.log('✅ Password updated successfully with bcrypt');
    } catch (e) {
      AppLogger.log('❌ Error updating password: $e');
      rethrow;
    }
  }

  /// Şifre doğrulama (bcrypt)
  bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      AppLogger.log('❌ Error verifying password: $e');
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
      AppLogger.log(
        '💰 Inserting asset: ${asset['name']} for ${asset['userEmail']}',
      );
      final id = await db.insert(
        'assets',
        asset,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cache'i invalidate et
      final userEmail = asset['userEmail'] as String;
      _assetsCache.remove(userEmail);

      AppLogger.log('✅ Asset inserted with ID: $id');
      return id;
    } catch (e) {
      AppLogger.log('❌ Error inserting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını getir (Cache'li)
  Future<List<Map<String, dynamic>>> getUserAssets(String userEmail) async {
    try {
      // Cache'de var mı kontrol et
      if (_assetsCache.containsKey(userEmail)) {
        AppLogger.log('💾 Assets found in cache: $userEmail');
        return _assetsCache[userEmail]!;
      }

      final db = await database;
      AppLogger.log('📊 Getting assets from DB: $userEmail');
      final results = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [userEmail],
        orderBy: 'addedAt DESC',
      );

      // Cache'e ekle
      _assetsCache[userEmail] = results;
      AppLogger.log('✅ Found and cached ${results.length} assets');
      return results;
    } catch (e) {
      AppLogger.log('❌ Error getting assets: $e');
      return [];
    }
  }

  /// Varlık güncelle
  Future<void> updateAsset(String assetId, Map<String, dynamic> asset) async {
    try {
      final db = await database;
      AppLogger.log('📝 Updating asset: $assetId');
      await db.update(
        'assets',
        asset,
        where: 'assetId = ?',
        whereArgs: [assetId],
      );
      AppLogger.log('✅ Asset updated');
    } catch (e) {
      AppLogger.log('❌ Error updating asset: $e');
      rethrow;
    }
  }

  /// Varlık sil
  Future<void> deleteAsset(String assetId) async {
    try {
      final db = await database;
      AppLogger.log('🗑️ Deleting asset: $assetId');
      await db.delete('assets', where: 'assetId = ?', whereArgs: [assetId]);
      AppLogger.log('✅ Asset deleted');
    } catch (e) {
      AppLogger.log('❌ Error deleting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını sil
  Future<void> deleteUserAssets(String userEmail) async {
    try {
      final db = await database;
      AppLogger.log('🗑️ Deleting all assets for: $userEmail');
      await db.delete('assets', where: 'userEmail = ?', whereArgs: [userEmail]);
      AppLogger.log('✅ All assets deleted');
    } catch (e) {
      AppLogger.log('❌ Error deleting assets: $e');
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
        AppLogger.log('✅ Widget preferences created for: $userEmail');
      } else {
        // Mevcut tercihi güncelle
        await db.update(
          'user_preferences',
          {'enabledWidgets': widgetsJson, 'updatedAt': now},
          where: 'userEmail = ?',
          whereArgs: [userEmail],
        );
        AppLogger.log('✅ Widget preferences updated for: $userEmail');
      }
    } catch (e) {
      AppLogger.log('❌ Error saving widget preferences: $e');
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
        AppLogger.log('ℹ️ No widget preferences found for: $userEmail');
        return [];
      }

      final widgetsJson = result.first['enabledWidgets'] as String;
      final widgets = widgetsJson.isEmpty ? <String>[] : widgetsJson.split(',');

      debugPrint(
        '✅ Loaded ${widgets.length} widget preferences for: $userEmail',
      );
      return widgets;
    } catch (e) {
      AppLogger.log('❌ Error loading widget preferences: $e');
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
      AppLogger.log('❌ Error getting stats: $e');
      return {'users': 0, 'assets': 0};
    }
  }

  /// Tüm veritabanı verilerini listele (Debug için)
  Future<void> printAllData() async {
    try {
      final db = await database;

      AppLogger.log('\n${'=' * 60}');
      AppLogger.log('📊 VERITABANI DUMP - TÜM VERİLER');
      AppLogger.log('=' * 60);

      // Kullanıcıları listele
      final users = await db.query('users');
      AppLogger.log('\n👥 KULLANICILAR (${users.length} kayıt):');
      AppLogger.log('-' * 60);
      for (var user in users) {
        AppLogger.log('ID: ${user['id']}');
        AppLogger.log('  Email: ${user['email']}');
        AppLogger.log('  İsim: ${user['fullName']}');
        AppLogger.log('  Provider: ${user['provider']}');
        AppLogger.log('  Oluşturma: ${user['createdAt']}');
        debugPrint(
          '  Hash: ${(user['hashedPassword'] as String).substring(0, 20)}...',
        );
        AppLogger.log(
          '  Salt: ${(user['salt'] as String).substring(0, 10)}...',
        );
        AppLogger.log('-' * 60);
      }

      // Asset'leri listele
      final assets = await db.query('assets');
      AppLogger.log('\n💰 VARLIKLAR (${assets.length} kayıt):');
      AppLogger.log('-' * 60);
      for (var asset in assets) {
        AppLogger.log('ID: ${asset['id']}');
        AppLogger.log('  Asset ID: ${asset['assetId']}');
        AppLogger.log('  Kullanıcı: ${asset['userEmail']}');
        AppLogger.log('  Tip: ${asset['type']}');
        AppLogger.log('  İsim: ${asset['name']}');
        AppLogger.log('  Miktar: ${asset['quantity']}');
        AppLogger.log('  Alış Fiyatı: ₺${asset['purchasePrice']}');
        AppLogger.log('  Toplam Maliyet: ₺${asset['totalCost']}');
        AppLogger.log('  Alış Tarihi: ${asset['purchaseDate']}');
        AppLogger.log('  Eklenme: ${asset['addedAt']}');
        AppLogger.log('-' * 60);
      }

      AppLogger.log('\n📈 İSTATİSTİKLER:');
      AppLogger.log('  Toplam Kullanıcı: ${users.length}');
      AppLogger.log('  Toplam Varlık: ${assets.length}');
      AppLogger.log('=' * 60 + '\n');
    } catch (e) {
      AppLogger.log('❌ Error printing data: $e');
    }
  }

  /// Kullanıcıya ait tüm verileri listele
  Future<void> printUserData(String email) async {
    try {
      final db = await database;

      AppLogger.log('\n${'=' * 60}');
      AppLogger.log('📊 KULLANICI VERİLERİ: $email');
      AppLogger.log('=' * 60);

      // Kullanıcı bilgisi
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (users.isEmpty) {
        AppLogger.log('❌ Kullanıcı bulunamadı!');
        return;
      }

      final user = users.first;
      AppLogger.log('\n👤 KULLANICI BİLGİSİ:');
      AppLogger.log('  ID: ${user['id']}');
      AppLogger.log('  Email: ${user['email']}');
      AppLogger.log('  İsim: ${user['fullName']}');
      AppLogger.log('  Provider: ${user['provider']}');
      AppLogger.log('  Oluşturma: ${user['createdAt']}');

      // Kullanıcının varlıkları
      final assets = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [email],
      );
      AppLogger.log('\n💰 VARLIKLAR (${assets.length} adet):');
      AppLogger.log('-' * 60);

      if (assets.isEmpty) {
        AppLogger.log('  Henüz varlık eklenmemiş.');
      } else {
        double totalValue = 0;
        for (var asset in assets) {
          AppLogger.log('${asset['name']} (${asset['type']})');
          AppLogger.log('  Miktar: ${asset['quantity']}');
          AppLogger.log('  Alış: ₺${asset['purchasePrice']}');
          AppLogger.log('  Toplam: ₺${asset['totalCost']}');
          AppLogger.log('  Tarih: ${asset['purchaseDate']}');
          AppLogger.log('-' * 60);
          totalValue += (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
        }
        debugPrint(
          '\n💵 TOPLAM PORTFÖY DEĞERİ: ₺${totalValue.toStringAsFixed(2)}',
        );
      }

      AppLogger.log('=' * 60 + '\n');
    } catch (e) {
      AppLogger.log('❌ Error printing user data: $e');
    }
  }

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    AppLogger.log('🔒 Database closed');
  }

  /// Veritabanını sıfırla (sadece development için!)
  Future<void> resetDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'algorist.db');

      await close();
      await deleteDatabase(path);

      _database = null;
      AppLogger.log('🔄 Database reset completed');
    } catch (e) {
      AppLogger.log('❌ Error resetting database: $e');
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
      AppLogger.log('❌ Error getting user preferences: $e');
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

      AppLogger.log('✅ Preference saved: $key = $value');
    } catch (e) {
      AppLogger.log('❌ Error saving user preference: $e');
    }
  }

  /// Şifre sıfırlama kodu oluşturur ve kaydeder
  Future<String?> generatePasswordResetCode(String email) async {
    try {
      final db = await database;

      // Kullanıcı var mı kontrol et
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        AppLogger.log('❌ User not found: $email');
        return null;
      }

      // 6 haneli kod oluştur
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString();

      // Kodu veritabanına kaydet (son kullanma süresini de ekle - 30 dakika geçerlilik)
      // Ayırıcı olarak '|||' kullan (ISO8601 tarihinde ':' var)
      final codeWithExpiry =
          '$code|||${DateTime.now().add(const Duration(minutes: 30)).toIso8601String()}';

      await db.update(
        'users',
        {'verificationCode': codeWithExpiry},
        where: 'email = ?',
        whereArgs: [email],
      );

      AppLogger.log('✅ Password reset code generated for $email: $code');
      return code;
    } catch (e) {
      AppLogger.log('❌ Error generating reset code: $e');
      return null;
    }
  }

  /// Şifre sıfırlama kodunu doğrular
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    try {
      final db = await database;

      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        AppLogger.log('❌ User not found: $email');
        return false;
      }

      final user = result.first;
      final storedCodeData = user['verificationCode'] as String?;

      AppLogger.log('🔍 Checking code for $email');
      AppLogger.log('   Stored data: $storedCodeData');
      AppLogger.log('   Input code: $code');

      if (storedCodeData == null || storedCodeData.isEmpty) {
        AppLogger.log('❌ No verification code found');
        return false;
      }

      // Kodu ve son kullanma süresini ayır (ayırıcı: |||)
      final parts = storedCodeData.split('|||');
      if (parts.length != 2) {
        AppLogger.log('❌ Invalid code format - parts: ${parts.length}');
        return false;
      }

      final storedCode = parts[0];
      final expiryTime = DateTime.parse(parts[1]);

      AppLogger.log('   Stored code: $storedCode');
      AppLogger.log('   Expiry time: $expiryTime');
      AppLogger.log('   Current time: ${DateTime.now()}');

      // Süre dolmuş mu kontrol et
      if (DateTime.now().isAfter(expiryTime)) {
        AppLogger.log('❌ Verification code expired');
        return false;
      }

      // Kodu doğrula (trim ile boşlukları temizle)
      if (storedCode.trim() != code.trim()) {
        AppLogger.log('❌ Invalid verification code');
        AppLogger.log('   Expected: "${storedCode.trim()}"');
        AppLogger.log('   Received: "${code.trim()}"');
        return false;
      }

      AppLogger.log('✅ Password reset code verified for $email');
      return true;
    } catch (e) {
      AppLogger.log('❌ Error verifying reset code: $e');
      return false;
    }
  }

  /// Şifre sıfırlama kodunu temizler
  Future<void> clearPasswordResetCode(String email) async {
    try {
      final db = await database;
      await db.update(
        'users',
        {'verificationCode': null},
        where: 'email = ?',
        whereArgs: [email],
      );
      AppLogger.log('✅ Reset code cleared for $email');
    } catch (e) {
      AppLogger.log('❌ Error clearing reset code: $e');
    }
  }

  /// DEBUG: Tüm kullanıcıları listele (şifreler hash'li olarak)
  Future<void> debugListAllUsers() async {
    try {
      final db = await database;
      final users = await db.query('users', orderBy: 'id ASC');

      AppLogger.log(
        '\n═══════════════════════════════════════════════════════',
      );
      AppLogger.log(
        '📋 KAYITLI KULLANICILAR LİSTESİ (${users.length} kullanıcı)',
      );
      AppLogger.log(
        '═══════════════════════════════════════════════════════\n',
      );

      for (var user in users) {
        AppLogger.log('👤 ID: ${user['id']}');
        AppLogger.log('   Email: ${user['email']}');
        AppLogger.log('   Ad Soyad: ${user['fullName'] ?? 'Belirtilmemiş'}');
        AppLogger.log('   Telefon: ${user['phone'] ?? 'Belirtilmemiş'}');
        debugPrint(
          '   Email Doğrulandı: ${user['emailVerified'] == 1 ? 'Evet ✓' : 'Hayır ✗'}',
        );
        AppLogger.log('   Şifre Hash: ${user['hashedPassword']}');
        AppLogger.log('   Salt: ${user['salt']}');
        AppLogger.log('   Provider: ${user['provider']}');
        AppLogger.log('   Kayıt Tarihi: ${user['createdAt']}');
        debugPrint(
          '   ─────────────────────────────────────────────────────\n',
        );
      }

      AppLogger.log(
        '═══════════════════════════════════════════════════════\n',
      );
    } catch (e) {
      AppLogger.log('❌ Kullanıcıları listelerken hata: $e');
    }
  }

  /// DEBUG: Belirli bir kullanıcının şifresini test et
  Future<bool> debugTestPassword(String email, String testPassword) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        AppLogger.log('❌ Kullanıcı bulunamadı: $email');
        return false;
      }

      final user = result.first;
      final hashedPassword = user['hashedPassword'] as String;
      final isValid = BCrypt.checkpw(testPassword, hashedPassword);

      AppLogger.log('🔐 Şifre testi: $email');
      AppLogger.log('   Test şifre: $testPassword');
      AppLogger.log('   Sonuç: ${isValid ? 'DOĞRU ✓' : 'YANLIŞ ✗'}');

      return isValid;
    } catch (e) {
      AppLogger.log('❌ Şifre test hatası: $e');
      return false;
    }
  }
}

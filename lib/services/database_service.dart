import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

    print('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🗄️ Creating database tables...');

    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT,
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

    // Index'ler
    await db.execute('CREATE INDEX idx_user_email ON users(email)');
    await db.execute('CREATE INDEX idx_asset_user_email ON assets(userEmail)');
    await db.execute('CREATE INDEX idx_asset_id ON assets(assetId)');

    print('✅ Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from v$oldVersion to v$newVersion');
    // Gelecekteki versiyon güncellemeleri için
  }

  // ==================== USER OPERATIONS ====================

  /// Yeni kullanıcı kaydet
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      print('👤 Inserting user: ${user['email']}');
      final id = await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ User inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting user: $e');
      rethrow;
    }
  }

  /// Email ile kullanıcı bul
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await database;
      print('🔍 Searching user: $email');
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (results.isEmpty) {
        print('❌ User not found: $email');
        return null;
      }

      print('✅ User found: $email');
      return results.first;
    } catch (e) {
      print('❌ Error getting user: $e');
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
      print('🗑️ Deleting user: $email');
      await db.delete('users', where: 'email = ?', whereArgs: [email]);
      print('✅ User deleted');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ==================== ASSET OPERATIONS ====================

  /// Varlık ekle
  Future<int> insertAsset(Map<String, dynamic> asset) async {
    try {
      final db = await database;
      print('💰 Inserting asset: ${asset['name']} for ${asset['userEmail']}');
      final id = await db.insert(
        'assets',
        asset,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Asset inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error inserting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını getir
  Future<List<Map<String, dynamic>>> getUserAssets(String userEmail) async {
    try {
      final db = await database;
      print('📊 Getting assets for: $userEmail');
      final results = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [userEmail],
        orderBy: 'addedAt DESC',
      );
      print('✅ Found ${results.length} assets');
      return results;
    } catch (e) {
      print('❌ Error getting assets: $e');
      return [];
    }
  }

  /// Varlık güncelle
  Future<void> updateAsset(String assetId, Map<String, dynamic> asset) async {
    try {
      final db = await database;
      print('📝 Updating asset: $assetId');
      await db.update(
        'assets',
        asset,
        where: 'assetId = ?',
        whereArgs: [assetId],
      );
      print('✅ Asset updated');
    } catch (e) {
      print('❌ Error updating asset: $e');
      rethrow;
    }
  }

  /// Varlık sil
  Future<void> deleteAsset(String assetId) async {
    try {
      final db = await database;
      print('🗑️ Deleting asset: $assetId');
      await db.delete('assets', where: 'assetId = ?', whereArgs: [assetId]);
      print('✅ Asset deleted');
    } catch (e) {
      print('❌ Error deleting asset: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm varlıklarını sil
  Future<void> deleteUserAssets(String userEmail) async {
    try {
      final db = await database;
      print('🗑️ Deleting all assets for: $userEmail');
      await db.delete('assets', where: 'userEmail = ?', whereArgs: [userEmail]);
      print('✅ All assets deleted');
    } catch (e) {
      print('❌ Error deleting assets: $e');
      rethrow;
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
      print('❌ Error getting stats: $e');
      return {'users': 0, 'assets': 0};
    }
  }

  /// Tüm veritabanı verilerini listele (Debug için)
  Future<void> printAllData() async {
    try {
      final db = await database;

      print('\n' + '=' * 60);
      print('📊 VERITABANI DUMP - TÜM VERİLER');
      print('=' * 60);

      // Kullanıcıları listele
      final users = await db.query('users');
      print('\n👥 KULLANICILAR (${users.length} kayıt):');
      print('-' * 60);
      for (var user in users) {
        print('ID: ${user['id']}');
        print('  Email: ${user['email']}');
        print('  İsim: ${user['fullName']}');
        print('  Provider: ${user['provider']}');
        print('  Oluşturma: ${user['createdAt']}');
        print(
          '  Hash: ${(user['hashedPassword'] as String).substring(0, 20)}...',
        );
        print('  Salt: ${(user['salt'] as String).substring(0, 10)}...');
        print('-' * 60);
      }

      // Asset'leri listele
      final assets = await db.query('assets');
      print('\n💰 VARLIKLAR (${assets.length} kayıt):');
      print('-' * 60);
      for (var asset in assets) {
        print('ID: ${asset['id']}');
        print('  Asset ID: ${asset['assetId']}');
        print('  Kullanıcı: ${asset['userEmail']}');
        print('  Tip: ${asset['type']}');
        print('  İsim: ${asset['name']}');
        print('  Miktar: ${asset['quantity']}');
        print('  Alış Fiyatı: ₺${asset['purchasePrice']}');
        print('  Toplam Maliyet: ₺${asset['totalCost']}');
        print('  Alış Tarihi: ${asset['purchaseDate']}');
        print('  Eklenme: ${asset['addedAt']}');
        print('-' * 60);
      }

      print('\n📈 İSTATİSTİKLER:');
      print('  Toplam Kullanıcı: ${users.length}');
      print('  Toplam Varlık: ${assets.length}');
      print('=' * 60 + '\n');
    } catch (e) {
      print('❌ Error printing data: $e');
    }
  }

  /// Kullanıcıya ait tüm verileri listele
  Future<void> printUserData(String email) async {
    try {
      final db = await database;

      print('\n' + '=' * 60);
      print('📊 KULLANICI VERİLERİ: $email');
      print('=' * 60);

      // Kullanıcı bilgisi
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (users.isEmpty) {
        print('❌ Kullanıcı bulunamadı!');
        return;
      }

      final user = users.first;
      print('\n👤 KULLANICI BİLGİSİ:');
      print('  ID: ${user['id']}');
      print('  Email: ${user['email']}');
      print('  İsim: ${user['fullName']}');
      print('  Provider: ${user['provider']}');
      print('  Oluşturma: ${user['createdAt']}');

      // Kullanıcının varlıkları
      final assets = await db.query(
        'assets',
        where: 'userEmail = ?',
        whereArgs: [email],
      );
      print('\n💰 VARLIKLAR (${assets.length} adet):');
      print('-' * 60);

      if (assets.isEmpty) {
        print('  Henüz varlık eklenmemiş.');
      } else {
        double totalValue = 0;
        for (var asset in assets) {
          print('${asset['name']} (${asset['type']})');
          print('  Miktar: ${asset['quantity']}');
          print('  Alış: ₺${asset['purchasePrice']}');
          print('  Toplam: ₺${asset['totalCost']}');
          print('  Tarih: ${asset['purchaseDate']}');
          print('-' * 60);
          totalValue += (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
        }
        print('\n💵 TOPLAM PORTFÖY DEĞERİ: ₺${totalValue.toStringAsFixed(2)}');
      }

      print('=' * 60 + '\n');
    } catch (e) {
      print('❌ Error printing user data: $e');
    }
  }

  /// Veritabanını kapat
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Database closed');
  }

  /// Veritabanını sıfırla (sadece development için!)
  Future<void> resetDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'algorist.db');

      await close();
      await deleteDatabase(path);

      _database = null;
      print('🔄 Database reset completed');
    } catch (e) {
      print('❌ Error resetting database: $e');
    }
  }
}

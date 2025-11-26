import 'database_service.dart';

/// Portfolio Service - Kullanıcı portföy verilerini yöneten servis
/// Veriler SQLite veritabanında kalıcı olarak saklanır
class PortfolioService {
  static final PortfolioService instance = PortfolioService._internal();
  factory PortfolioService() => instance;
  PortfolioService._internal();

  final DatabaseService _db = DatabaseService.instance;

  /// Kullanıcının portföy verilerini getir
  Future<List<Map<String, dynamic>>> getUserAssets(String userEmail) async {
    try {
      return await _db.getUserAssets(userEmail);
    } catch (e) {
      print('❌ Error getting user assets: $e');
      return [];
    }
  }

  /// Yeni varlık ekle
  Future<void> addAsset(String userEmail, Map<String, dynamic> asset) async {
    try {
      // Veritabanı için gerekli alanları ekle
      asset['userEmail'] = userEmail;
      asset['assetId'] = 'asset_${DateTime.now().millisecondsSinceEpoch}';
      asset['addedAt'] = DateTime.now().toIso8601String();
      asset['userId'] = 0; // Foreign key, şimdilik 0

      await _db.insertAsset(asset);
    } catch (e) {
      print('❌ Error adding asset: $e');
      rethrow;
    }
  }

  /// Varlık güncelle
  Future<void> updateAsset(
    String userEmail,
    String assetId,
    Map<String, dynamic> updatedAsset,
  ) async {
    try {
      await _db.updateAsset(assetId, updatedAsset);
    } catch (e) {
      print('Error updating asset: $e');
      rethrow;
    }
  }

  /// Varlık sil
  Future<void> deleteAsset(String userEmail, String assetId) async {
    try {
      await _db.deleteAsset(assetId);
    } catch (e) {
      print('Error deleting asset: $e');
      rethrow;
    }
  }

  /// Portföy istatistikleri hesapla
  Future<Map<String, dynamic>> getPortfolioStats(String userEmail) async {
    try {
      final assets = await getUserAssets(userEmail);

      if (assets.isEmpty) {
        return {
          'totalValue': 0.0,
          'totalCost': 0.0,
          'totalGain': 0.0,
          'gainPercentage': 0.0,
          'assetCount': 0,
        };
      }

      double totalCost = 0.0;

      for (var asset in assets) {
        totalCost += (asset['totalCost'] ?? 0.0);
      }

      return {
        'totalValue': totalCost,
        'totalCost': totalCost,
        'totalGain': 0.0,
        'gainPercentage': 0.0,
        'assetCount': assets.length,
      };
    } catch (e) {
      print('Error calculating portfolio stats: $e');
      return {
        'totalValue': 0.0,
        'totalCost': 0.0,
        'totalGain': 0.0,
        'gainPercentage': 0.0,
        'assetCount': 0,
      };
    }
  }

  /// Kullanıcının tüm portföy verilerini sil
  Future<void> clearUserPortfolio(String userEmail) async {
    try {
      await _db.deleteUserAssets(userEmail);
    } catch (e) {
      print('Error clearing user portfolio: $e');
      rethrow;
    }
  }
}

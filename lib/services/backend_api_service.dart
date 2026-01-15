import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

/// Backend API Service
/// Replaces direct Yahoo Finance calls with cached backend data
class BackendApiService {
  // Singleton pattern
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;
  BackendApiService._internal();

  // Platform-aware base URL
  String get baseUrl {
    try {
      if (Platform.isAndroid) {
        // Android Emulator uses 10.0.2.2 for localhost
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS) {
        // iOS Simulator uses localhost
        return 'http://localhost:8000';
      }
    } catch (e) {
      // Web or other platforms
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  /// Fetch all market data from backend
  Future<Map<String, dynamic>> getAllMarketData() async {
    try {
      AppLogger.info('📡 Fetching market data from $baseUrl');
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/market-data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.info(
          '✅ Market data received: ${data.keys.length} categories',
        );
        return data;
      } else {
        AppLogger.warning('⚠️ Backend returned ${response.statusCode}');
        return {};
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching market data', e);
      return {}; // Return empty map instead of throwing
    }
  }

  /// Fetch only BIST100 stocks
  Future<List<dynamic>> getStocks() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/stocks'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stocks = data['stocks'] ?? data['bist100'] ?? [];
        AppLogger.info('✅ Loaded ${stocks.length} stocks from backend');
        return stocks;
      } else {
        AppLogger.warning('⚠️ Stocks endpoint returned ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching stocks', e);
      return []; // Return empty list instead of throwing
    }
  }

  /// Fetch only Forex pairs
  Future<List<dynamic>> getForex() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/forex'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forex = data['forex'] ?? [];
        AppLogger.info('✅ Loaded ${forex.length} forex pairs');
        return forex;
      } else {
        AppLogger.warning('⚠️ Forex endpoint returned ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching forex', e);
      return [];
    }
  }

  /// Fetch only Commodities
  Future<List<dynamic>> getCommodities() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/commodities'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commodities = data['commodities'] ?? [];
        AppLogger.info('✅ Loaded ${commodities.length} commodities');
        return commodities;
      } else {
        AppLogger.warning(
          '⚠️ Commodities endpoint returned ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching commodities', e);
      return [];
    }
  }

  /// Fetch only TEFAS Funds
  Future<List<dynamic>> getFunds() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/funds'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final funds = data['funds'] ?? [];
        AppLogger.info('✅ Loaded ${funds.length} funds');
        return funds;
      } else {
        AppLogger.warning('⚠️ Funds endpoint returned ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.error('❌ Error fetching funds', e);
      return [];
    }
  }

  /// Check backend health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed');
      }
    } catch (e) {
      throw Exception('Backend unreachable: $e');
    }
  }

  /// Force refresh stocks data (admin)
  Future<void> forceRefreshStocks() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/api/refresh/stocks'))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Refresh failed: $e');
    }
  }

  /// Force refresh funds data (admin)
  Future<void> forceRefreshFunds() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/api/refresh/funds'))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Refresh failed: $e');
    }
  }
}

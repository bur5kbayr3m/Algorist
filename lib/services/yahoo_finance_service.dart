import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class YahooFinanceService {
  static final YahooFinanceService instance = YahooFinanceService._();
  YahooFinanceService._();

  final String _baseUrl = 'https://query1.finance.yahoo.com';

  /// Hisse senedi verisi çeker
  /// symbol: THYAO.IS, BIMAS.IS gibi
  Future<Map<String, dynamic>?> getQuote(String symbol) async {
    try {
      final url = Uri.parse('$_baseUrl/v8/finance/chart/$symbol');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final quote = result['indicators']['quote'][0];

        return {
          'symbol': meta['symbol'],
          'price': meta['regularMarketPrice'],
          'previousClose': meta['previousClose'],
          'change': meta['regularMarketPrice'] - meta['previousClose'],
          'changePercent':
              ((meta['regularMarketPrice'] - meta['previousClose']) /
                  meta['previousClose']) *
              100,
          'currency': meta['currency'],
          'timezone': meta['timezone'],
        };
      }

      AppLogger.warning('Quote fetch failed: ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.error('Error fetching quote for $symbol', e);
      return null;
    }
  }

  /// Tarihsel fiyat verisi çeker (grafik için)
  /// interval: 1d, 1h, 5m, etc.
  /// range: 1d, 5d, 1mo, 3mo, 6mo, 1y, 5y
  Future<Map<String, dynamic>?> getHistoricalData(
    String symbol, {
    String interval = '1d',
    String range = '1mo',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/v8/finance/chart/$symbol?interval=$interval&range=$range',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List;
        final quote = result['indicators']['quote'][0];
        final closes = quote['close'] as List;
        final opens = quote['open'] as List;
        final highs = quote['high'] as List;
        final lows = quote['low'] as List;
        final volumes = quote['volume'] as List;

        List<Map<String, dynamic>> chartData = [];
        for (int i = 0; i < timestamps.length; i++) {
          if (closes[i] != null) {
            chartData.add({
              'timestamp': timestamps[i],
              'date': DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              'open': opens[i]?.toDouble() ?? 0.0,
              'close': closes[i]?.toDouble() ?? 0.0,
              'high': highs[i]?.toDouble() ?? 0.0,
              'low': lows[i]?.toDouble() ?? 0.0,
              'volume': volumes[i]?.toInt() ?? 0,
            });
          }
        }

        return {'symbol': result['meta']['symbol'], 'data': chartData};
      }

      AppLogger.warning('Historical data fetch failed: ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.error('Error fetching historical data for $symbol', e);
      return null;
    }
  }

  /// Birden fazla hisse için veri çeker (paralel)
  Future<List<Map<String, dynamic>>> getMultipleQuotes(
    List<String> symbols,
  ) async {
    // Tüm API çağrılarını paralel olarak başlat
    final futures = symbols.map((symbol) => getQuote(symbol)).toList();

    // Tüm sonuçları bekle
    final results = await Future.wait(
      futures,
      eagerError: false, // Bir hata diğerlerini durdurmasın
    );

    // Null olmayan sonuçları filtrele ve döndür
    return results
        .where((quote) => quote != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// BIST 100 hisseleri için semboller
  static List<String> getBist100Symbols() {
    return [
      'THYAO.IS', // Türk Hava Yolları
      'BIMAS.IS', // BIM
      'EREGL.IS', // Ereğli Demir Çelik
      'SAHOL.IS', // Sabancı Holding
      'AKBNK.IS', // Akbank
      'ASELS.IS', // Aselsan
      'TUPRS.IS', // Tüpraş
      'KCHOL.IS', // Koç Holding
      'GARAN.IS', // Garanti Bankası
      'ISCTR.IS', // İş Bankası
      'SISE.IS', // Şişe Cam
      'PETKM.IS', // Petkim
      'VAKBN.IS', // Vakıfbank
      'ENKAI.IS', // Enka İnşaat
      'TCELL.IS', // Turkcell
      'FROTO.IS', // Ford Otosan
      'TTKOM.IS', // Türk Telekom
      'KOZAL.IS', // Koza Altın
      'ARCLK.IS', // Arçelik
      'TOASO.IS', // Tofaş
    ];
  }

  /// Döviz kurları için semboller
  static List<String> getForexSymbols() {
    return [
      'USDTRY=X', // USD/TRY
      'EURTRY=X', // EUR/TRY
      'GBPTRY=X', // GBP/TRY
    ];
  }

  /// Emtia için semboller
  static List<String> getCommoditySymbols() {
    return [
      'GC=F', // Altın
      'SI=F', // Gümüş
      'CL=F', // Ham Petrol
    ];
  }
}

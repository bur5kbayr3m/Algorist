import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  static NewsService get instance => _instance;
  NewsService._internal();

  // GNews API - Ücretsiz haber API'si (günde 100 istek)
  // https://gnews.io/ adresinden API key alabilirsiniz
  static const String _gNewsApiKey = 'YOUR_GNEWS_API_KEY'; // Ücretsiz key için gnews.io'ya kayıt olun
  static const String _gNewsBaseUrl = 'https://gnews.io/api/v4';

  // Alternatif: NewsData.io API (günde 200 istek)
  // https://newsdata.io/ adresinden API key alabilirsiniz
  static const String _newsDataApiKey = 'YOUR_NEWSDATA_API_KEY';
  static const String _newsDataBaseUrl = 'https://newsdata.io/api/1';

  /// Belirli bir hisse/şirket için haberleri getirir
  Future<List<NewsItem>> getStockNews(String symbol, String companyName) async {
    try {
      // Önce GNews API'yi dene
      final gNewsResult = await _fetchFromGNews(companyName);
      if (gNewsResult.isNotEmpty) {
        return gNewsResult;
      }

      // GNews başarısız olursa NewsData.io'yu dene
      final newsDataResult = await _fetchFromNewsData(companyName);
      if (newsDataResult.isNotEmpty) {
        return newsDataResult;
      }

      // Her iki API de başarısız olursa mock veri döndür
      return _generateMockNews(symbol, companyName);
    } catch (e) {
      AppLogger.error('Error fetching news', e);
      return _generateMockNews(symbol, companyName);
    }
  }

  /// GNews API'den haber çeker
  Future<List<NewsItem>> _fetchFromGNews(String query) async {
    if (_gNewsApiKey == 'YOUR_GNEWS_API_KEY') {
      // API key ayarlanmamış, mock veri kullan
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent('$query borsa hisse');
      final url = '$_gNewsBaseUrl/search?q=$encodedQuery&lang=tr&country=tr&max=10&apikey=$_gNewsApiKey';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List<dynamic>? ?? [];
        
        return articles.map((article) {
          return NewsItem(
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            source: article['source']?['name'] ?? 'Bilinmeyen Kaynak',
            url: article['url'] ?? '',
            imageUrl: article['image'],
            publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
            category: 'Genel',
          );
        }).toList();
      }
    } catch (e) {
      AppLogger.error('GNews API error', e);
    }
    return [];
  }

  /// NewsData.io API'den haber çeker
  Future<List<NewsItem>> _fetchFromNewsData(String query) async {
    if (_newsDataApiKey == 'YOUR_NEWSDATA_API_KEY') {
      // API key ayarlanmamış, mock veri kullan
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_newsDataBaseUrl/news?apikey=$_newsDataApiKey&q=$encodedQuery&country=tr&language=tr';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['results'] as List<dynamic>? ?? [];
        
        return articles.map((article) {
          return NewsItem(
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            source: article['source_id'] ?? 'Bilinmeyen Kaynak',
            url: article['link'] ?? '',
            imageUrl: article['image_url'],
            publishedAt: DateTime.tryParse(article['pubDate'] ?? '') ?? DateTime.now(),
            category: 'Genel',
          );
        }).toList();
      }
    } catch (e) {
      AppLogger.error('NewsData API error', e);
    }
    return [];
  }

  /// KAP bildirimleri için mock veri üretir
  List<KapNews> getKapNews(String symbol, String companyName) {
    return [
      KapNews(
        title: '$companyName Finansal Tablo Açıklaması',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'Finansal Tablo',
        importance: KapImportance.high,
        url: 'https://www.kap.org.tr/tr/bist-sirketler',
      ),
      KapNews(
        title: 'Yönetim Kurulu Kararları Açıklaması',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'Yönetim',
        importance: KapImportance.medium,
        url: 'https://www.kap.org.tr/tr/bist-sirketler',
      ),
      KapNews(
        title: 'Ortaklık Yapısı Değişikliği',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: 'Ortaklık',
        importance: KapImportance.high,
        url: 'https://www.kap.org.tr/tr/bist-sirketler',
      ),
      KapNews(
        title: 'Temettü Dağıtım Politikası',
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: 'Temettü',
        importance: KapImportance.medium,
        url: 'https://www.kap.org.tr/tr/bist-sirketler',
      ),
    ];
  }

  /// Mock haber verisi üretir (API kullanılamadığında)
  List<NewsItem> _generateMockNews(String symbol, String companyName) {
    return [
      NewsItem(
        title: '$companyName hisseleri yükselişte! Uzmanlar ne diyor?',
        description: 'Analistler, şirketin son çeyrek performansının beklenenden iyi olduğunu belirtiyor.',
        source: 'Bloomberg HT',
        url: 'https://www.bloomberght.com/borsa',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        category: 'Analiz',
      ),
      NewsItem(
        title: 'Piyasa analisti: $companyName için yeni hedef fiyat açıkladı',
        description: 'Araştırma şirketi, hedef fiyatını %15 yukarı revize etti.',
        source: 'Investing.com',
        url: 'https://tr.investing.com/',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        category: 'Analiz',
      ),
      NewsItem(
        title: '$companyName\'nın çeyrek sonuçları beklentileri aştı',
        description: 'Şirket, geçen yılın aynı dönemine göre %25 gelir artışı bildirdi.',
        source: 'CNBC Türkiye',
        url: 'https://www.cnbce.com/',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Finansal',
      ),
      NewsItem(
        title: 'Sektör analizinde $companyName öne çıkıyor',
        description: 'Sektör raporuna göre şirket, rakiplerine kıyasla daha güçlü büyüme potansiyeli taşıyor.',
        source: 'Dünya',
        url: 'https://www.dunya.com/',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Sektör',
      ),
      NewsItem(
        title: '$companyName yeni yatırım planlarını açıkladı',
        description: 'Şirket, önümüzdeki 3 yıl için kapsamlı bir genişleme planı duyurdu.',
        source: 'Ekonomist',
        url: 'https://www.ekonomist.com.tr/',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Şirket',
      ),
    ];
  }

  /// Genel piyasa haberlerini getirir
  Future<List<NewsItem>> getMarketNews() async {
    try {
      final gNewsResult = await _fetchFromGNews('borsa BIST türkiye');
      if (gNewsResult.isNotEmpty) {
        return gNewsResult;
      }

      final newsDataResult = await _fetchFromNewsData('borsa hisse');
      if (newsDataResult.isNotEmpty) {
        return newsDataResult;
      }

      return _generateMarketMockNews();
    } catch (e) {
      AppLogger.error('Error fetching market news', e);
      return _generateMarketMockNews();
    }
  }

  List<NewsItem> _generateMarketMockNews() {
    return [
      NewsItem(
        title: 'BIST 100 güne yükselişle başladı',
        description: 'Endeks, bankacılık sektörünün desteğiyle pozitif seyrediyor.',
        source: 'Bloomberg HT',
        url: 'https://www.bloomberght.com/borsa',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
        category: 'Piyasa',
      ),
      NewsItem(
        title: 'Merkez Bankası faiz kararı açıklandı',
        description: 'Para Politikası Kurulu toplantı sonuçları piyasaları etkiledi.',
        source: 'Habertürk',
        url: 'https://www.haberturk.com/ekonomi',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        category: 'Ekonomi',
      ),
      NewsItem(
        title: 'Dolar/TL kurunda son durum',
        description: 'Döviz piyasalarındaki son gelişmeler ve analizler.',
        source: 'NTV',
        url: 'https://www.ntv.com.tr/ekonomi',
        imageUrl: null,
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        category: 'Döviz',
      ),
    ];
  }
}

/// Haber modeli
class NewsItem {
  final String title;
  final String description;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String category;

  NewsItem({
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.category,
  });
}

/// KAP bildirimi modeli
class KapNews {
  final String title;
  final DateTime date;
  final String type;
  final KapImportance importance;
  final String url;

  KapNews({
    required this.title,
    required this.date,
    required this.type,
    required this.importance,
    required this.url,
  });
}

enum KapImportance { low, medium, high }

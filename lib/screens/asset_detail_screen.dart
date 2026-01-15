import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../services/news_service.dart';
import '../services/backend_api_service.dart';
import '../utils/app_logger.dart';

class AssetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

enum ChartPeriod { day, week, month, threeMonths, year, all }

enum ChartType { line, candlestick, area, bar }

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  ChartType _selectedChartType = ChartType.line;
  bool _isLoadingNews = true;
  List<KapNews> _kapNews = [];
  List<NewsItem> _generalNews = [];

  // Real-time price data
  double? _currentPrice;
  bool _isLoadingPrice = true;
  final BackendApiService _backendApi = BackendApiService();

  @override
  void initState() {
    super.initState();
    _loadNews();
    _loadCurrentPrice();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);

    try {
      final assetName = _getCleanName();
      final symbol = _getSymbol();

      // Gerçek haber servisinden veri çek
      final newsService = NewsService.instance;

      final generalNews = await newsService.getStockNews(symbol, assetName);
      final kapNews = newsService.getKapNews(symbol, assetName);

      if (mounted) {
        setState(() {
          _generalNews = generalNews;
          _kapNews = kapNews;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading news', e);
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _loadCurrentPrice() async {
    setState(() => _isLoadingPrice = true);

    try {
      final type = widget.asset['type'] as String;

      // Nakit için fiyat güncellemesi yok
      if (type == 'Nakit') {
        setState(() {
          _currentPrice = null;
          _isLoadingPrice = false;
        });
        return;
      }

      final symbol = _getSymbol();
      if (symbol.isEmpty) {
        setState(() {
          _currentPrice = null;
          _isLoadingPrice = false;
        });
        return;
      }

      // Backend'den ilgili varlık tipine göre fiyat çek
      if (type == 'Hisse') {
        final stocks = await _backendApi.getStocks();
        final stock = stocks.firstWhere(
          (s) => s['symbol'].toString().toUpperCase().contains(
            symbol.toUpperCase(),
          ),
          orElse: () => {},
        );
        if (stock.isNotEmpty) {
          setState(() {
            _currentPrice = stock['price']?.toDouble();
            _isLoadingPrice = false;
          });
        }
      } else if (type == 'Döviz') {
        final forex = await _backendApi.getForex();
        final pair = forex.firstWhere(
          (f) => f['symbol'].toString().toUpperCase().contains(
            symbol.toUpperCase(),
          ),
          orElse: () => {},
        );
        if (pair.isNotEmpty) {
          setState(() {
            _currentPrice = pair['price']?.toDouble();
            _isLoadingPrice = false;
          });
        }
      } else if (type == 'Altın' || type == 'Emtia') {
        final commodities = await _backendApi.getCommodities();
        final commodity = commodities.firstWhere(
          (c) =>
              c['symbol'].toString().toUpperCase().contains(
                symbol.toUpperCase(),
              ) ||
              c['name'].toString().toUpperCase().contains(symbol.toUpperCase()),
          orElse: () => {},
        );
        if (commodity.isNotEmpty) {
          setState(() {
            _currentPrice = commodity['price']?.toDouble();
            _isLoadingPrice = false;
          });
        }
      } else if (type == 'Fon') {
        final funds = await _backendApi.getFunds();
        final fund = funds.firstWhere(
          (f) =>
              f['code'].toString().toUpperCase().contains(symbol.toUpperCase()),
          orElse: () => {},
        );
        if (fund.isNotEmpty) {
          setState(() {
            _currentPrice = fund['price']?.toDouble();
            _isLoadingPrice = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading current price', e);
      setState(() => _isLoadingPrice = false);
    }
  }

  String _getSymbol() {
    final nameRaw = widget.asset['name'] as String;
    if (nameRaw.contains('|')) {
      return nameRaw.split('|')[0].trim();
    }
    return nameRaw;
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Bu haber için kaynak linki mevcut değil'),
                ),
              ],
            ),
            backgroundColor: AppColors.slate700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bağlantı açılamadı: ${e.toString().split(':').first}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.negativeDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _getCleanName() {
    final nameRaw = widget.asset['name'] as String;
    if (nameRaw.contains('|')) {
      return nameRaw.split('|')[0];
    }
    return nameRaw;
  }

  double _getProfitLoss() {
    final nameRaw = widget.asset['name'] as String;
    if (!nameRaw.contains('|')) return 0.0;

    final parts = nameRaw.split('|');
    if (parts.length > 1) {
      final profitInfo = parts[1];
      final match = RegExp(r'profitLoss:([-\d.]+)').firstMatch(profitInfo);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 0.0;
      }
    }
    return 0.0;
  }

  double _getProfitLossPercent() {
    final nameRaw = widget.asset['name'] as String;
    if (!nameRaw.contains('|')) return 0.0;

    final parts = nameRaw.split('|');
    if (parts.length > 1) {
      final profitInfo = parts[1];
      final match = RegExp(
        r'profitLossPercent:([-\d.]+)',
      ).firstMatch(profitInfo);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 0.0;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.asset['type'] as String;
    final quantity = widget.asset['quantity'] as num?;
    final purchasePrice =
        (widget.asset['purchasePrice'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (widget.asset['totalCost'] as num?)?.toDouble() ?? 0.0;
    final assetName = _getCleanName();
    final profitLoss = _getProfitLoss();
    final profitLossPercent = _getProfitLossPercent();

    // Backend'den gelen gerçek güncel fiyat (yoksa satın alma fiyatını kullan)
    final currentPrice = type == 'Nakit'
        ? 0.0
        : (_currentPrice ?? purchasePrice);
    final currentValue = type == 'Nakit'
        ? totalCost
        : (quantity?.toDouble() ?? 0.0) * currentPrice;
    final unrealizedProfitLoss = type == 'Nakit'
        ? 0.0
        : currentValue - totalCost;
    final unrealizedProfitLossPercent = type == 'Nakit'
        ? 0.0
        : totalCost > 0
        ? (unrealizedProfitLoss / totalCost) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMainDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          assetName,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: AppColors.textMainDark),
            onPressed: () {
              // Favorilere ekle
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textMainDark),
            onPressed: () {
              // Paylaş
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        color: AppColors.primary,
        backgroundColor: const Color(0xFF1F2937),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fiyat Bilgileri
              _buildPriceSection(
                type,
                currentPrice,
                currentValue,
                unrealizedProfitLoss,
                unrealizedProfitLossPercent,
              ),

              // Grafik - En üstte, fiyat bilgilerinin hemen altında
              _buildChartSection(),

              // Kullanıcı Pozisyon Bilgileri
              _buildPositionSection(
                type,
                quantity,
                purchasePrice,
                totalCost,
                currentValue,
                profitLoss,
                profitLossPercent,
                unrealizedProfitLoss,
                unrealizedProfitLossPercent,
              ),

              // KAP Haberleri (sadece hisseler için)
              if (type == 'Hisse') _buildKapNewsSection(),

              // Genel Haberler
              _buildGeneralNewsSection(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSellDialog(),
        backgroundColor: AppColors.negativeDark,
        elevation: 0,
        icon: const Icon(Icons.sell),
        label: Text(
          'Sat',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPriceSection(
    String type,
    double currentPrice,
    double currentValue,
    double profitLoss,
    double profitLossPercent,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type != 'Nakit') ...[
            Text(
              'Güncel Fiyat',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${currentPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMainDark,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (profitLossPercent >= 0
                                ? AppColors.positiveDark
                                : AppColors.negativeDark)
                            .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        profitLossPercent >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: profitLossPercent >= 0
                            ? AppColors.positiveDark
                            : AppColors.negativeDark,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: profitLossPercent >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Toplam Değer',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₺${currentValue.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textMainDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Grafik türü seçici - Grid layout
          Row(
            children: [
              Expanded(
                child: _buildChartTypeButton(
                  ChartType.line,
                  'Çizgi',
                  Icons.show_chart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeButton(
                  ChartType.area,
                  'Alan',
                  Icons.area_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChartTypeButton(
                  ChartType.candlestick,
                  'Mum',
                  Icons.candlestick_chart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChartTypeButton(
                  ChartType.bar,
                  'Çubuk',
                  Icons.bar_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Periyot seçici
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ChartPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return InkWell(
                onTap: () => setState(() => _selectedPeriod = period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPeriodLabel(period),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Grafik placeholder - seçilen türe göre ikon gösterimi
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getChartTypeIcon(_selectedChartType),
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_getChartTypeName(_selectedChartType)} Grafik',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMainDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerçek zamanlı fiyat grafiği\nAPI entegrasyonu ile eklenecek',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, String label, IconData icon) {
    final isSelected = _selectedChartType == type;
    return InkWell(
      onTap: () => setState(() => _selectedChartType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : const Color(0xFF131022),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderDark.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryDark,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChartTypeIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.candlestick:
        return Icons.candlestick_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.bar:
        return Icons.bar_chart;
    }
  }

  String _getChartTypeName(ChartType type) {
    switch (type) {
      case ChartType.line:
        return 'Çizgi';
      case ChartType.candlestick:
        return 'Mum';
      case ChartType.area:
        return 'Alan';
      case ChartType.bar:
        return 'Çubuk';
    }
  }

  String _getPeriodLabel(ChartPeriod period) {
    switch (period) {
      case ChartPeriod.day:
        return '1G';
      case ChartPeriod.week:
        return '1H';
      case ChartPeriod.month:
        return '1A';
      case ChartPeriod.threeMonths:
        return '3A';
      case ChartPeriod.year:
        return '1Y';
      case ChartPeriod.all:
        return 'Tümü';
    }
  }

  Widget _buildPositionSection(
    String type,
    num? quantity,
    double purchasePrice,
    double totalCost,
    double currentValue,
    double realizedProfitLoss,
    double realizedProfitLossPercent,
    double unrealizedProfitLoss,
    double unrealizedProfitLossPercent,
  ) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Pozisyon Bilgileri',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pozisyon bilgileri grid
          if (type != 'Nakit') ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Miktar',
                    quantity?.toStringAsFixed(
                          quantity.truncateToDouble() == quantity ? 0 : 2,
                        ) ??
                        '0',
                    Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Alış Fiyatı',
                    '₺${purchasePrice.toStringAsFixed(2)}',
                    Icons.shopping_cart_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Toplam Maliyet',
                    '₺${totalCost.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Güncel Değer',
                    '₺${currentValue.toStringAsFixed(2)}',
                    Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kar/Zarar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    (unrealizedProfitLoss >= 0
                            ? AppColors.positiveDark
                            : AppColors.negativeDark)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (unrealizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark)
                          .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerçekleşmemiş Kar/Zarar',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${unrealizedProfitLoss.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: unrealizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: unrealizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${unrealizedProfitLossPercent >= 0 ? '+' : ''}${unrealizedProfitLossPercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Gerçekleşen kar/zarar (varsa)
          if (type == 'Nakit' && realizedProfitLoss != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    (realizedProfitLoss >= 0
                            ? AppColors.positiveDark
                            : AppColors.negativeDark)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (realizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark)
                          .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerçekleşen Kar/Zarar',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Satış işleminden',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${realizedProfitLoss.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: realizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: realizedProfitLoss >= 0
                              ? AppColors.positiveDark
                              : AppColors.negativeDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${realizedProfitLossPercent >= 0 ? '+' : ''}${realizedProfitLossPercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondaryDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKapNewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'KAP Bildirimleri',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMainDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showAllKapNewsDialog(),
                child: Text(
                  'Tümü',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingNews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_kapNews.isEmpty)
            _buildEmptyState('KAP bildirimi bulunamadı')
          else
            ..._kapNews.map((news) => _buildKapNewsCard(news)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildKapNewsCard(KapNews news) {
    Color importanceColor;
    switch (news.importance) {
      case KapImportance.high:
        importanceColor = AppColors.negativeDark;
        break;
      case KapImportance.medium:
        importanceColor = const Color(0xFFFBBF24); // yellow
        break;
      default:
        importanceColor = AppColors.textSecondaryDark;
    }

    return GestureDetector(
      onTap: () => _launchUrl(news.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: importanceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    news.type,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: importanceColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.circle, size: 8, color: importanceColor),
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm • dd.MM.yyyy').format(news.date),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              news.title,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMainDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _launchUrl(news.url),
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Detay',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralNewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.newspaper,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Haberler',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMainDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showAllGeneralNewsDialog(),
                child: Text(
                  'Tümü',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingNews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_generalNews.isEmpty)
            _buildEmptyState('Haber bulunamadı')
          else
            ..._generalNews.map((news) => _buildGeneralNewsCard(news)),
        ],
      ),
    );
  }

  Widget _buildGeneralNewsCard(NewsItem news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchUrl(news.url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMainDark,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.source,
                          size: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          news.source,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTimeAgo(news.publishedAt),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: AppColors.textSecondaryDark.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _showAllKapNewsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tüm KAP Bildirimleri',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _kapNews.isEmpty
                  ? Center(
                      child: Text(
                        'KAP bildirimi bulunamadı',
                        style: GoogleFonts.manrope(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _kapNews.length,
                      itemBuilder: (context, index) =>
                          _buildKapNewsCard(_kapNews[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllGeneralNewsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tüm Haberler',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _generalNews.isEmpty
                  ? Center(
                      child: Text(
                        'Haber bulunamadı',
                        style: GoogleFonts.manrope(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _generalNews.length,
                      itemBuilder: (context, index) =>
                          _buildGeneralNewsCard(_generalNews[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellDialog() {
    final assetName = _getCleanName();
    final type = widget.asset['type'] as String;
    final quantity = (widget.asset['quantity'] as num?)?.toDouble() ?? 0.0;
    final purchasePrice =
        (widget.asset['purchasePrice'] as num?)?.toDouble() ?? 0.0;
    final currentPrice = type == 'Nakit' ? purchasePrice : purchasePrice * 1.05;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssetSellBottomSheet(
        assetName: assetName,
        currentPrice: currentPrice,
        assetType: type,
        maxQuantity: quantity,
      ),
    );
  }
}

class _AssetSellBottomSheet extends StatefulWidget {
  final String assetName;
  final double currentPrice;
  final String assetType;
  final double maxQuantity;

  const _AssetSellBottomSheet({
    required this.assetName,
    required this.currentPrice,
    required this.assetType,
    required this.maxQuantity,
  });

  @override
  State<_AssetSellBottomSheet> createState() => _AssetSellBottomSheetState();
}

class _AssetSellBottomSheetState extends State<_AssetSellBottomSheet> {
  final _quantityController = TextEditingController(text: '1');
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _totalValue = quantity * widget.currentPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final isValidQuantity = quantity > 0 && quantity <= widget.maxQuantity;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '${widget.assetName} Sat',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Güncel Fiyat: ₺${widget.currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mevcut Miktar: ${widget.maxQuantity.toStringAsFixed(widget.assetType == 'Fon' ? 6 : 2)} Adet',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Miktar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Satılacak Miktar',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _quantityController.text = widget.maxQuantity
                          .toStringAsFixed(widget.assetType == 'Fon' ? 6 : 2);
                      _calculateTotal();
                    },
                    child: Text(
                      'Tümünü Sat',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.negativeDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _calculateTotal(),
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: 'Adet',
                  suffixStyle: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  errorText: !isValidQuantity && quantity > 0
                      ? 'Mevcut miktardan fazla satılamaz'
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Toplam
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.negativeDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.negativeDark.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Satış Tutarı',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '₺${_totalValue.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.negativeDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Satış Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isValidQuantity
                      ? () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Satış emri oluşturuldu: ${_quantityController.text} adet ${widget.assetName}',
                              ),
                              backgroundColor: AppColors.negativeDark,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negativeDark,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'SAT',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

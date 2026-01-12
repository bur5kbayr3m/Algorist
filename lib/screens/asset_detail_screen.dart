import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class AssetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

enum ChartPeriod { day, week, month, threeMonths, year, all }

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  bool _isLoadingNews = true;
  List<Map<String, dynamic>> _kapNews = [];
  List<Map<String, dynamic>> _generalNews = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);

    // Simulated news loading - gerçek API entegrasyonu eklenecek
    await Future.delayed(const Duration(seconds: 1));

    final assetName = _getCleanName();

    setState(() {
      _kapNews = _generateMockKapNews(assetName);
      _generalNews = _generateMockGeneralNews(assetName);
      _isLoadingNews = false;
    });
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

  List<Map<String, dynamic>> _generateMockKapNews(String assetName) {
    return [
      {
        'title': '$assetName Finansal Tablo Açıklaması',
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'type': 'Finansal Tablo',
        'importance': 'high',
      },
      {
        'title': 'Yönetim Kurulu Kararları Açıklaması',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'type': 'Yönetim',
        'importance': 'medium',
      },
      {
        'title': 'Ortaklık Yapısı Değişikliği',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'type': 'Ortaklık',
        'importance': 'high',
      },
      {
        'title': 'Temettü Dağıtım Politikası',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'type': 'Temettü',
        'importance': 'medium',
      },
    ];
  }

  List<Map<String, dynamic>> _generateMockGeneralNews(String assetName) {
    return [
      {
        'title': '$assetName hisseleri yükselişte! Uzmanlar ne diyor?',
        'source': 'Bloomberg HT',
        'date': DateTime.now().subtract(const Duration(hours: 3)),
        'imageUrl': null,
      },
      {
        'title': 'Piyasa analisti: $assetName için yeni hedef fiyat açıkladı',
        'source': 'Investing.com',
        'date': DateTime.now().subtract(const Duration(hours: 5)),
        'imageUrl': null,
      },
      {
        'title': '$assetName\'nın çeyrek sonuçları beklentileri aştı',
        'source': 'CNBC Türkiye',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'imageUrl': null,
      },
      {
        'title': 'Sektör analizinde $assetName öne çıkıyor',
        'source': 'Hürriyet',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'imageUrl': null,
      },
    ];
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

    // Mock güncel fiyat (gerçek API entegrasyonu eklenecek)
    final currentPrice = type == 'Nakit' ? 0.0 : purchasePrice * 1.05;
    final currentValue = type == 'Nakit'
        ? totalCost
        : (quantity?.toDouble() ?? 0.0) * currentPrice;
    final unrealizedProfitLoss = type == 'Nakit'
        ? 0.0
        : currentValue - totalCost;
    final unrealizedProfitLossPercent = type == 'Nakit'
        ? 0.0
        : (unrealizedProfitLoss / totalCost) * 100;

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
        onPressed: () {
          // İşlem yap (Al/Sat)
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        icon: const Icon(Icons.swap_horiz),
        label: Text(
          'İşlem Yap',
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

          // Grafik placeholder (gerçek grafik kütüphanesi eklenecek)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: AppColors.textSecondaryDark.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Grafik yükleniyor...',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark,
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
                onPressed: () {
                  // Tümünü göster
                },
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

  Widget _buildKapNewsCard(Map<String, dynamic> news) {
    final title = news['title'] as String;
    final date = news['date'] as DateTime;
    final type = news['type'] as String;
    final importance = news['importance'] as String;

    Color importanceColor;
    switch (importance) {
      case 'high':
        importanceColor = AppColors.negativeDark;
        break;
      case 'medium':
        importanceColor = const Color(0xFFFBBF24); // yellow
        break;
      default:
        importanceColor = AppColors.textSecondaryDark;
    }

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: importanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
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
                DateFormat('HH:mm • dd.MM.yyyy').format(date),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
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
                onPressed: () {
                  // Detayı aç
                },
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
                onPressed: () {
                  // Tümünü göster
                },
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

  Widget _buildGeneralNewsCard(Map<String, dynamic> news) {
    final title = news['title'] as String;
    final source = news['source'] as String;
    final date = news['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Haberi aç
        },
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
                      title,
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
                          source,
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
                          _getTimeAgo(date),
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
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondaryDark,
              ),
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
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/offline_mode_banner.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _userAssets = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    if (userEmail != null) {
      final assets = await PortfolioService.instance.getUserAssets(userEmail);
      setState(() {
        _userAssets = assets;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundDark,
          bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Analizler',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondaryDark,
              labelStyle: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Genel Bakış'),
                Tab(text: 'Dağılım'),
                Tab(text: 'Performans'),
                Tab(text: 'Risk'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                _buildOverviewTab(),
                _buildDistributionTab(),
                _buildPerformanceTab(),
                _buildRiskTab(),
              ],
            ),
        ),
        const OfflineModeBanner(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final totalValue = _calculateTotalValue();
    final assetCount = _userAssets.length;
    final typeCount = _getUniqueTypes().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Kartları
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam Değer',
                  '₺${_formatNumber(totalValue)}',
                  Icons.account_balance_wallet_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Varlık Sayısı',
                  assetCount.toString(),
                  Icons.inventory_2_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Varlık Türü',
                  typeCount.toString(),
                  Icons.category_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ortalama',
                  assetCount > 0
                      ? '₺${_formatNumber(totalValue / assetCount)}'
                      : '₺0',
                  Icons.trending_flat_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // En Büyük Varlıklar
          Text(
            'En Büyük Pozisyonlar',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildTopAssets(),

          const SizedBox(height: 24),

          // Portföy Sağlık Skoru
          _buildHealthScore(),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    final typeDistribution = _getTypeDistribution();
    final totalValue = _calculateTotalValue();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Varlık Türü Dağılımı',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),

          if (_userAssets.isEmpty)
            _buildEmptyState('Dağılım görmek için varlık ekleyin')
          else ...[
            // Görsel Dağılım
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Basit bar gösterimi
                  ...typeDistribution.entries.map((entry) {
                    final percentage = totalValue > 0
                        ? (entry.value / totalValue * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getColorForType(entry.key),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMainDark,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMainDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppColors.borderDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForType(entry.key),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₺${_formatNumber(entry.value)}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Çeşitlendirme Önerisi
            _buildDiversificationTip(),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans Analizi',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),

          if (_userAssets.isEmpty)
            _buildEmptyState('Performans görmek için varlık ekleyin')
          else ...[
            // Kar/Zarar Özeti
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satış Kar/Zarar Özeti',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMainDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildProfitLossItems(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Performans İpuçları
            _buildPerformanceTips(),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskTab() {
    final typeDistribution = _getTypeDistribution();
    final typeCount = typeDistribution.length;
    final totalValue = _calculateTotalValue();

    // Risk skoru hesaplama
    double riskScore = 0;
    String riskLevel = 'Düşük';
    Color riskColor = AppColors.positiveDark;

    if (typeCount == 1) {
      riskScore = 80;
      riskLevel = 'Yüksek';
      riskColor = AppColors.negativeDark;
    } else if (typeCount == 2) {
      riskScore = 60;
      riskLevel = 'Orta-Yüksek';
      riskColor = const Color(0xFFF59E0B);
    } else if (typeCount == 3) {
      riskScore = 40;
      riskLevel = 'Orta';
      riskColor = const Color(0xFFFBBF24);
    } else if (typeCount >= 4) {
      riskScore = 20;
      riskLevel = 'Düşük';
      riskColor = AppColors.positiveDark;
    }

    // En büyük pozisyon kontrolü
    if (typeDistribution.isNotEmpty) {
      final maxPercentage = typeDistribution.values.isNotEmpty && totalValue > 0
          ? (typeDistribution.values.reduce((a, b) => a > b ? a : b) /
                totalValue *
                100)
          : 0.0;
      if (maxPercentage > 50) {
        riskScore += 20;
        if (riskScore > 80) riskScore = 80;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Analizi',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),

          if (_userAssets.isEmpty)
            _buildEmptyState('Risk analizi için varlık ekleyin')
          else ...[
            // Risk Skoru
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Risk Seviyesi',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMainDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          riskLevel,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: riskScore / 100,
                      backgroundColor: AppColors.borderDark,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Düşük',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      Text(
                        'Yüksek',
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

            const SizedBox(height: 20),

            // Risk Faktörleri
            Text(
              'Risk Faktörleri',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMainDark,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildRiskFactors(),

            const SizedBox(height: 20),

            // Risk Azaltma Önerileri
            _buildRiskRecommendations(),
          ],
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopAssets() {
    if (_userAssets.isEmpty) {
      return [_buildEmptyState('Henüz varlık eklenmemiş')];
    }

    final sortedAssets = List<Map<String, dynamic>>.from(_userAssets)
      ..sort((a, b) {
        final costA = (a['totalCost'] as num?)?.toDouble() ?? 0;
        final costB = (b['totalCost'] as num?)?.toDouble() ?? 0;
        return costB.compareTo(costA);
      });

    return sortedAssets.take(5).map((asset) {
      final name = (asset['name'] as String).split('|').first;
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0;
      final totalValue = _calculateTotalValue();
      final percentage = totalValue > 0 ? (cost / totalValue * 100) : 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getColorForType(type).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForType(type),
                color: _getColorForType(type),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMainDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    type,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${_formatNumber(cost)}',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMainDark,
                  ),
                ),
                Text(
                  '%${percentage.toStringAsFixed(1)}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildHealthScore() {
    final typeCount = _getUniqueTypes().length;
    final assetCount = _userAssets.length;

    int score = 0;
    if (assetCount > 0) score += 25;
    if (assetCount >= 3) score += 15;
    if (assetCount >= 5) score += 10;
    if (typeCount >= 2) score += 25;
    if (typeCount >= 3) score += 15;
    if (typeCount >= 4) score += 10;

    String healthText;
    Color healthColor;
    if (score >= 80) {
      healthText = 'Mükemmel';
      healthColor = AppColors.positiveDark;
    } else if (score >= 60) {
      healthText = 'İyi';
      healthColor = const Color(0xFF10B981);
    } else if (score >= 40) {
      healthText = 'Orta';
      healthColor = const Color(0xFFF59E0B);
    } else {
      healthText = 'Geliştirilebilir';
      healthColor = AppColors.negativeDark;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            healthColor.withOpacity(0.15),
            healthColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: healthColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portföy Sağlık Skoru',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  healthText,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / 100',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: healthColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversificationTip() {
    final typeCount = _getUniqueTypes().length;
    String tip;
    IconData icon;
    Color color;

    if (typeCount < 2) {
      tip =
          'Portföyünüzü çeşitlendirmek için farklı varlık türleri eklemeyi düşünün.';
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFF59E0B);
    } else if (typeCount < 4) {
      tip =
          'İyi bir başlangıç! Daha fazla çeşitlendirme için diğer varlık türlerini de değerlendirin.';
      icon = Icons.lightbulb_outline_rounded;
      color = AppColors.primary;
    } else {
      tip = 'Harika! Portföyünüz iyi çeşitlendirilmiş görünüyor.';
      icon = Icons.check_circle_outline_rounded;
      color = AppColors.positiveDark;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textMainDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfitLossItems() {
    final profitLossAssets = _userAssets.where((asset) {
      final name = asset['name'] as String;
      return name.contains('profitLoss:');
    }).toList();

    if (profitLossAssets.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Henüz satış işlemi yapılmamış',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ),
      ];
    }

    return profitLossAssets.map((asset) {
      final nameRaw = asset['name'] as String;
      final parts = nameRaw.split('|');
      final name = parts.first;

      double profitLoss = 0;
      if (parts.length > 1) {
        final match = RegExp(r'profitLoss:([-\d.]+)').firstMatch(parts[1]);
        if (match != null) {
          profitLoss = double.tryParse(match.group(1)!) ?? 0;
        }
      }

      final isPositive = profitLoss >= 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isPositive ? AppColors.positiveDark : AppColors.negativeDark)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMainDark,
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}₺${profitLoss.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? AppColors.positiveDark
                    : AppColors.negativeDark,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPerformanceTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Performans İpuçları',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Uzun vadeli yatırımlarda sabırlı olun'),
          _buildTipItem('Piyasa dalgalanmalarında panik yapmayın'),
          _buildTipItem('Düzenli olarak portföyünüzü gözden geçirin'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRiskFactors() {
    final factors = <Widget>[];
    final typeDistribution = _getTypeDistribution();
    final totalValue = _calculateTotalValue();
    final typeCount = typeDistribution.length;

    // Tek varlık türü riski
    if (typeCount == 1) {
      factors.add(
        _buildRiskFactorItem(
          'Tek varlık türünde yoğunlaşma',
          'Yüksek',
          AppColors.negativeDark,
        ),
      );
    }

    // Yoğunlaşma riski
    if (typeDistribution.isNotEmpty && totalValue > 0) {
      final maxEntry = typeDistribution.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final maxPercentage = maxEntry.value / totalValue * 100;
      if (maxPercentage > 50) {
        factors.add(
          _buildRiskFactorItem(
            '${maxEntry.key} türünde %${maxPercentage.toStringAsFixed(0)} yoğunlaşma',
            'Orta',
            const Color(0xFFF59E0B),
          ),
        );
      }
    }

    // Az varlık riski
    if (_userAssets.length < 3) {
      factors.add(
        _buildRiskFactorItem(
          'Düşük varlık çeşitliliği',
          'Orta',
          const Color(0xFFF59E0B),
        ),
      );
    }

    if (factors.isEmpty) {
      factors.add(
        _buildRiskFactorItem(
          'Belirgin risk faktörü tespit edilmedi',
          'Düşük',
          AppColors.positiveDark,
        ),
      );
    }

    return factors;
  }

  Widget _buildRiskFactorItem(String text, String level, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textMainDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risk Azaltma Önerileri',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Farklı varlık sınıflarına yatırım yapın'),
          _buildTipItem('Tek bir varlığa %50\'den fazla ağırlık vermeyin'),
          _buildTipItem('Düzenli aralıklarla portföyünüzü dengeleyin'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 60,
              color: AppColors.textSecondaryDark.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Utility Methods
  double _calculateTotalValue() {
    return _userAssets.fold(0.0, (sum, asset) {
      final totalCost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
      return sum + totalCost;
    });
  }

  Set<String> _getUniqueTypes() {
    return _userAssets.map((a) => a['type'] as String).toSet();
  }

  Map<String, double> _getTypeDistribution() {
    final distribution = <String, double>{};
    for (var asset in _userAssets) {
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
      distribution[type] = (distribution[type] ?? 0.0) + cost;
    }
    return distribution;
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Hisse':
        return const Color(0xFF60A5FA);
      case 'Altın':
        return const Color(0xFFFBBF24);
      case 'Fon':
        return const Color(0xFF8B5CF6);
      case 'Nakit':
        return const Color(0xFF10B981);
      case 'Kripto':
        return const Color(0xFFF97316);
      case 'Döviz':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Hisse':
        return Icons.show_chart_rounded;
      case 'Altın':
        return Icons.payments_rounded;
      case 'Fon':
        return Icons.stacked_line_chart_rounded;
      case 'Nakit':
        return Icons.account_balance_wallet_rounded;
      case 'Kripto':
        return Icons.currency_bitcoin_rounded;
      case 'Döviz':
        return Icons.currency_exchange_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }
}

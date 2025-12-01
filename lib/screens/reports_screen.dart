import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _generateReports();
  }

  Future<void> _generateReports() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    if (userEmail != null) {
      final assets = await PortfolioService.instance.getUserAssets(userEmail);

      // AI benzeri raporlar üret
      final reports = <Map<String, dynamic>>[];

      // 1. Portföy Analiz Raporu
      reports.add(_generatePortfolioAnalysis(assets));

      // 2. Çeşitlendirme Raporu
      reports.add(_generateDiversificationReport(assets));

      // 3. Risk Analizi
      reports.add(_generateRiskAnalysis(assets));

      // 4. Performans Raporu
      reports.add(_generatePerformanceReport(assets));

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _generatePortfolioAnalysis(
    List<Map<String, dynamic>> assets,
  ) {
    if (assets.isEmpty) {
      return {
        'title': 'Portföy Analizi',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF3B82F6),
        'date': DateTime.now(),
        'insights': [
          'Henüz portföyünüzde varlık bulunmuyor.',
          'Çeşitlendirilmiş bir portföy oluşturmak için farklı varlık türlerinden eklemeye başlayın.',
        ],
        'recommendation':
            'Öneri: Hisse senedi, altın ve döviz gibi farklı varlık sınıflarıyla başlayın.',
      };
    }

    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + ((asset['totalCost'] as num?)?.toDouble() ?? 0),
    );
    final assetCount = assets.length;

    // Varlık türlerine göre dağılım
    final typeDistribution = <String, double>{};
    for (var asset in assets) {
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + cost;
    }

    final insights = <String>[
      'Portföyünüzde toplam $assetCount varlık bulunmaktadır.',
      'Toplam portföy değeriniz ₺${totalValue.toStringAsFixed(2)}.',
    ];

    // En büyük varlık türü
    if (typeDistribution.isNotEmpty) {
      final maxType = typeDistribution.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final percentage = (maxType.value / totalValue * 100).toStringAsFixed(1);
      insights.add(
        'En büyük pozisyonunuz ${maxType.key} sınıfında (%$percentage).',
      );
    }

    // Çeşitlendirme kontrolü
    String recommendation;
    if (typeDistribution.length <= 1) {
      recommendation =
          'Öneri: Portföyünüzü çeşitlendirmek için farklı varlık türlerine yatırım yapın.';
    } else if (typeDistribution.length == 2) {
      recommendation =
          'Öneri: İyi bir başlangıç! Daha fazla çeşitlendirme için ek varlık türleri ekleyebilirsiniz.';
    } else {
      recommendation = 'Harika! Portföyünüz iyi çeşitlendirilmiş durumda.';
    }

    return {
      'title': 'Portföy Analizi',
      'icon': Icons.analytics_outlined,
      'color': const Color(0xFF3B82F6),
      'date': DateTime.now(),
      'insights': insights,
      'recommendation': recommendation,
    };
  }

  Map<String, dynamic> _generateDiversificationReport(
    List<Map<String, dynamic>> assets,
  ) {
    if (assets.isEmpty) {
      return {
        'title': 'Çeşitlendirme Raporu',
        'icon': Icons.donut_small_outlined,
        'color': const Color(0xFFF59E0B),
        'date': DateTime.now(),
        'insights': ['Çeşitlendirme analizi için varlık ekleyin.'],
        'recommendation':
            'Risk yönetimi için farklı sektör ve varlık türlerine yatırım yapın.',
      };
    }

    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + ((asset['totalCost'] as num?)?.toDouble() ?? 0),
    );
    final typeDistribution = <String, double>{};

    for (var asset in assets) {
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + cost;
    }

    final insights = <String>[];
    final diversificationScore = typeDistribution.length * 25.0;
    insights.add(
      'Çeşitlendirme skorunuz: ${diversificationScore.toStringAsFixed(0)}/100',
    );

    typeDistribution.forEach((type, value) {
      final percentage = (value / totalValue * 100).toStringAsFixed(1);
      insights.add('$type: %$percentage (₺${value.toStringAsFixed(2)})');
    });

    String recommendation;
    if (diversificationScore < 50) {
      recommendation =
          'Dikkat: Portföyünüz yetersiz çeşitlendirilmiş. Risk seviyenizi azaltmak için farklı varlık türlerine yatırım yapın.';
    } else if (diversificationScore < 75) {
      recommendation =
          'İyi: Portföyünüz orta düzeyde çeşitlendirilmiş. Daha fazla varlık türü ekleyerek riski azaltabilirsiniz.';
    } else {
      recommendation =
          'Mükemmel: Portföyünüz çok iyi çeşitlendirilmiş durumda.';
    }

    return {
      'title': 'Çeşitlendirme Raporu',
      'icon': Icons.donut_small_outlined,
      'color': const Color(0xFFF59E0B),
      'date': DateTime.now(),
      'insights': insights,
      'recommendation': recommendation,
    };
  }

  Map<String, dynamic> _generateRiskAnalysis(
    List<Map<String, dynamic>> assets,
  ) {
    if (assets.isEmpty) {
      return {
        'title': 'Risk Analizi',
        'icon': Icons.shield_outlined,
        'color': const Color(0xFFEF4444),
        'date': DateTime.now(),
        'insights': ['Risk analizi için varlık ekleyin.'],
        'recommendation': 'Risk yönetimi portföy başarısının anahtarıdır.',
      };
    }

    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + ((asset['totalCost'] as num?)?.toDouble() ?? 0),
    );
    final typeDistribution = <String, double>{};

    for (var asset in assets) {
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + cost;
    }

    // Risk seviyesi hesapla (basit model)
    final riskWeights = {
      'Hisse': 0.8,
      'Kripto': 1.0,
      'Döviz': 0.5,
      'Altın': 0.3,
      'Nakit': 0.0,
    };

    double weightedRisk = 0;
    typeDistribution.forEach((type, value) {
      final weight = riskWeights[type] ?? 0.5;
      weightedRisk += (value / totalValue) * weight;
    });

    final riskScore = (weightedRisk * 100).toInt();
    String riskLevel;
    Color riskColor;

    if (riskScore < 30) {
      riskLevel = 'Düşük';
      riskColor = AppColors.positiveDark;
    } else if (riskScore < 60) {
      riskLevel = 'Orta';
      riskColor = const Color(0xFFF59E0B);
    } else {
      riskLevel = 'Yüksek';
      riskColor = AppColors.negativeDark;
    }

    final insights = <String>[
      'Portföy risk seviyeniz: $riskLevel (%$riskScore)',
      'Risk-getiri dengesine göre portföyünüz analiz edildi.',
    ];

    // Nakit oranı kontrolü
    final cashRatio = (typeDistribution['Nakit'] ?? 0) / totalValue;
    if (cashRatio > 0.3) {
      insights.add(
        'Portföyünüzde yüksek oranda nakit var (%${(cashRatio * 100).toStringAsFixed(1)}).',
      );
    }

    String recommendation;
    if (riskScore < 30) {
      recommendation =
          'Portföyünüz düşük riskli. Daha yüksek getiri için riskli varlıkları değerlendirebilirsiniz.';
    } else if (riskScore < 60) {
      recommendation =
          'Risk seviyeniz dengeli. Mevcut stratejiyi sürdürün ve düzenli takip edin.';
    } else {
      recommendation =
          'Yüksek risk seviyesi tespit edildi. Portföyünüzü daha güvenli varlıklarla dengelemeyi düşünün.';
    }

    return {
      'title': 'Risk Analizi',
      'icon': Icons.shield_outlined,
      'color': riskColor,
      'date': DateTime.now(),
      'insights': insights,
      'recommendation': recommendation,
      'riskScore': riskScore,
    };
  }

  Map<String, dynamic> _generatePerformanceReport(
    List<Map<String, dynamic>> assets,
  ) {
    // Satışlardan gelen kar/zarar hesapla
    double totalProfitLoss = 0;
    int salesCount = 0;

    for (var asset in assets) {
      final type = asset['type'] as String;
      if (type == 'Nakit') {
        final nameRaw = asset['name'] as String;
        if (nameRaw.contains('|')) {
          salesCount++;
          final parts = nameRaw.split('|');
          if (parts.length > 1) {
            final profitInfo = parts[1];
            final match = RegExp(
              r'profitLoss:([-\d.]+)',
            ).firstMatch(profitInfo);
            if (match != null) {
              totalProfitLoss += double.tryParse(match.group(1)!) ?? 0;
            }
          }
        }
      }
    }

    final insights = <String>[];

    if (salesCount == 0) {
      insights.add('Henüz gerçekleştirilmiş işlem bulunmuyor.');
      insights.add('Performans takibi için satış işlemi yapın.');
    } else {
      insights.add('Toplam $salesCount satış işlemi gerçekleştirdiniz.');

      if (totalProfitLoss > 0) {
        insights.add(
          'Toplam kazancınız: +₺${totalProfitLoss.toStringAsFixed(2)}',
        );
        insights.add(
          'Ortalama işlem başına kar: ₺${(totalProfitLoss / salesCount).toStringAsFixed(2)}',
        );
      } else if (totalProfitLoss < 0) {
        insights.add(
          'Toplam zararınız: -₺${totalProfitLoss.abs().toStringAsFixed(2)}',
        );
        insights.add(
          'Ortalama işlem başına zarar: ₺${(totalProfitLoss.abs() / salesCount).toStringAsFixed(2)}',
        );
      } else {
        insights.add('Toplam kar/zarar: ₺0.00');
      }
    }

    String recommendation;
    if (salesCount == 0) {
      recommendation =
          'Öneri: Portföy performansını değerlendirmek için düzenli al-sat işlemleri yapın.';
    } else if (totalProfitLoss > 0) {
      recommendation =
          'Harika! Başarılı işlemler gerçekleştiriyorsunuz. Bu stratejiyi sürdürün.';
    } else if (totalProfitLoss < 0) {
      recommendation =
          'Dikkat: Zararlı işlemler var. Stratejinizi gözden geçirmeyi düşünün.';
    } else {
      recommendation =
          'İşlemleriniz başabaş durumda. Piyasayı yakından takip edin.';
    }

    return {
      'title': 'Performans Raporu',
      'icon': Icons.trending_up_outlined,
      'color': totalProfitLoss >= 0
          ? AppColors.positiveDark
          : AppColors.negativeDark,
      'date': DateTime.now(),
      'insights': insights,
      'recommendation': recommendation,
    };
  }

  @override
  Widget build(BuildContext context) {
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
          'AI Raporları',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _generateReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _generateReports,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(_reports[index]);
                },
              ),
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final insights = report['insights'] as List<String>;
    final date = report['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (report['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report['icon'] as IconData,
                  color: report['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMainDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}.${date.month}.${date.year}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grayBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analiz Sonuçları',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...insights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: report['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.textMainDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (report['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (report['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: report['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report['recommendation'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMainDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../services/email_verification_service.dart';
import '../services/backend_api_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import 'add_asset_screen.dart';
import 'transaction_history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'email_verification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _userAssets = [];
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _selectedPeriod = 'Bugün'; // Bugün, Bu Hafta, Bu Ay, Bu Yıl

  // Cache için
  Map<String, dynamic>? _cachedStats;
  int _assetsHashCode = 0;

  // Backend API
  final BackendApiService _backendApi = BackendApiService();
  Map<String, List<dynamic>> _marketPrices = {};

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _loadDashboardData();
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUserEmail;
    if (email != null) {
      final isVerified = await EmailVerificationService.instance
          .isEmailVerified(email);
      if (mounted && !isVerified) {
        _showVerificationWarning();
      }
    }
  }

  void _showVerificationWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.85),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E2E), Color(0xFF151520)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4F46E5).withOpacity(0.2),
                          const Color(0xFF7C3AED).withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFF818CF8),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Email Doğrulaması Gerekli',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gösterge panelini kullanabilmek için önce email adresinizi doğrulamanız gerekmektedir.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Şimdi Doğrula Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final email = authProvider.currentUserEmail;

                        if (email != null && email.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmailVerificationScreen(email: email),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _checkEmailVerification();
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Şimdi Doğrula',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Geri Dön Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, 'openDrawer');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: const Color(0xFF94A3B8).withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'Geri Dön',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    if (userEmail != null) {
      // Backend'den market prices yükle
      await _loadMarketPrices();

      final assets = await PortfolioService.instance.getUserAssets(userEmail);

      // Sadece assets değiştiyse stats'ı yeniden hesapla
      final newHashCode = assets.hashCode;
      Map<String, dynamic> stats;

      if (_assetsHashCode == newHashCode && _cachedStats != null) {
        stats = _cachedStats!; // Cache'den al
      } else {
        stats = _calculateStats(assets);
        _cachedStats = stats;
        _assetsHashCode = newHashCode;
      }

      if (mounted) {
        setState(() {
          _userAssets = assets;
          _stats = stats;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMarketPrices() async {
    try {
      final stocks = await _backendApi.getStocks();
      final forex = await _backendApi.getForex();
      final commodities = await _backendApi.getCommodities();

      _marketPrices = {
        'stocks': stocks,
        'forex': forex,
        'commodities': commodities,
      };
    } catch (e) {
      AppLogger.error('Error loading market prices for dashboard', e);
      _marketPrices = {};
    }
  }

  String _extractSymbol(String name) {
    // Asset name'den symbol çıkar
    // Format: "THYAO | Profit..." veya sadece "THYAO"
    if (name.contains('|')) {
      return name.split('|')[0].trim();
    }
    return name.trim();
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> assets) {
    if (assets.isEmpty) {
      return {
        'totalValue': 0.0,
        'totalAssets': 0,
        'assetTypes': 0,
        'dailyChange': 0.0,
        'weeklyChange': 0.0,
        'monthlyChange': 0.0,
        'yearlyChange': 0.0,
        'totalProfit': 0.0,
        'profitPercentage': 0.0,
        'bestPerformer': null,
        'worstPerformer': null,
        'bestPerformerProfit': 0.0,
        'worstPerformerLoss': 0.0,
        'assetDistribution': <String, double>{},
      };
    }

    final totalValue = assets.fold<double>(
      0.0,
      (sum, asset) => sum + ((asset['totalCost'] as num?)?.toDouble() ?? 0.0),
    );

    final assetTypes = <String>{};
    final distribution = <String, double>{};

    // En iyi ve en kötü performans gösteren varlıkları bul
    String? bestPerformer;
    String? worstPerformer;
    double bestProfit = 0.0;
    double worstLoss = 0.0;

    for (var asset in assets) {
      final type = asset['type'] as String? ?? 'Bilinmeyen';
      final name = asset['name'] as String? ?? 'Bilinmeyen';
      final totalCost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
      final purchasePrice = (asset['purchasePrice'] as num?)?.toDouble() ?? 0.0;
      final quantity = (asset['quantity'] as num?)?.toDouble() ?? 0.0;

      assetTypes.add(type);
      distribution[type] = (distribution[type] ?? 0.0) + totalCost;

      // Backend'den gerçek güncel fiyat al (eğer varsa)
      double currentPrice = purchasePrice; // Default: satın alma fiyatı

      try {
        final symbol = _extractSymbol(name);
        if (symbol.isNotEmpty) {
          if (type == 'Hisse' && _marketPrices['stocks'] != null) {
            final stock = _marketPrices['stocks']!.firstWhere(
              (s) => s['symbol'].toString().toUpperCase().contains(
                symbol.toUpperCase(),
              ),
              orElse: () => {},
            );
            if (stock.isNotEmpty) {
              currentPrice = stock['price']?.toDouble() ?? purchasePrice;
            }
          } else if (type == 'Döviz' && _marketPrices['forex'] != null) {
            final forex = _marketPrices['forex']!.firstWhere(
              (f) => f['symbol'].toString().toUpperCase().contains(
                symbol.toUpperCase(),
              ),
              orElse: () => {},
            );
            if (forex.isNotEmpty) {
              currentPrice = forex['price']?.toDouble() ?? purchasePrice;
            }
          } else if ((type == 'Altın' || type == 'Emtia') &&
              _marketPrices['commodities'] != null) {
            final commodity = _marketPrices['commodities']!.firstWhere(
              (c) => c['symbol'].toString().toUpperCase().contains(
                symbol.toUpperCase(),
              ),
              orElse: () => {},
            );
            if (commodity.isNotEmpty) {
              currentPrice = commodity['price']?.toDouble() ?? purchasePrice;
            }
          }
        }
      } catch (e) {
        AppLogger.error('Error getting current price for $name', e);
      }

      final currentValue = currentPrice * quantity;
      final profit = currentValue - totalCost;

      if (profit > bestProfit) {
        bestProfit = profit;
        bestPerformer = name;
      }
      if (profit < worstLoss) {
        worstLoss = profit;
        worstPerformer = name;
      }
    }

    // Simulated changes
    final seed = totalValue.toInt();
    final dailyChange = ((seed % 100) / 100.0) * 3.5 - 0.5;
    final weeklyChange = ((seed % 150) / 150.0) * 8.0 - 2.0;
    final monthlyChange = ((seed % 200) / 200.0) * 15.0 - 5.0;
    final yearlyChange = ((seed % 300) / 300.0) * 35.0 - 10.0;

    final totalProfit = totalValue * (dailyChange / 100);
    final profitPercentage = dailyChange;

    return {
      'totalValue': totalValue,
      'totalAssets': assets.length,
      'assetTypes': assetTypes.length,
      'dailyChange': dailyChange,
      'weeklyChange': weeklyChange,
      'monthlyChange': monthlyChange,
      'yearlyChange': yearlyChange,
      'totalProfit': totalProfit,
      'profitPercentage': profitPercentage,
      'bestPerformer': bestPerformer,
      'worstPerformer': worstPerformer,
      'bestPerformerProfit': bestProfit,
      'worstPerformerLoss': worstLoss,
      'assetDistribution': distribution,
    };
  }

  double _getCurrentChange() {
    switch (_selectedPeriod) {
      case 'Bu Hafta':
        return _stats['weeklyChange'] ?? 0.0;
      case 'Bu Ay':
        return _stats['monthlyChange'] ?? 0.0;
      case 'Bu Yıl':
        return _stats['yearlyChange'] ?? 0.0;
      default:
        return _stats['dailyChange'] ?? 0.0;
    }
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
          onPressed: () => Navigator.pop(context, 'openDrawer'),
        ),
        title: Text(
          'Gösterge Paneli',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textMainDark,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardDark,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildMainPortfolioCard(),
                    const SizedBox(height: 20),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildSummaryGrid(),
                    const SizedBox(height: 24),
                    _buildAssetDistribution(),
                    const SizedBox(height: 24),
                    _buildTodaySummary(),
                    const SizedBox(height: 24),
                    _buildMarketStatus(),
                    const SizedBox(height: 24),
                    _buildQuickActionsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 18) {
      greeting = 'İyi günler';
    } else {
      greeting = 'İyi akşamlar';
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    String userName = 'Kullanıcı';
    if (currentUser != null) {
      if (currentUser['fullName'] != null &&
          currentUser['fullName']!.isNotEmpty) {
        userName = currentUser['fullName']!;
      } else {
        final email = currentUser['email'] ?? '';
        if (email.contains('@')) {
          userName = email.split('@')[0];
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildMainPortfolioCard() {
    final totalValue = _stats['totalValue'] ?? 0.0;
    final currentChange = _getCurrentChange();
    final isPositive = currentChange >= 0;
    final profit = _stats['totalProfit'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam Değer',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${currentChange.toStringAsFixed(2)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₺${totalValue.toStringAsFixed(2)}',
            style: GoogleFonts.manrope(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}₺${profit.abs().toStringAsFixed(2)} $_selectedPeriod',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Bugün', 'Bu Hafta', 'Bu Ay', 'Bu Yıl'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            Icons.account_balance_wallet_outlined,
            '${_stats['totalAssets'] ?? 0}',
            'Varlık',
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            Icons.pie_chart_outline,
            '${_stats['assetTypes'] ?? 0}',
            'Kategori',
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            Icons.show_chart,
            '${_getCurrentChange().toStringAsFixed(1)}%',
            'Değişim',
            _getCurrentChange() >= 0
                ? AppColors.positiveDark
                : AppColors.negativeDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDistribution() {
    final distribution =
        _stats['assetDistribution'] as Map<String, double>? ?? {};

    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalValue = _stats['totalValue'] ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Varlık Dağılımı',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: distribution.entries.map((entry) {
              final percentage = (entry.value / totalValue) * 100;
              Color barColor;
              IconData icon;

              switch (entry.key) {
                case 'Hisse':
                  barColor = const Color(0xFF3B82F6);
                  icon = Icons.show_chart;
                case 'Altın':
                  barColor = const Color(0xFFEAB308);
                  icon = Icons.monetization_on;
                case 'Kripto':
                  barColor = const Color(0xFFF97316);
                  icon = Icons.currency_bitcoin;
                case 'Döviz':
                  barColor = const Color(0xFF10B981);
                  icon = Icons.attach_money;
                default:
                  barColor = AppColors.primary;
                  icon = Icons.account_balance_wallet;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: barColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMainDark,
                            ),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.grayBg,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    final bestPerformer = _stats['bestPerformer'] as String?;
    final bestProfit =
        (_stats['bestPerformerProfit'] as num?)?.toDouble() ?? 0.0;
    final lastAsset = _userAssets.isNotEmpty ? _userAssets.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugünün Özeti',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        const SizedBox(height: 16),
        // En Çok Kazandıran - Dinamik
        _buildSummaryItem(
          Icons.trending_up,
          'En Çok Kazandıran',
          bestPerformer ?? 'Yok',
          bestProfit != 0.0
              ? '${bestProfit >= 0 ? '+' : ''}₺${bestProfit.toStringAsFixed(2)}'
              : '₺0.00',
          bestProfit >= 0 ? AppColors.positiveDark : AppColors.negativeDark,
        ),
        const SizedBox(height: 12),
        // Son Eklenen - Dinamik
        _buildSummaryItem(
          Icons.add_circle_outline,
          'Son Eklenen',
          lastAsset?['name'] ?? 'Yok',
          lastAsset != null
              ? '₺${((lastAsset['totalCost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'
              : '₺0.00',
          AppColors.primary,
        ),
        const SizedBox(height: 12),
        // Portföy Performansı - Dinamik
        _buildSummaryItem(
          Icons.star_outline,
          'Portföy Performansı',
          _getCurrentChange() >= 0 ? 'İyi' : 'Düşüş',
          '${_getCurrentChange().toStringAsFixed(1)}%',
          _getCurrentChange() >= 0
              ? AppColors.positiveDark
              : AppColors.negativeDark,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMainDark,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Piyasa Durumu',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              _buildMarketItem('BIST 100', '9.456,23', '+1.23%', true),
              const Divider(color: AppColors.borderDark, height: 24),
              _buildMarketItem('Dolar/TL', '34,25', '+0.45%', true),
              const Divider(color: AppColors.borderDark, height: 24),
              _buildMarketItem('Altın (gr)', '2.856,50', '-0.12%', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketItem(
    String name,
    String value,
    String change,
    bool isPositive,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMainDark,
              ),
            ),
            const SizedBox(height: 4),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                (isPositive ? AppColors.positiveDark : AppColors.negativeDark)
                    .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            change,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? AppColors.positiveDark
                  : AppColors.negativeDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              Icons.add_circle_outline,
              'Varlık Ekle',
              AppColors.primary,
              () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAssetScreen(),
                  ),
                );
                if (result == true && mounted) {
                  _loadDashboardData();
                }
              },
            ),
            _buildActionCard(
              Icons.history,
              'İşlem Geçmişi',
              const Color(0xFF10B981),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              Icons.analytics_outlined,
              'Raporlar',
              const Color(0xFF3B82F6),
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
                if (mounted) {
                  _loadDashboardData();
                }
              },
            ),
            _buildActionCard(
              Icons.settings_outlined,
              'Ayarlar',
              const Color(0xFF8B5CF6),
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                if (mounted) {
                  _loadDashboardData();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMainDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

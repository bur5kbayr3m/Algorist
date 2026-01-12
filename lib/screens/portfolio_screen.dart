import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import 'add_asset_screen.dart';
import 'analytics_screen.dart';
import 'markets_screen.dart';
import 'dashboard_screen.dart';
import 'edit_portfolio_screen.dart';
import 'asset_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/offline_mode_banner.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/refreshable_scroll_view.dart';
import '../widgets/global_search_bar.dart';
import '../utils/error_handler.dart';
import 'transaction_history_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

enum TimePeriod { daily, weekly, monthly, allTime }

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<Map<String, dynamic>> _userAssets = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  final List<String> _enabledWidgets = []; // 'chart', 'density', etc.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TimePeriod _selectedPeriod = TimePeriod.daily;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserAssets();
        _loadWidgetPreferencesSimple();
      }
    });
  }

  Future<void> _loadWidgetPreferencesSimple() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.currentUserEmail;

      if (userEmail != null && mounted) {
        final preferences = await DatabaseService.instance
            .loadWidgetPreferences(userEmail);
        if (mounted) {
          setState(() {
            _enabledWidgets.clear();
            _enabledWidgets.addAll(preferences);
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading widget preferences', e);
    }
  }

  Future<void> _loadUserAssets() async {
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

  // Widget preferences _loadWidgetPreferencesSimple metodunda yükleniyor

  Future<void> _saveWidgetPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    if (userEmail != null) {
      await DatabaseService.instance.saveWidgetPreferences(
        userEmail,
        _enabledWidgets,
      );
    }
  }

  Future<void> _navigateToAddAsset() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => const AddAssetScreen()),
    );

    if (result == true) {
      await _loadUserAssets();
    } else if (result == 'openDrawer') {
      await _loadUserAssets();
      // Drawer'ı aç
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scaffoldKey.currentState?.openDrawer();
        }
      });
    }
  }

  void _showFABMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: AppColors.borderDark.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondaryDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildFABMenuItem(
              icon: Icons.add_circle_outline,
              title: 'Varlık Ekle',
              subtitle: 'Portföyünüze yeni varlık ekleyin',
              onTap: () async {
                Navigator.pop(context);
                await _navigateToAddAsset();
              },
            ),
            const SizedBox(height: 12),
            _buildFABMenuItem(
              icon: Icons.edit_outlined,
              title: 'Portföyü Düzenle',
              subtitle: 'Varlıklarınızı düzenleyin veya satın',
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPortfolioScreen(),
                  ),
                );
                if (result == true) {
                  await _loadUserAssets();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFABMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131022),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMainDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondaryDark,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalValue() {
    return _userAssets.fold(0.0, (sum, asset) {
      final totalCost = asset['totalCost'] as num?;
      return sum + (totalCost?.toDouble() ?? 0.0);
    });
  }

  double _getHighestAssetValue() {
    if (_userAssets.isEmpty) return 0.0;
    return _userAssets
        .map((asset) => (asset['totalCost'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
  }

  double _getLowestAssetValue() {
    if (_userAssets.isEmpty) return 0.0;
    return _userAssets
        .map((asset) => (asset['totalCost'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
  }

  Map<String, dynamic> _calculatePeriodChange() {
    if (_userAssets.isEmpty) {
      return {'change': 0.0, 'percentage': 0.0, 'isPositive': true};
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case TimePeriod.daily:
        startDate = now.subtract(const Duration(days: 1));
        break;
      case TimePeriod.weekly:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.monthly:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimePeriod.allTime:
        // En eski varlık tarihini bul
        startDate = _userAssets
            .map((asset) {
              final dateStr = asset['addedAt'] as String?;
              if (dateStr != null) {
                try {
                  return DateTime.parse(dateStr);
                } catch (e) {
                  return now;
                }
              }
              return now;
            })
            .reduce((a, b) => a.isBefore(b) ? a : b);
        break;
    }

    // Satışlardan gelen kar/zararı hesapla
    double totalProfitLoss = 0.0;

    for (var asset in _userAssets) {
      final type = asset['type'] as String;

      // Nakit varlıklardan kar/zarar çıkar
      if (type == 'Nakit') {
        final nameRaw = asset['name'] as String;
        if (nameRaw.contains('|')) {
          final parts = nameRaw.split('|');
          if (parts.length > 1) {
            final profitInfo = parts[1];
            final profitLossMatch = RegExp(
              r'profitLoss:([-\d.]+)',
            ).firstMatch(profitInfo);
            if (profitLossMatch != null) {
              final profitLoss =
                  double.tryParse(profitLossMatch.group(1)!) ?? 0.0;
              totalProfitLoss += profitLoss;
            }
          }
        }
      }
    }

    final totalValue = _calculateTotalValue();

    // Eğer satıştan kar/zarar varsa, ona göre hesapla
    if (totalProfitLoss != 0.0) {
      // Gerçek yatırım = toplam değer - kar/zarar
      final realInvestment = totalValue - totalProfitLoss;
      final changePercentage = realInvestment > 0
          ? (totalProfitLoss / realInvestment) * 100
          : 0.0;

      return {
        'change': totalProfitLoss,
        'percentage': changePercentage,
        'isPositive': totalProfitLoss >= 0,
      };
    }

    // Satış yoksa basit simülasyon
    final daysSinceStart = now.difference(startDate).inDays;
    final seed = totalValue.toInt() + daysSinceStart;
    final random = (seed % 100) / 100.0;
    final changePercentage = (random * 3.5) - 0.5;
    final changeAmount = totalValue * (changePercentage / 100);

    return {
      'change': changeAmount,
      'percentage': changePercentage,
      'isPositive': changePercentage >= 0,
    };
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return 'Bugün';
      case TimePeriod.weekly:
        return 'Bu Hafta';
      case TimePeriod.monthly:
        return 'Bu Ay';
      case TimePeriod.allTime:
        return 'Tüm Zamanlar';
    }
  }

  void _cyclePeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case TimePeriod.daily:
          _selectedPeriod = TimePeriod.weekly;
          break;
        case TimePeriod.weekly:
          _selectedPeriod = TimePeriod.monthly;
          break;
        case TimePeriod.monthly:
          _selectedPeriod = TimePeriod.allTime;
          break;
        case TimePeriod.allTime:
          _selectedPeriod = TimePeriod.daily;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.backgroundDark,
          drawer: _buildDrawer(),
          body: SafeArea(
            child: _isLoading
                ? const PortfolioSkeletonLoader()
                : RefreshIndicator(
                    onRefresh: _loadUserAssets,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAppBar(),
                          const SizedBox(height: 24),
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildPortfolioSummary(),
                          const SizedBox(height: 24),
                          if (_isEditMode) ...[
                            _buildWidgetSelector(),
                            const SizedBox(height: 24),
                          ],
                          ..._buildDynamicWidgets(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Varlıklarım',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMainDark,
                                ),
                              ),
                              if (_userAssets.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_userAssets.length} varlık',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildAssetList(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
          bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
          floatingActionButton: _buildFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
        const OfflineModeBanner(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Hamburger Menu
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textMainDark,
                size: 24,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          const Spacer(),
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Algorist',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMainDark,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Edit Button
          Container(
            decoration: BoxDecoration(
              color: _isEditMode
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: _isEditMode
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                _isEditMode ? Icons.check_rounded : Icons.tune_rounded,
                color: _isEditMode ? AppColors.primary : AppColors.textMainDark,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Günaydın';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = 'İyi günler';
      greetingIcon = Icons.light_mode_rounded;
    } else {
      greeting = 'İyi akşamlar';
      greetingIcon = Icons.nightlight_round;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(greetingIcon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '$greeting, $userName',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Portföyüm',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSummary() {
    final totalValue = _calculateTotalValue();
    final hasAssets = _userAssets.isNotEmpty;
    final periodChange = _calculatePeriodChange();
    final isPositive = periodChange['isPositive'] as bool;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toplam Varlık Değeri',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₺${_formatNumber(totalValue)}',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          if (hasAssets) ...[
            const SizedBox(height: 16),
            // Kar/Zarar satırı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isPositive ? '+' : ''}₺${_formatNumber((periodChange['change'] as double).abs())}',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${(periodChange['percentage'] as double).toStringAsFixed(1)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Dönem seçici
                GestureDetector(
                  onTap: _cyclePeriod,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getPeriodLabel(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sync_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!hasAssets) ...[
            const SizedBox(height: 12),
            Text(
              'Henüz varlık eklenmedi',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildAssetList() {
    if (_userAssets.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppColors.textSecondaryDark.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz varlık eklenmemiş',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Artı butonuna basarak ilk varlığınızı ekleyin',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _userAssets.map((asset) => _buildAssetCard(asset)).toList(),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final type = asset['type'] as String;
    final nameRaw = asset['name'] as String;
    final quantity = asset['quantity'] as num?;
    final totalCost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;

    // Kar/Zarar bilgisini parse et
    String name = nameRaw;
    double? profitLossPercent;

    if (nameRaw.contains('|')) {
      final parts = nameRaw.split('|');
      name = parts[0];
      if (parts.length > 1 && type == 'Nakit') {
        final profitInfo = parts[1];
        final match = RegExp(
          r'profitLossPercent:([-\d.]+)',
        ).firstMatch(profitInfo);
        if (match != null) {
          profitLossPercent = double.tryParse(match.group(1)!);
        }
      }
    }

    // Icon ve renk belirleme
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (type) {
      case 'Hisse':
        icon = Icons.show_chart;
        iconBg = AppColors.grayBg;
        iconColor = const Color(0xFFD1D5DB); // gray-300
        break;
      case 'Altın':
        icon = Icons.payments;
        iconBg = AppColors.yellowBg;
        iconColor = const Color(0xFFFBBF24); // yellow-400
        break;
      case 'Fon':
        icon = Icons.stacked_line_chart;
        iconBg = AppColors.blueBg;
        iconColor = const Color(0xFF60A5FA); // blue-400
        break;
      case 'Nakit':
        icon = Icons.account_balance_wallet;
        iconBg = AppColors.greenBg;
        iconColor = const Color(0xFF10B981); // green-500
        break;
      default:
        icon = Icons.account_balance_wallet;
        iconBg = AppColors.greenBg;
        iconColor = const Color(0xFF34D399); // green-400
    }
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMainDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₺${totalCost.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMainDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$type${quantity != null ? ' • ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)}' : ''}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                      if (profitLossPercent != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (profitLossPercent >= 0
                                        ? AppColors.positiveDark
                                        : AppColors.negativeDark)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: profitLossPercent >= 0
                                  ? AppColors.positiveDark
                                  : AppColors.negativeDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    // Email'den kullanıcı adı oluştur
    String userName = 'Kullanıcı';
    String userEmail = 'user@example.com';
    String? profileImagePath;

    if (currentUser != null) {
      userEmail = currentUser['email'] ?? 'user@example.com';
      profileImagePath = currentUser['profileImage'];

      // Önce fullName'e bak, yoksa email'den username oluştur
      if (currentUser['fullName'] != null &&
          currentUser['fullName']!.isNotEmpty) {
        userName = currentUser['fullName']!;
      } else {
        // Email'in @ işaretinden öncesini al ve ilk harfi büyüt
        final emailUsername = userEmail.split('@')[0];
        userName =
            emailUsername.substring(0, 1).toUpperCase() +
            emailUsername.substring(1);
      }
    }

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header - User Info (Tıklanabilir)
            InkWell(
              onTap: () {
                _navigateFromDrawer(context, const ProfileScreen());
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            profileImagePath != null &&
                                profileImagePath.isNotEmpty
                            ? Image.file(
                                File(profileImagePath),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 32,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMainDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.textSecondaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondaryDark,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Gösterge Paneli', () {
                    _navigateFromDrawer(context, const DashboardScreen());
                  }),
                  _buildDrawerItem(Icons.history, 'İşlem Geçmişi', () {
                    _navigateFromDrawer(
                      context,
                      const TransactionHistoryScreen(),
                    );
                  }),
                  _buildDrawerItem(Icons.analytics, 'Analizler', () {
                    _navigateFromDrawer(context, AnalyticsScreen());
                  }),
                  _buildDrawerItem(Icons.trending_up, 'Piyasalar', () {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (authProvider.currentUserEmail != null) {
                      _navigateFromDrawer(
                        context,
                        MarketsScreen(
                          userEmail: authProvider.currentUserEmail!,
                        ),
                      );
                    }
                  }),
                  _buildDrawerItem(Icons.notifications, 'Bildirimler', () {
                    _navigateFromDrawer(context, const NotificationsScreen());
                  }),
                  const Divider(color: AppColors.borderDark, height: 1),
                  _buildDrawerItem(Icons.settings, 'Ayarlar', () {
                    _navigateFromDrawer(context, const SettingsScreen());
                  }),
                  _buildDrawerItem(Icons.help_outline, 'Yardım', () {
                    _navigateFromDrawer(context, const HelpScreen());
                  }),
                  _buildDrawerItem(Icons.info_outline, 'Hakkında', () {
                    _navigateFromDrawer(context, const AboutScreen());
                  }),
                  const Divider(color: AppColors.borderDark, height: 1),
                  _buildDrawerItem(
                    Icons.bug_report,
                    'Debug: Tüm Veriler',
                    () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await DatabaseService.instance.printAllData();
                      if (authProvider.currentUserEmail != null) {
                        await DatabaseService.instance.printUserData(
                          authProvider.currentUserEmail!,
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veriler terminale yazdırıldı!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    isDestructive: false,
                  ),
                  _buildDrawerItem(Icons.logout, 'Çıkış Yap', () async {
                    // Önce onay dialogu göster
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Çıkış Yap',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
                          style: GoogleFonts.manrope(
                            color: AppColors.textSecondaryDark,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'İptal',
                              style: GoogleFonts.manrope(
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Çıkış Yap',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    // Kullanıcı onayladıysa çıkış yap
                    if (shouldLogout == true && mounted) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    }
                  }, isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? AppColors.negativeDark
            : AppColors.textSecondaryDark,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? AppColors.negativeDark
              : AppColors.textMainDark,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _navigateFromDrawer(BuildContext context, Widget screen) {
    Navigator.pop(context); // Drawer'ı kapat

    Navigator.push<String>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade + Yumuşak scale animasyonu
          return FadeTransition(
            opacity: animation.drive(
              Tween(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: ScaleTransition(
              scale: animation.drive(
                Tween(
                  begin: 0.95,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    ).then((result) {
      // Geri dönüldüğünde verileri yenile
      if (mounted) {
        _loadUserAssets();
        // Drawer'ı yenilemek için setState çağır (profil fotoğrafı güncellenmesi için)
        setState(() {});
        // 'openDrawer' sinyali geldiyse drawer'ı aç
        if (result == 'openDrawer') {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              _scaffoldKey.currentState?.openDrawer();
            }
          });
        }
      }
    });
  }

  Widget _buildWidgetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Widget Ekle',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildWidgetButton('Dağılım Grafiği', Icons.pie_chart, 'chart'),
              const SizedBox(width: 12),
              _buildWidgetButton(
                'Yoğunluk Grafiği',
                Icons.bar_chart,
                'density',
              ),
              const SizedBox(width: 12),
              _buildWidgetButton(
                'Performans',
                Icons.trending_up,
                'performance',
              ),
              const SizedBox(width: 12),
              _buildWidgetButton('İstatistikler', Icons.analytics, 'stats'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetButton(String title, IconData icon, String widgetId) {
    final isEnabled = _enabledWidgets.contains(widgetId);

    return GestureDetector(
      onTap: () async {
        setState(() {
          if (isEnabled) {
            _enabledWidgets.remove(widgetId);
          } else {
            _enabledWidgets.add(widgetId);
          }
        });
        await _saveWidgetPreferences();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? AppColors.primary : AppColors.borderDark,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.white : AppColors.textSecondaryDark,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : AppColors.textMainDark,
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicWidgets() {
    List<Widget> widgets = [];

    for (var widgetId in _enabledWidgets) {
      switch (widgetId) {
        case 'chart':
          widgets.add(_buildChartWidget());
          widgets.add(const SizedBox(height: 24));
          break;
        case 'density':
          widgets.add(_buildDensityWidget());
          widgets.add(const SizedBox(height: 24));
          break;
        case 'performance':
          widgets.add(_buildPerformanceWidget());
          widgets.add(const SizedBox(height: 24));
          break;
        case 'stats':
          widgets.add(_buildStatsWidget());
          widgets.add(const SizedBox(height: 24));
          break;
      }
    }

    return widgets;
  }

  Widget _buildChartWidget() {
    // Varlık tipine göre gruplama
    final Map<String, double> typeDistribution = {};
    for (var asset in _userAssets) {
      final type = asset['type'] as String;
      final cost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
      typeDistribution[type] = (typeDistribution[type] ?? 0.0) + cost;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portföy Dağılımı',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              if (_isEditMode)
                IconButton(
                  icon: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondaryDark,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userAssets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Dağılım görmek için varlık ekleyin',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            )
          else
            Column(
              children: typeDistribution.entries.map((entry) {
                final percentage = _calculateTotalValue() > 0
                    ? (entry.value / _calculateTotalValue() * 100)
                    : 0.0;

                Color color;
                IconData icon;
                switch (entry.key) {
                  case 'Hisse':
                    color = const Color(0xFF818CF8); // Indigo açık
                    icon = Icons.show_chart;
                    break;
                  case 'Altın':
                    color = const Color(0xFFFBBF24); // Altın sarısı
                    icon = Icons.payments;
                    break;
                  case 'Fon':
                    color = const Color(0xFF4F46E5); // Indigo ana
                    icon = Icons.stacked_line_chart;
                    break;
                  default:
                    color = const Color(0xFF7C3AED); // Mor
                    icon = Icons.account_balance_wallet;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(icon, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: AppColors.textMainDark,
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMainDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₺${entry.value.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.textSecondaryDark,
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
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDensityWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Varlık Değerleri',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              if (_isEditMode)
                IconButton(
                  icon: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondaryDark,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userAssets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Analiz için varlık ekleyin',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _userAssets.take(6).map((asset) {
                  final value = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
                  final maxValue = _getHighestAssetValue();
                  final heightPercentage = maxValue > 0
                      ? (value / maxValue)
                      : 0.0;

                  Color color;
                  switch (asset['type'] as String) {
                    case 'Hisse':
                      color = const Color(0xFF818CF8); // Indigo açık
                      break;
                    case 'Altın':
                      color = const Color(0xFFFBBF24); // Altın sarısı
                      break;
                    case 'Fon':
                      color = const Color(0xFF4F46E5); // Indigo ana
                      break;
                    default:
                      color = const Color(0xFF7C3AED); // Mor
                  }

                  // Tek varlık varsa genişliği sınırla
                  final barWidth = _userAssets.length == 1 ? 60.0 : null;

                  return _userAssets.length == 1
                      ? SizedBox(
                          width: barWidth,
                          child: _buildBarColumn(
                            asset,
                            value,
                            heightPercentage,
                            color,
                          ),
                        )
                      : Expanded(
                          child: _buildBarColumn(
                            asset,
                            value,
                            heightPercentage,
                            color,
                          ),
                        );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(
    Map<String, dynamic> asset,
    double value,
    double heightPercentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '₺${value.toStringAsFixed(0)}',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.textSecondaryDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            height: 150 * heightPercentage,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final nameRaw = asset['name'] as String;
              final cleanName = nameRaw.contains('|')
                  ? nameRaw.split('|')[0]
                  : nameRaw;
              return Text(
                cleanName.length > 5
                    ? '${cleanName.substring(0, 5)}...'
                    : cleanName,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: AppColors.textMainDark,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceWidget() {
    final totalValue = _calculateTotalValue();
    final assetCount = _userAssets.length;
    final avgValue = assetCount > 0 ? totalValue / assetCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portföy Özeti',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              if (_isEditMode)
                IconButton(
                  icon: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondaryDark,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userAssets.isEmpty)
            Center(
              child: Text(
                'Özet için varlık ekleyin',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Toplam',
                  '₺${totalValue.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
                _buildSummaryItem(
                  'Ortalama',
                  '₺${avgValue.toStringAsFixed(0)}',
                  Icons.analytics,
                  const Color(0xFF60A5FA),
                ),
                _buildSummaryItem(
                  'Varlık',
                  '$assetCount',
                  Icons.inventory_2,
                  const Color(0xFF34D399),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
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
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İstatistikler',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              if (_isEditMode)
                IconButton(
                  icon: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondaryDark,
                  ),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Toplam Varlık', _userAssets.length.toString()),
          const SizedBox(height: 12),
          _buildStatRow(
            'Toplam Değer',
            '₺${_calculateTotalValue().toStringAsFixed(2)}',
          ),
          if (_userAssets.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatRow(
              'En Yüksek Değer',
              '₺${_getHighestAssetValue().toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'En Düşük Değer',
              '₺${_getLowestAssetValue().toStringAsFixed(2)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
      ],
    );
  }

  void _showCustomSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showFABMenu,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

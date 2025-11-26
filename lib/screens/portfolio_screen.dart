import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../services/database_service.dart';
import 'add_asset_screen.dart';

class AppColors {
  // Primary Color (matching HTML #4b2bee)
  static const primary = Color(0xFF4B2BEE);

  // Background Colors
  static const backgroundLight = Color(0xFFF6F6F8);
  static const backgroundDark = Color(0xFF131022);

  // Card/Surface Colors (white with opacity)
  static const cardDark = Color(0x0DFFFFFF); // white/5

  // Text Colors
  static const textMainDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFF9CA3AF); // gray-400

  // Status Colors
  static const positiveDark = Color(0xFF34C759);
  static const negativeDark = Color(0xFFFF3B30);

  // Icon background colors
  static const grayBg = Color(0xFF1F2937); // gray-800
  static const yellowBg = Color(0x66713F12); // yellow-900/40
  static const blueBg = Color(0x661E3A8A); // blue-900/40
  static const greenBg = Color(0x66065F46); // green-900/40

  // Border
  static const borderDark = Color(0x1AFFFFFF); // white/10
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<Map<String, dynamic>> _userAssets = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  final List<String> _enabledWidgets = []; // 'chart', 'density', etc.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserAssets();
  }

  Future<void> _loadUserAssets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    print('🔍 Loading assets for user: $userEmail');

    if (userEmail != null) {
      final assets = await PortfolioService.instance.getUserAssets(userEmail);
      print('📦 Loaded ${assets.length} assets');
      print('📊 Assets data: $assets');
      setState(() {
        _userAssets = assets;
        _isLoading = false;
      });
    } else {
      print('❌ No user email found');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddAssetScreen()),
    );

    if (result == true) {
      await _loadUserAssets();
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildPortfolioSummary(),
                    const SizedBox(height: 32),
                    if (_isEditMode) _buildWidgetSelector(),
                    if (_isEditMode) const SizedBox(height: 24),
                    ..._buildDynamicWidgets(),
                    const SizedBox(height: 32),
                    _buildAssetList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAsset,
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: AppColors.textSecondaryDark,
              size: 28,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          Text(
            'Algorist',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Portföyüm',
      style: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textMainDark,
        height: 1.2,
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    final totalValue = _calculateTotalValue();
    final hasAssets = _userAssets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toplam Varlık Değeri',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₺${totalValue.toStringAsFixed(2)}',
          style: GoogleFonts.manrope(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
            height: 1.2,
          ),
        ),
        if (hasAssets) ...[
          const SizedBox(height: 8),
          Text(
            'Varlık sayısı: ${_userAssets.length}',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ],
    );
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
    final name = asset['name'] as String;
    final quantity = asset['quantity'] as num?;
    final totalCost = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;

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
      default:
        icon = Icons.account_balance_wallet;
        iconBg = AppColors.greenBg;
        iconColor = const Color(0xFF34D399); // green-400
    }

    return Container(
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
                Text(
                  '$type${quantity != null ? ' • ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)}' : ''}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Email'den kullanıcı adı oluştur
    String userName = 'Kullanıcı';
    String userEmail = 'user@example.com';

    if (currentUser != null) {
      userEmail = currentUser['email'] ?? 'user@example.com';

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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 32,
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
                ],
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.dashboard, 'Gösterge Paneli', () {}),
                  _buildDrawerItem(
                    Icons.account_balance_wallet,
                    'Varlıklarım',
                    () {},
                  ),
                  _buildDrawerItem(Icons.history, 'İşlem Geçmişi', () {}),
                  _buildDrawerItem(Icons.analytics, 'Analizler', () {}),
                  _buildDrawerItem(Icons.notifications, 'Bildirimler', () {}),
                  const Divider(color: AppColors.borderDark, height: 1),
                  _buildDrawerItem(Icons.settings, 'Ayarlar', () {}),
                  _buildDrawerItem(Icons.help_outline, 'Yardım', () {}),
                  _buildDrawerItem(Icons.info_outline, 'Hakkında', () {}),
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
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
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
      onTap: () {
        setState(() {
          if (isEnabled) {
            _enabledWidgets.remove(widgetId);
          } else {
            _enabledWidgets.add(widgetId);
          }
        });
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
                    color = const Color(0xFFD1D5DB);
                    icon = Icons.show_chart;
                    break;
                  case 'Altın':
                    color = const Color(0xFFFBBF24);
                    icon = Icons.payments;
                    break;
                  case 'Fon':
                    color = const Color(0xFF60A5FA);
                    icon = Icons.stacked_line_chart;
                    break;
                  default:
                    color = const Color(0xFF34D399);
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
                children: _userAssets.take(6).map((asset) {
                  final value = (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
                  final maxValue = _getHighestAssetValue();
                  final heightPercentage = maxValue > 0
                      ? (value / maxValue)
                      : 0.0;

                  Color color;
                  switch (asset['type'] as String) {
                    case 'Hisse':
                      color = const Color(0xFFD1D5DB);
                      break;
                    case 'Altın':
                      color = const Color(0xFFFBBF24);
                      break;
                    case 'Fon':
                      color = const Color(0xFF60A5FA);
                      break;
                    default:
                      color = const Color(0xFF34D399);
                  }

                  return Expanded(
                    child: Padding(
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
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (asset['name'] as String).length > 5
                                ? '${(asset['name'] as String).substring(0, 5)}...'
                                : asset['name'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.textMainDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withOpacity(0.8),
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.pie_chart, 'Portföy', 0, true),
              _buildNavItem(Icons.candlestick_chart, 'Piyasalar', 1, false),
              _buildNavItem(Icons.smart_toy, 'AI Analiz', 2, false),
              _buildNavItem(Icons.person, 'Profil', 3, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isActive) {
    return InkWell(
      onTap: () {
        // Navigation will be implemented later
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textSecondaryDark,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

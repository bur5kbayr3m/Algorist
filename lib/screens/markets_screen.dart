import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import 'add_asset_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/offline_mode_banner.dart';
import '../widgets/loading_widgets.dart';

class MarketsScreen extends StatefulWidget {
  final String userEmail;

  const MarketsScreen({super.key, required this.userEmail});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  List<MarketItem> _watchlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);

    try {
      // Kullanıcının watchlist'ini yükle (şimdilik default göster)
      _watchlist = _getDefaultMarketItems();
    } catch (e) {
      AppLogger.error('Error loading watchlist', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<MarketItem> _getDefaultMarketItems() {
    return [
      // En çok yatırım yapılan 5 Türk şirketi
      MarketItem(
        symbol: 'THYAO',
        name: 'Türk Hava Yolları',
        category: 'Hisse',
        price: 285.50,
        change: 3.25,
        changePercent: 1.15,
      ),
      MarketItem(
        symbol: 'BIMAS',
        name: 'BIM Mağazaları',
        category: 'Hisse',
        price: 564.00,
        change: -2.50,
        changePercent: -0.44,
      ),
      MarketItem(
        symbol: 'EREGL',
        name: 'Ereğli Demir Çelik',
        category: 'Hisse',
        price: 42.86,
        change: 1.12,
        changePercent: 2.68,
      ),
      MarketItem(
        symbol: 'SAHOL',
        name: 'Sabancı Holding',
        category: 'Hisse',
        price: 78.25,
        change: 0.75,
        changePercent: 0.97,
      ),
      MarketItem(
        symbol: 'AKBNK',
        name: 'Akbank',
        category: 'Hisse',
        price: 56.80,
        change: -0.40,
        changePercent: -0.70,
      ),

      // Döviz kurları
      MarketItem(
        symbol: 'USD/TRY',
        name: 'Amerikan Doları',
        category: 'Döviz',
        price: 34.25,
        change: 0.15,
        changePercent: 0.44,
      ),
      MarketItem(
        symbol: 'EUR/TRY',
        name: 'Euro',
        category: 'Döviz',
        price: 37.45,
        change: 0.22,
        changePercent: 0.59,
      ),

      // Altın
      MarketItem(
        symbol: 'XAU/TRY',
        name: 'Altın (Gram)',
        category: 'Emtia',
        price: 2845.50,
        change: 12.50,
        changePercent: 0.44,
      ),
    ];
  }

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMarketItemSheet(
        onAdd: (item) {
          setState(() {
            _watchlist.add(item);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDarkMode
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
            title: Text(
              'Piyasalar',
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
                onPressed: () {
                  // TODO: Search functionality
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadWatchlist,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BIST 100',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '10,234.56',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+1.24%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.greenAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // İzleme Listesi Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İzleme Listem',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_watchlist.length} varlık',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Market Items
                  ..._watchlist.map(
                    (item) => _buildMarketItemCard(item, isDarkMode),
                  ),
                ],
              ),
            ),
          bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
          floatingActionButton: _buildFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
        const OfflineModeBanner(),
      ],
    );
  }

  Widget _buildMarketItemCard(MarketItem item, bool isDarkMode) {
    final isPositive = item.change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(item.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(item.category),
              color: _getCategoryColor(item.category),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.symbol,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Price and Change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: changeColor,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hisse':
        return Icons.show_chart;
      case 'Döviz':
        return Icons.attach_money;
      case 'Emtia':
        return Icons.diamond;
      case 'Fon':
        return Icons.account_balance;
      default:
        return Icons.trending_up;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hisse':
        return Colors.blue;
      case 'Döviz':
        return Colors.green;
      case 'Emtia':
        return Colors.amber;
      case 'Fon':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class MarketItem {
  final String symbol;
  final String name;
  final String category;
  final double price;
  final double change;
  final double changePercent;

  MarketItem({
    required this.symbol,
    required this.name,
    required this.category,
    required this.price,
    required this.change,
    required this.changePercent,
  });
}

class AddMarketItemSheet extends StatefulWidget {
  final Function(MarketItem) onAdd;

  const AddMarketItemSheet({super.key, required this.onAdd});

  @override
  State<AddMarketItemSheet> createState() => _AddMarketItemSheetState();
}

class _AddMarketItemSheetState extends State<AddMarketItemSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MarketItem> _getBist100Stocks() {
    return [
      MarketItem(
        symbol: 'ASELS',
        name: 'Aselsan',
        category: 'Hisse',
        price: 123.45,
        change: 2.5,
        changePercent: 2.07,
      ),
      MarketItem(
        symbol: 'TUPRS',
        name: 'Tüpraş',
        category: 'Hisse',
        price: 234.50,
        change: -1.2,
        changePercent: -0.51,
      ),
      MarketItem(
        symbol: 'KCHOL',
        name: 'Koç Holding',
        category: 'Hisse',
        price: 156.75,
        change: 3.25,
        changePercent: 2.12,
      ),
      MarketItem(
        symbol: 'GARAN',
        name: 'Garanti Bankası',
        category: 'Hisse',
        price: 89.60,
        change: 0.85,
        changePercent: 0.96,
      ),
      MarketItem(
        symbol: 'ISCTR',
        name: 'İş Bankası (C)',
        category: 'Hisse',
        price: 12.34,
        change: -0.15,
        changePercent: -1.20,
      ),
      MarketItem(
        symbol: 'SISE',
        name: 'Şişe Cam',
        category: 'Hisse',
        price: 67.80,
        change: 1.50,
        changePercent: 2.26,
      ),
      MarketItem(
        symbol: 'PETKM',
        name: 'Petkim',
        category: 'Hisse',
        price: 45.20,
        change: 0.90,
        changePercent: 2.03,
      ),
      MarketItem(
        symbol: 'VAKBN',
        name: 'Vakıfbank',
        category: 'Hisse',
        price: 34.56,
        change: -0.44,
        changePercent: -1.26,
      ),
      MarketItem(
        symbol: 'ENKAI',
        name: 'Enka İnşaat',
        category: 'Hisse',
        price: 78.90,
        change: 2.10,
        changePercent: 2.73,
      ),
      MarketItem(
        symbol: 'TCELL',
        name: 'Turkcell',
        category: 'Hisse',
        price: 98.50,
        change: 1.75,
        changePercent: 1.81,
      ),
    ];
  }

  List<MarketItem> _getTefasFunds() {
    return [
      MarketItem(
        symbol: 'GAH',
        name: 'Garanti Portföy Altın',
        category: 'Fon',
        price: 0.123456,
        change: 0.001,
        changePercent: 0.82,
      ),
      MarketItem(
        symbol: 'TBH',
        name: 'Tacirler Portföy B Tipi',
        category: 'Fon',
        price: 0.089234,
        change: -0.002,
        changePercent: -2.19,
      ),
      MarketItem(
        symbol: 'IPH',
        name: 'İş Portföy Hisse',
        category: 'Fon',
        price: 0.156789,
        change: 0.003,
        changePercent: 1.95,
      ),
      MarketItem(
        symbol: 'YAH',
        name: 'Yapı Kredi Portföy Altın',
        category: 'Fon',
        price: 0.134567,
        change: 0.0015,
        changePercent: 1.13,
      ),
      MarketItem(
        symbol: 'AKH',
        name: 'Akbank Portföy Hisse',
        category: 'Fon',
        price: 0.098765,
        change: -0.001,
        changePercent: -1.00,
      ),
    ];
  }

  List<MarketItem> _getBonds() {
    return [
      MarketItem(
        symbol: 'TR230126T21',
        name: 'Devlet Tahvili',
        category: 'Tahvil',
        price: 98.75,
        change: 0.25,
        changePercent: 0.25,
      ),
      MarketItem(
        symbol: 'TR240612T19',
        name: 'Hazine Bonosu',
        category: 'Tahvil',
        price: 102.30,
        change: -0.15,
        changePercent: -0.15,
      ),
      MarketItem(
        symbol: 'THYAO.E',
        name: 'THY Eurobond',
        category: 'Tahvil',
        price: 95.80,
        change: 0.50,
        changePercent: 0.52,
      ),
    ];
  }

  List<MarketItem> _getFilteredItems(List<MarketItem> items) {
    if (_searchQuery.isEmpty) return items;

    return items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.symbol.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Varlık Ekle',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDarkMode
                ? Colors.white.withOpacity(0.6)
                : AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'BIST 100'),
              Tab(text: 'TEFAS'),
              Tab(text: 'Tahvil'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(
                  _getFilteredItems(_getBist100Stocks()),
                  isDarkMode,
                ),
                _buildItemsList(
                  _getFilteredItems(_getTefasFunds()),
                  isDarkMode,
                ),
                _buildItemsList(_getFilteredItems(_getBonds()), isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<MarketItem> items, bool isDarkMode) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.6)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isPositive = item.change >= 0;
        final changeColor = isPositive ? Colors.green : Colors.red;

        return InkWell(
          onTap: () {
            widget.onAdd(item);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.symbol} izleme listesine eklendi'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.symbol,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${item.price.toStringAsFixed(item.category == 'Fon' ? 6 : 2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: changeColor,
                          size: 12,
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

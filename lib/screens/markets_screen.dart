import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/offline_mode_banner.dart';
import '../widgets/success_dialog.dart';
import '../services/yahoo_finance_service.dart';
import 'market_asset_detail_screen.dart';

class MarketsScreen extends StatefulWidget {
  final String userEmail;

  const MarketsScreen({super.key, required this.userEmail});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  List<MarketItem> _watchlist = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
    // Her 30 saniyede bir otomatik güncelle
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadWatchlist();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);

    try {
      // Yahoo Finance'den gerçek veri çek - sadece 3 hisse
      final symbols = YahooFinanceService.getBist100Symbols().take(3).toList();
      final quotes = await YahooFinanceService.instance.getMultipleQuotes(symbols);
      
      _watchlist = quotes.map((quote) {
        return MarketItem(
          symbol: quote['symbol'].toString().replaceAll('.IS', ''),
          name: _getCompanyName(quote['symbol'].toString()),
          category: 'Hisse',
          price: quote['price']?.toDouble() ?? 0.0,
          change: quote['change']?.toDouble() ?? 0.0,
          changePercent: quote['changePercent']?.toDouble() ?? 0.0,
        );
      }).toList();
      
      _lastUpdate = DateTime.now();
    } catch (e) {
      AppLogger.error('Error loading watchlist', e);
      _watchlist = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  String _getCompanyName(String symbol) {
    final Map<String, String> names = {
      'THYAO.IS': 'Türk Hava Yolları',
      'BIMAS.IS': 'BIM Mağazaları',
      'EREGL.IS': 'Ereğli Demir Çelik',
      'SAHOL.IS': 'Sabancı Holding',
      'AKBNK.IS': 'Akbank',
    };
    return names[symbol] ?? symbol;
  }

  String _formatLastUpdate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return 'Az önce';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce';
    } else {
      return '${diff.inHours} saat önce';
    }
  }

  List<MarketItem> _getDefaultMarketItems() {
    // TODO: Gerçek API verisi eklenecek
    return [];
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
                      // İzleme Listesi Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (_lastUpdate != null)
                            Text(
                              'Son güncelleme: ${_formatLastUpdate(_lastUpdate!)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.4)
                                    : AppColors.textSecondary.withOpacity(0.6),
                              ),
                            ),
                        ],
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketAssetDetailScreen(
              marketItem: item,
              userEmail: widget.userEmail,
            ),
          ),
        );
      },
      child: Container(
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
  bool _isLoading = true;
  List<MarketItem> _bist100Stocks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBist100Stocks();
  }

  Future<void> _loadBist100Stocks() async {
    setState(() => _isLoading = true);

    try {
      // Yahoo Finance'den BIST 100 hisselerini çek - ilk 3 hariç kalan 17 hisse
      final symbols = YahooFinanceService.getBist100Symbols().skip(3).toList();
      final quotes = await YahooFinanceService.instance.getMultipleQuotes(symbols);
      
      _bist100Stocks = quotes.map((quote) {
        return MarketItem(
          symbol: quote['symbol'].toString().replaceAll('.IS', ''),
          name: _getCompanyName(quote['symbol'].toString()),
          category: 'Hisse',
          price: quote['price']?.toDouble() ?? 0.0,
          change: quote['change']?.toDouble() ?? 0.0,
          changePercent: quote['changePercent']?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      _bist100Stocks = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCompanyName(String symbol) {
    final Map<String, String> names = {
      'THYAO.IS': 'Türk Hava Yolları',
      'BIMAS.IS': 'BIM Mağazaları',
      'EREGL.IS': 'Ereğli Demir Çelik',
      'SAHOL.IS': 'Sabancı Holding',
      'AKBNK.IS': 'Akbank',
    };
    return names[symbol] ?? symbol;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MarketItem> _getBist100Stocks() {
    return _bist100Stocks;
  }

  List<MarketItem> _getTefasFunds() {
    // TODO: Gerçek TEFAS API verisi eklenecek
    return [];
  }

  List<MarketItem> _getBonds() {
    // TODO: Gerçek tahvil API verisi eklenecek
    return [];
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
            SuccessDialog.show(
              context,
              title: 'Başarılı',
              message: '${item.symbol} izleme listesine eklendi',
              onDismiss: () {
                // İzleme listesine ekleme tamamlandı
              },
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

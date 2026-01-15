import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../services/news_service.dart';
import '../services/yahoo_finance_service.dart';
import 'markets_screen.dart';

class MarketAssetDetailScreen extends StatefulWidget {
  final MarketItem marketItem;
  final String userEmail;

  const MarketAssetDetailScreen({
    super.key,
    required this.marketItem,
    required this.userEmail,
  });

  @override
  State<MarketAssetDetailScreen> createState() =>
      _MarketAssetDetailScreenState();
}

enum ChartPeriod { day, week, month, threeMonths, year, all }

enum ChartType { line, candlestick, area, bar }

class _MarketAssetDetailScreenState extends State<MarketAssetDetailScreen>
    with SingleTickerProviderStateMixin {
  ChartPeriod _selectedPeriod = ChartPeriod.day;
  ChartType _selectedChartType = ChartType.line;
  bool _isLoadingNews = true;
  bool _isLoadingChart = true;
  List<KapNews> _kapNews = [];
  List<NewsItem> _generalNews = [];
  List<Map<String, dynamic>> _chartData = [];
  late TabController _tabController;

  // Grafik zoom ve pan değişkenleri
  double _minX = 0;
  double _maxX = 50;
  double _viewportWidth = 50;
  double _zoomLevel = 1.0;
  final double _maxZoomLevel = 4.0;
  final double _minZoomLevel = 0.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNews();
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleZoom(double delta) {
    setState(() {
      _zoomLevel = (_zoomLevel + delta).clamp(_minZoomLevel, _maxZoomLevel);
      _viewportWidth = (_chartData.length / _zoomLevel).clamp(10, _chartData.length.toDouble());
      _maxX = (_minX + _viewportWidth).clamp(_viewportWidth, _chartData.length.toDouble());
    });
  }

  void _handlePan(double delta) {
    setState(() {
      _minX = (_minX + delta).clamp(0, _chartData.length - _viewportWidth);
      _maxX = _minX + _viewportWidth;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _minX = 0;
      _maxX = _chartData.length.toDouble();
      _viewportWidth = _chartData.length.toDouble();
    });
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);

    try {
      // Gerçek haber servisinden veri çek
      final newsService = NewsService.instance;

      final generalNews = await newsService.getStockNews(
        widget.marketItem.symbol,
        widget.marketItem.name,
      );

      final kapNews = newsService.getKapNews(
        widget.marketItem.symbol,
        widget.marketItem.name,
      );

      if (mounted) {
        setState(() {
          _generalNews = generalNews;
          _kapNews = kapNews;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoadingChart = true);

    try {
      // Yahoo Finance'den tarihsel veri çek
      String range = '1d';
      String interval = '5m';

      switch (_selectedPeriod) {
        case ChartPeriod.day:
          range = '1d';
          interval = '5m';
          break;
        case ChartPeriod.week:
          range = '5d';
          interval = '15m';
          break;
        case ChartPeriod.month:
          range = '1mo';
          interval = '1h';
          break;
        case ChartPeriod.threeMonths:
          range = '3mo';
          interval = '1d';
          break;
        case ChartPeriod.year:
          range = '1y';
          interval = '1wk';
          break;
        case ChartPeriod.all:
          range = '5y';
          interval = '1mo';
          break;
      }

      final symbol = '${widget.marketItem.symbol}.IS';
      final data = await YahooFinanceService.instance.getHistoricalData(
        symbol,
        interval: interval,
        range: range,
      );

      if (mounted && data != null) {
        setState(() {
          _chartData = data['data'] as List<Map<String, dynamic>>;
          _isLoadingChart = false;
        });
      } else if (mounted) {
        setState(() {
          _chartData = [];
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartData = [];
          _isLoadingChart = false;
        });
      }
    }
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
      // Farklı modları dene
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        // Alternatif olarak platformDefault dene
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

  @override
  Widget build(BuildContext context) {
    final item = widget.marketItem;
    final isPositive = item.change >= 0;
    final changeColor = isPositive
        ? AppColors.positiveDark
        : AppColors.negativeDark;

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
          item.symbol,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.symbol} favorilere eklendi'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textMainDark),
            onPressed: () {
              // Share functionality
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
              _buildPriceSection(item, changeColor, isPositive),

              // Grafik
              _buildChartSection(),

              // Detay Bilgileri
              _buildDetailsSection(item),

              // Tab Bar for News
              _buildNewsTabSection(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // Piyasalar ekranında işlem butonu yok - sadece izleme modu
    );
  }

  Widget _buildPriceSection(
    MarketItem item,
    Color changeColor,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
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
                '₺${item.price.toStringAsFixed(item.category == 'Fon' ? 6 : 2)}',
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
                  color: changeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: changeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Değişim: ${isPositive ? '+' : ''}₺${item.change.toStringAsFixed(2)}',
            style: GoogleFonts.manrope(fontSize: 14, color: changeColor),
          ),
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
          // Grafik türü seçici
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ChartType.values.map((type) {
              final isSelected = _selectedChartType == type;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedChartType = type),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderDark,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getChartTypeIcon(type),
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Periyot seçici
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ChartPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return InkWell(
                onTap: () {
                  setState(() => _selectedPeriod = period);
                  _loadChartData();
                },
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

          // Grafik ipuçları
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'İpucu: İki parmakla yakınlaştırma yapabilir, sürükleyerek grafikte gezinebilirsiniz',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textMainDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gerçek Grafik
          SizedBox(
            height: 200,
            child: _isLoadingChart
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _chartData.isEmpty
                ? Center(
                    child: Text(
                      'Grafik verisi yüklenemedi',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  )
                : RepaintBoundary(
                    // OPTIMIZATION: Grafik çizimi maliyetlidir. Veri değişmediği sürece
                    // tekrar boyanmasını (repaint) engellemek için RepaintBoundary kullanıyoruz.
                    child: _buildChartByType(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartByType() {
    switch (_selectedChartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.candlestick:
        return _buildCandlestickChart();
      case ChartType.area:
        return _buildAreaChart();
      case ChartType.bar:
        return _buildBarChart();
    }
  }

  Widget _buildLineChart() {
    if (_chartData.isEmpty) return const SizedBox();
    
    // İlk yüklemede viewport ayarla
    if (_maxX == 50 && _chartData.length > 50) {
      _maxX = _chartData.length.toDouble();
      _viewportWidth = _chartData.length.toDouble();
    }

    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: _resetZoom,
          onHorizontalDragUpdate: (details) {
            // Sağa-sola kaydırma (pan)
            final delta = -details.primaryDelta! / 5;
            _handlePan(delta);
          },
          onScaleUpdate: (details) {
            // Pinch zoom
            if (details.scale != 1.0) {
              final zoomDelta = (details.scale - 1.0) * 0.5;
              _handleZoom(zoomDelta);
            }
          },
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      if (spot.x.toInt() >= 0 && spot.x.toInt() < _chartData.length) {
                        final date = _chartData[spot.x.toInt()]['date'] as DateTime;
                        return LineTooltipItem(
                          '${DateFormat('HH:mm').format(date)}\n₺${spot.y.toStringAsFixed(2)}',
                          GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.borderDark.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _chartData.length / 4,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < _chartData.length) {
                        final date =
                            _chartData[value.toInt()]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('HH:mm').format(date),
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: AppColors.textSecondaryDark,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: _minX,
              maxX: _maxX,
              minY:
                  _chartData
                      .map((e) => e['close'] as double)
                      .reduce((a, b) => a < b ? a : b) *
                  0.995,
              maxY:
                  _chartData
                      .map((e) => e['close'] as double)
                      .reduce((a, b) => a > b ? a : b) *
                  1.005,
              lineBarsData: [
                LineChartBarData(
                  spots: _chartData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value['close'] as double,
                    );
                  }).toList(),
                  isCurved: true,
                  color: widget.marketItem.change >= 0
                      ? Colors.green
                      : Colors.red,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        // Zoom kontrolü ve reset butonu
        if (_zoomLevel != 1.0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_zoomLevel.toStringAsFixed(1)}x',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textMainDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _resetZoom,
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAreaChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = _chartData[spot.x.toInt()]['date'] as DateTime;
                return LineTooltipItem(
                  '${DateFormat('HH:mm').format(date)}\n₺${spot.y.toStringAsFixed(2)}',
                  GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.borderDark.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _chartData.length / 4,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                  final date = _chartData[value.toInt()]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textSecondaryDark,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: _chartData.map((e) => e['close'] as double).reduce((a, b) => a < b ? a : b) * 0.995,
        maxY: _chartData.map((e) => e['close'] as double).reduce((a, b) => a > b ? a : b) * 1.005,
        lineBarsData: [
          LineChartBarData(
            spots: _chartData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['close'] as double,
              );
            }).toList(),
            isCurved: true,
            color: widget.marketItem.change >= 0 ? Colors.green : Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (widget.marketItem.change >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlestickChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < _chartData.length) {
                final data = _chartData[groupIndex];
                final date = data['date'] as DateTime;
                final open = data['open'] as double;
                final close = data['close'] as double;
                final high = data['high'] as double;
                final low = data['low'] as double;
                return BarTooltipItem(
                  '${DateFormat('HH:mm').format(date)}\n'
                  'A: ₺${open.toStringAsFixed(2)}\n'
                  'K: ₺${close.toStringAsFixed(2)}\n'
                  'Y: ₺${high.toStringAsFixed(2)}\n'
                  'D: ₺${low.toStringAsFixed(2)}',
                  GoogleFonts.manrope(color: Colors.white, fontSize: 11),
                );
              }
              return null;
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.borderDark.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _chartData.length / 4,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                  final date = _chartData[value.toInt()]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textSecondaryDark,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _chartData.asMap().entries.map((entry) {
          final data = entry.value;
          final open = data['open'] as double;
          final close = data['close'] as double;
          final high = data['high'] as double;
          final low = data['low'] as double;
          final isPositive = close >= open;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                fromY: low,
                toY: high,
                color: isPositive ? Colors.green : Colors.red,
                width: 1,
              ),
              BarChartRodData(
                fromY: open < close ? open : close,
                toY: open < close ? close : open,
                color: isPositive ? Colors.green : Colors.red,
                width: 8,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < _chartData.length) {
                final data = _chartData[groupIndex];
                final date = data['date'] as DateTime;
                final volume = data['volume'] as int;
                return BarTooltipItem(
                  '${DateFormat('HH:mm').format(date)}\n'
                  'Hacim: ${NumberFormat.compact().format(volume)}',
                  GoogleFonts.manrope(color: Colors.white, fontSize: 11),
                );
              }
              return null;
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.borderDark.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _chartData.length / 4,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                  final date = _chartData[value.toInt()]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textSecondaryDark,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _chartData.asMap().entries.map((entry) {
          final data = entry.value;
          final close = data['close'] as double;
          final open = data['open'] as double;
          final isPositive = close >= open;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: close,
                color: isPositive ? Colors.green : Colors.red,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsSection(MarketItem item) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detaylar',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showAllDetailsDialog(context, item);
                },
                child: Text(
                  'Tümü',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Kategori', item.category),
          _buildDetailRow('Sembol', item.symbol),
          _buildDetailRow(
            'Günlük Değişim',
            '${item.change >= 0 ? '+' : ''}₺${item.change.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Yüzdesel Değişim',
            '${item.changePercent >= 0 ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
              fontWeight: FontWeight.w600,
              color: AppColors.textMainDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Haberler',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              TextButton(
                onPressed: () => _showAllNewsDialog(context),
                child: Text(
                  'Tümü',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderDark.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondaryDark,
              labelStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Genel'),
                    ],
                  ),
                ),
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('KAP'),
                    ],
                  ),
                ),
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Analiz'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          SizedBox(
            height: 300,
            child: _isLoadingNews
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralNewsList(),
                      _buildKapNewsList(),
                      _buildAnalysisNewsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralNewsList() {
    if (_generalNews.isEmpty) {
      return _buildEmptyNewsState();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _generalNews.length,
      itemBuilder: (context, index) {
        final news = _generalNews[index];
        return _buildNewsCard(
          title: news.title,
          source: news.source,
          date: news.publishedAt,
          url: news.url,
          imageUrl: news.imageUrl,
        );
      },
    );
  }

  Widget _buildKapNewsList() {
    if (_kapNews.isEmpty) {
      return _buildEmptyNewsState();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _kapNews.length,
      itemBuilder: (context, index) {
        final news = _kapNews[index];
        return _buildKapNewsCard(news);
      },
    );
  }

  Widget _buildAnalysisNewsList() {
    final analysisNews = _generalNews
        .where((n) => n.category == 'Analiz')
        .toList();

    if (analysisNews.isEmpty) {
      // Mock analiz haberleri
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildNewsCard(
            title: '${widget.marketItem.name} Teknik Analizi',
            source: 'Algorist AI',
            date: DateTime.now(),
            url: '',
            imageUrl: null,
          ),
          _buildNewsCard(
            title: 'Uzman Görüşleri: ${widget.marketItem.symbol}',
            source: 'Algorist',
            date: DateTime.now().subtract(const Duration(hours: 2)),
            url: '',
            imageUrl: null,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: analysisNews.length,
      itemBuilder: (context, index) {
        final news = analysisNews[index];
        return _buildNewsCard(
          title: news.title,
          source: news.source,
          date: news.publishedAt,
          url: news.url,
          imageUrl: news.imageUrl,
        );
      },
    );
  }

  Widget _buildEmptyNewsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper,
            size: 48,
            color: AppColors.textSecondaryDark.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz haber bulunamadı',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String source,
    required DateTime date,
    required String url,
    String? imageUrl,
  }) {
    final hasUrl = url.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceDark,
                AppColors.surfaceDark.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUrl
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.borderDark,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source & Date Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getSourceIcon(source),
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          source,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: AppColors.textSecondaryDark.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
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

              const SizedBox(height: 12),

              // Footer with action
              Row(
                children: [
                  if (hasUrl) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Haberi Oku',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate700.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Özet',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    final lowerSource = source.toLowerCase();
    if (lowerSource.contains('bloomberg')) return Icons.show_chart;
    if (lowerSource.contains('investing')) return Icons.trending_up;
    if (lowerSource.contains('cnbc')) return Icons.tv;
    if (lowerSource.contains('reuters')) return Icons.public;
    if (lowerSource.contains('algorist')) return Icons.auto_awesome;
    return Icons.newspaper;
  }

  Widget _buildKapNewsCard(KapNews news) {
    final importanceColor = news.importance == KapImportance.high
        ? const Color(0xFFEF4444)
        : news.importance == KapImportance.medium
        ? const Color(0xFFF59E0B)
        : const Color(0xFF6B7280);

    final importanceLabel = news.importance == KapImportance.high
        ? 'Önemli'
        : news.importance == KapImportance.medium
        ? 'Orta'
        : 'Bilgi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(news.url),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [importanceColor.withOpacity(0.1), AppColors.surfaceDark],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: importanceColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: importanceColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Importance Indicator
              Container(
                width: 5,
                height: 100,
                decoration: BoxDecoration(
                  color: importanceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // KAP Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'KAP',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              news.type,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Importance Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: importanceColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  news.importance == KapImportance.high
                                      ? Icons.priority_high
                                      : Icons.info_outline,
                                  size: 12,
                                  color: importanceColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  importanceLabel,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: importanceColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        news.title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMainDark,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Footer
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.textSecondaryDark.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(news.date),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'KAP\'ta Görüntüle',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr').format(date);
    }
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
        return 'Bar';
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

  void _showTradeDialog(BuildContext context, MarketItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TradeBottomSheet(item: item, userEmail: widget.userEmail),
    );
  }

  void _showAllDetailsDialog(BuildContext context, MarketItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    '${item.symbol} Detayları',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailRow('Şirket Adı', item.name),
                    _buildDetailRow('Sembol', item.symbol),
                    _buildDetailRow('Kategori', item.category),
                    _buildDetailRow(
                      'Fiyat',
                      '₺${item.price.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Günlük Değişim',
                      '₺${item.change.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Yüzdesel Değişim',
                      '${item.changePercent.toStringAsFixed(2)}%',
                    ),
                    const Divider(color: AppColors.borderDark, height: 32),
                    _buildDetailRow('Piyasa Değeri', 'Hesaplanıyor...'),
                    _buildDetailRow('Hacim', 'API Entegrasyonu Gerekli'),
                    _buildDetailRow(
                      '52H En Yüksek',
                      'API Entegrasyonu Gerekli',
                    ),
                    _buildDetailRow('52H En Düşük', 'API Entegrasyonu Gerekli'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllNewsDialog(BuildContext context) {
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _generalNews.length + _kapNews.length,
                itemBuilder: (context, index) {
                  if (index < _generalNews.length) {
                    final news = _generalNews[index];
                    return _buildNewsCard(
                      title: news.title,
                      source: news.source,
                      date: news.publishedAt,
                      url: news.url,
                      imageUrl: news.imageUrl,
                    );
                  } else {
                    final kapIndex = index - _generalNews.length;
                    final news = _kapNews[kapIndex];
                    return _buildKapNewsCard(news);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeBottomSheet extends StatefulWidget {
  final MarketItem item;
  final String userEmail;

  const _TradeBottomSheet({required this.item, required this.userEmail});

  @override
  State<_TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<_TradeBottomSheet> {
  bool _isBuying = true;
  final _quantityController = TextEditingController(text: '1');
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _totalCost = quantity * widget.item.price;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                '${widget.item.symbol} İşlem',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Güncel Fiyat: ₺${widget.item.price.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Al/Sat Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBuying = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isBuying
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'AL',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isBuying
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isBuying = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isBuying ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'SAT',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: !_isBuying
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Miktar
              Text(
                'Miktar',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
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
                ),
              ),
              const SizedBox(height: 24),

              // Toplam
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toplam Tutar',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '₺${_totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // İşlem Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_isBuying ? 'Alım' : 'Satım'} emri oluşturuldu: ${_quantityController.text} adet ${widget.item.symbol}',
                        ),
                        backgroundColor: _isBuying ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBuying ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isBuying ? 'AL' : 'SAT',
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

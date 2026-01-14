import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/error_dialog.dart';
import '../widgets/success_dialog.dart';

class EditPortfolioScreen extends StatefulWidget {
  const EditPortfolioScreen({super.key});

  @override
  State<EditPortfolioScreen> createState() => _EditPortfolioScreenState();
}

class _EditPortfolioScreenState extends State<EditPortfolioScreen> {
  List<Map<String, dynamic>> _userAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAssets();
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

  Future<void> _deleteAsset(String assetId, String assetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Text(
          'Varlığı Sil',
          style: GoogleFonts.manrope(
            color: AppColors.textMainDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          '$assetName varlığını silmek istediğinizden emin misiniz?',
          style: GoogleFonts.manrope(
            color: AppColors.textSecondaryDark,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'İptal',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negativeDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sil',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PortfolioService.instance.deleteAsset(assetId);
        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'Başarılı',
            message: 'Varlık başarıyla silindi',
            onDismiss: () {
              // Varlık silme tamamlandı
            },
          );
          await _loadUserAssets();
        }
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(
            context,
            title: 'Hata',
            message: 'Varlık silinirken hata oluştu: $e',
          );
        }
      }
    }
  }

  Future<void> _editAssetQuantity(Map<String, dynamic> asset) async {
    final quantityController = TextEditingController(
      text: (asset['quantity'] as num).toString(),
    );

    final newQuantity = await showDialog<double>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Text(
          'Miktar Düzenle',
          style: GoogleFonts.manrope(
            color: AppColors.textMainDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset['name'] as String,
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'Yeni Miktar',
                labelStyle: GoogleFonts.manrope(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderDark.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'İptal',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(quantityController.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Kaydet',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );

    if (newQuantity != null) {
      try {
        final purchasePrice = (asset['purchasePrice'] as num).toDouble();
        final updatedAsset = {
          'quantity': newQuantity,
          'totalCost': newQuantity * purchasePrice,
        };

        await PortfolioService.instance.updateAsset(
          asset['assetId'] as String,
          updatedAsset,
        );

        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'Başarılı',
            message: 'Miktar başarıyla güncellendi',
            onDismiss: () {
              // Miktar güncelleme tamamlandı
            },
          );
          await _loadUserAssets();
        }
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(
            context,
            title: 'Hata',
            message: 'Miktar güncellenirken hata oluştu: $e',
          );
        }
      }
    }
  }

  Future<void> _sellAsset(Map<String, dynamic> asset) async {
    final name = asset['name'] as String;
    final quantity = (asset['quantity'] as num).toDouble();
    final purchasePrice = (asset['purchasePrice'] as num).toDouble();

    final sellQuantityController = TextEditingController();
    final sellPriceController = TextEditingController();

    final result = await showDialog<Map<String, double>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Text(
          'Varlık Sat',
          style: GoogleFonts.manrope(
            color: AppColors.textMainDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mevcut: ${quantity.toStringAsFixed(2)} adet',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            Text(
              'Alış Fiyatı: ₺${purchasePrice.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: sellQuantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'Satış Miktarı',
                labelStyle: GoogleFonts.manrope(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderDark.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sellPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'Satış Fiyatı (₺)',
                labelStyle: GoogleFonts.manrope(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderDark.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'İptal',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final sellQty = double.tryParse(sellQuantityController.text);
              final sellPrice = double.tryParse(sellPriceController.text);

              if (sellQty != null &&
                  sellPrice != null &&
                  sellQty > 0 &&
                  sellQty <= quantity &&
                  sellPrice > 0) {
                Navigator.pop(context, {
                  'quantity': sellQty,
                  'price': sellPrice,
                });
              } else {
                ErrorDialog.show(
                  context,
                  title: 'Hata',
                  message: 'Geçersiz miktar veya fiyat',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sat',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final sellQty = result['quantity']!;
        final sellPrice = result['price']!;
        final remainingQty = quantity - sellQty;

        // Kar/Zarar hesaplama
        final buyTotal = sellQty * purchasePrice;
        final sellTotal = sellQty * sellPrice;
        final profitLoss = sellTotal - buyTotal;
        final profitLossPercent = (profitLoss / buyTotal) * 100;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userEmail = authProvider.currentUserEmail;

        if (userEmail != null) {
          // Kar/Zarar bilgisini isimde sakla (JSON formatında)
          final profitInfo =
              '{profitLoss:$profitLoss,profitLossPercent:$profitLossPercent}';

          // Nakit olarak ekle
          final cashAsset = {
            'userEmail': userEmail,
            'assetId': 'cash_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'Nakit',
            'name': 'Satış: $name|$profitInfo',
            'quantity': 1.0,
            'purchasePrice': sellTotal,
            'purchaseDate': DateTime.now().toIso8601String(),
            'totalCost': sellTotal,
            'addedAt': DateTime.now().toIso8601String(),
            'userId': 0,
          };

          await PortfolioService.instance.addAsset(userEmail, cashAsset);

          // Varlığı güncelle veya sil
          if (remainingQty > 0) {
            final updatedAsset = {
              'quantity': remainingQty,
              'totalCost': remainingQty * purchasePrice,
            };
            await PortfolioService.instance.updateAsset(
              asset['assetId'] as String,
              updatedAsset,
            );
          } else {
            await PortfolioService.instance.deleteAsset(
              asset['assetId'] as String,
            );
          }

          if (mounted) {
            final profitLossText = profitLoss >= 0
                ? '+₺${profitLoss.toStringAsFixed(2)} (${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)'
                : '-₺${profitLoss.abs().toStringAsFixed(2)} (${profitLossPercent.toStringAsFixed(2)}%)';

            SuccessDialog.show(
              context,
              title: 'Başarılı',
              message: 'Satış tamamlandı: $profitLossText',
              onDismiss: () {
                // Satış tamamlandı
              },
            );
            await _loadUserAssets();
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorDialog.show(
            context,
            title: 'Hata',
            message: 'Satış sırasında hata oluştu: $e',
          );
        }
      }
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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Portföyü Düzenle',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _userAssets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _userAssets.length,
              itemBuilder: (context, index) {
                return _buildAssetCard(_userAssets[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Portföyünüz Boş',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMainDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Düzenlenecek varlık bulunmuyor.\nVarlık ekleyerek başlayın.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(Map<String, dynamic> asset) {
    final nameRaw = asset['name'] as String;
    final type = asset['type'] as String;
    final quantity = (asset['quantity'] as num).toDouble();
    final purchasePrice = (asset['purchasePrice'] as num).toDouble();
    final totalCost = (asset['totalCost'] as num).toDouble();

    // Kar/Zarar bilgisini parse et
    String name = nameRaw;
    double? profitLoss;
    double? profitLossPercent;

    if (type == 'Nakit' && nameRaw.contains('|')) {
      final parts = nameRaw.split('|');
      name = parts[0];
      if (parts.length > 1) {
        final profitInfo = parts[1];
        // {profitLoss:123.45,profitLossPercent:12.34} formatını parse et
        final profitLossMatch = RegExp(
          r'profitLoss:([-\d.]+)',
        ).firstMatch(profitInfo);
        final profitLossPercentMatch = RegExp(
          r'profitLossPercent:([-\d.]+)',
        ).firstMatch(profitInfo);

        if (profitLossMatch != null) {
          profitLoss = double.tryParse(profitLossMatch.group(1)!);
        }
        if (profitLossPercentMatch != null) {
          profitLossPercent = double.tryParse(profitLossPercentMatch.group(1)!);
        }
      }
    }

    final isCash = type == 'Nakit';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'Hisse':
        icon = Icons.show_chart;
        iconColor = const Color(0xFF3B82F6);
      case 'Altın':
        icon = Icons.monetization_on;
        iconColor = const Color(0xFFEAB308);
      case 'Kripto':
        icon = Icons.currency_bitcoin;
        iconColor = const Color(0xFFF97316);
      case 'Döviz':
        icon = Icons.attach_money;
        iconColor = const Color(0xFF10B981);
      case 'Nakit':
        icon = Icons.account_balance_wallet;
        iconColor = const Color(0xFF10B981);
      default:
        icon = Icons.account_balance_wallet;
        iconColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMainDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grayBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isCash && profitLoss != null && profitLossPercent != null
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Satış Tutarı',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₺${totalCost.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMainDark,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Kar/Zarar',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${profitLoss >= 0 ? '+' : ''}₺${profitLoss.toStringAsFixed(2)}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: profitLoss >= 0
                                          ? AppColors.positiveDark
                                          : AppColors.negativeDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (profitLossPercent >= 0
                                                  ? AppColors.positiveDark
                                                  : AppColors.negativeDark)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${profitLossPercent >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: profitLossPercent >= 0
                                            ? AppColors.positiveDark
                                            : AppColors.negativeDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Miktar',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${quantity.toStringAsFixed(2)} adet',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMainDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birim Fiyat',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₺${purchasePrice.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMainDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          if (!isCash) const SizedBox(height: 12),
          if (!isCash)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAssetQuantity(asset),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Düzenle',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sellAsset(asset),
                    icon: const Icon(Icons.trending_down, size: 18),
                    label: Text(
                      'Sat',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF97316),
                      side: const BorderSide(color: Color(0xFFF97316)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _deleteAsset(asset['assetId'] as String, name),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      'Sil',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.negativeDark,
                      side: const BorderSide(color: AppColors.negativeDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          if (isCash) const SizedBox(height: 12),
          if (isCash)
            OutlinedButton.icon(
              onPressed: () => _deleteAsset(asset['assetId'] as String, name),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                'Nakti Portföyden Çıkar',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.negativeDark,
                side: const BorderSide(color: AppColors.negativeDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

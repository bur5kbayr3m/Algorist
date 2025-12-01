import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../services/email_verification_service.dart';
import '../theme/app_colors.dart';
import 'email_verification_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _loadTransactions();
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUserEmail;
    if (email != null) {
      final isVerified = await EmailVerificationService.instance
          .isEmailVerified(email);
      if (mounted) {
        setState(() {
          _isEmailVerified = isVerified;
        });
        if (!isVerified) {
          _showVerificationWarning();
        }
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
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4F46E5).withOpacity(0.2),
                          const Color(0xFF7C3AED).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFF818CF8),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
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
                  // Content
                  Text(
                    'İşlem geçmişini görüntülemek için email adresinizi doğrulamanız gerekmektedir.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Primary Button - Şimdi Doğrula
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final email = authProvider.currentUserEmail;
                        if (email != null) {
                          final success = await EmailVerificationService
                              .instance
                              .sendVerificationCode(email);
                          if (success && mounted) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmailVerificationScreen(email: email),
                              ),
                            );
                            if (result == true) {
                              _checkEmailVerification();
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Şimdi Doğrula',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Secondary Button - Geri Dön
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, 'openDrawer');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'Geri Dön',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF94A3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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

  Future<void> _loadTransactions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUserEmail;

    if (userEmail != null) {
      final assets = await PortfolioService.instance.getUserAssets(userEmail);

      // Her varlığı bir işlem olarak göster (ekleme işlemi)
      final transactions = assets.map((asset) {
        // Kar/Zarar bilgisini temizle
        final nameRaw = asset['name'] as String;
        final cleanName = nameRaw.contains('|')
            ? nameRaw.split('|')[0]
            : nameRaw;

        return {
          'id': asset['assetId'],
          'type': 'buy', // buy veya sell
          'assetName': cleanName,
          'assetType': asset['type'],
          'quantity': asset['quantity'],
          'price': asset['purchasePrice'],
          'totalCost': asset['totalCost'],
          'date': DateTime.parse(asset['purchaseDate'] as String),
          'addedAt': DateTime.parse(asset['addedAt'] as String),
        };
      }).toList();

      // Tarihe göre sırala (en yeni en üstte)
      transactions.sort(
        (a, b) =>
            (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime),
      );

      setState(() {
        _transactions = transactions;
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
          'İşlem Geçmişi',
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
          : _transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardDark,
              onRefresh: _loadTransactions,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItem(_transactions[index]);
                },
              ),
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
                Icons.history_outlined,
                size: 80,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Henüz İşlem Geçmişiniz Yok',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMainDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Herhangi bir işlem geçmişiniz bulunmuyor.\nVarlık ekleyerek işlem geçmişi oluşturabilirsiniz.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'Geri Dön',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final isBuy = type == 'buy';
    final assetName = transaction['assetName'] as String;
    final assetType = transaction['assetType'] as String;
    final quantity = (transaction['quantity'] as num).toDouble();
    final price = (transaction['price'] as num).toDouble();
    final totalCost = (transaction['totalCost'] as num).toDouble();
    final date = transaction['addedAt'] as DateTime;

    // Asset type'a göre icon ve renk
    IconData icon;
    Color iconColor;

    switch (assetType) {
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
      default:
        icon = Icons.account_balance_wallet;
        iconColor = AppColors.primary;
    }

    // Tarih formatı
    final now = DateTime.now();
    final difference = now.difference(date);
    String timeAgo;

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          timeAgo = 'Az önce';
        } else {
          timeAgo = '${difference.inMinutes} dakika önce';
        }
      } else {
        timeAgo = '${difference.inHours} saat önce';
      }
    } else if (difference.inDays == 1) {
      timeAgo = 'Dün';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      timeAgo = '$weeks hafta önce';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      timeAgo = '$months ay önce';
    } else {
      final years = (difference.inDays / 365).floor();
      timeAgo = '$years yıl önce';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              // Asset Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            assetName,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMainDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isBuy
                                ? AppColors.positiveDark.withOpacity(0.1)
                                : AppColors.negativeDark.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBuy ? 'ALIŞ' : 'SATIŞ',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isBuy
                                  ? AppColors.positiveDark
                                  : AppColors.negativeDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$assetType • $timeAgo',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transaction Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grayBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  'Miktar',
                  '${quantity.toStringAsFixed(2)} adet',
                ),
                Container(width: 1, height: 30, color: AppColors.borderDark),
                _buildDetailItem('Birim Fiyat', '₺${price.toStringAsFixed(2)}'),
                Container(width: 1, height: 30, color: AppColors.borderDark),
                _buildDetailItem(
                  'Toplam',
                  '₺${totalCost.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primary : AppColors.textMainDark,
          ),
        ),
      ],
    );
  }
}

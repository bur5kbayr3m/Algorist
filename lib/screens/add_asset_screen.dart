import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';
import '../services/email_verification_service.dart';
import '../theme/app_colors.dart';
import 'email_verification_screen.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  String _selectedAssetType = 'Hisse';
  final TextEditingController _assetNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _selectedDate;

  double _totalCost = 0.0;
  double _availableCash = 0.0;
  bool _isLoadingCash = true;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _loadAvailableCash();
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
      if (mounted && !_isEmailVerified) {
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
                  // İkon ve Başlık
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
                    'Varlık eklemek için önce email adresinizi doğrulamanız gerekmektedir. Bu işlem hesabınızın güvenliği için önemlidir.',
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
                              await _checkEmailVerification();
                            }
                          }
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

  Future<bool> _checkVerificationBeforeAction() async {
    if (!_isEmailVerified) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                'Email Doğrulaması Gerekli',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Varlık eklemek için email adresinizi doğrulamanız gerekmektedir.',
            style: GoogleFonts.manrope(
              color: const Color(0xFFE5E7EB),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context, false);
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final email = authProvider.currentUserEmail;
                if (email != null) {
                  final success = await EmailVerificationService.instance
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
                      await _checkEmailVerification();
                    }
                  }
                }
              },
              child: Text(
                'Şimdi Doğrula',
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Vazgeç',
                style: GoogleFonts.manrope(color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCash() async {
    setState(() => _isLoadingCash = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUser?['email'];

    if (userEmail != null) {
      final assets = await PortfolioService.instance.getUserAssets(userEmail);
      double totalCash = 0.0;

      // Nakit varlıklarını topla
      for (var asset in assets) {
        if (asset['type'] == 'Nakit') {
          totalCash += (asset['totalCost'] as num?)?.toDouble() ?? 0.0;
        }
      }

      setState(() {
        _availableCash = totalCash;
        _isLoadingCash = false;
      });
    } else {
      setState(() => _isLoadingCash = false);
    }
  }

  void _calculateTotalCost() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price =
        double.tryParse(
          _priceController.text.replaceAll('₺', '').replaceAll(',', ''),
        ) ??
        0;
    setState(() {
      _totalCost = quantity * price;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.onSurfaceDark,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addAsset() async {
    // Email doğrulama kontrolü
    if (!await _checkVerificationBeforeAction()) {
      return;
    }

    if (_assetNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen tüm alanları doldurun',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUser?['email'];

    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kullanıcı oturumu bulunamadı',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final asset = {
      'type': _selectedAssetType,
      'name': _assetNameController.text,
      'quantity': double.parse(_quantityController.text),
      'purchasePrice': double.parse(
        _priceController.text.replaceAll('₺', '').replaceAll(',', ''),
      ),
      'purchaseDate': _selectedDate!.toIso8601String(),
      'totalCost': _totalCost,
    };

    try {
      // Varlığı ekle
      await PortfolioService.instance.addAsset(userEmail, asset);

      // Nakitten düş
      await _deductCash(userEmail, _totalCost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Varlık başarıyla eklendi',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e', style: GoogleFonts.manrope()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _deductCash(String userEmail, double amount) async {
    try {
      // Tüm nakit varlıklarını getir
      final assets = await PortfolioService.instance.getUserAssets(userEmail);
      final cashAssets = assets
          .where((asset) => asset['type'] == 'Nakit')
          .toList();

      if (cashAssets.isEmpty || amount <= 0) {
        return; // Nakit yok veya düşülecek miktar yok
      }

      // Toplam nakiti hesapla
      double totalCash = 0.0;
      for (var asset in cashAssets) {
        totalCash += (asset['totalCost'] ?? 0.0);
      }

      if (totalCash < amount) {
        // Yeterli nakit yok, işlem yapma
        return;
      }

      // Nakit varlıklarını miktarlarına göre sırala (büyükten küçüğe)
      cashAssets.sort(
        (a, b) => (b['totalCost'] ?? 0.0).compareTo(a['totalCost'] ?? 0.0),
      );

      double remainingAmount = amount;

      for (var cashAsset in cashAssets) {
        if (remainingAmount <= 0) break;

        final cashAmount = (cashAsset['totalCost'] ?? 0.0) as double;

        if (cashAmount <= remainingAmount) {
          // Bu nakit varlığını tamamen sil
          await PortfolioService.instance.deleteAsset(cashAsset['assetId']);
          remainingAmount -= cashAmount;
        } else {
          // Bu nakit varlığından kısmi düş
          final newCashAmount = cashAmount - remainingAmount;
          final updatedAsset = Map<String, dynamic>.from(cashAsset);
          updatedAsset['totalCost'] = newCashAmount;
          updatedAsset['purchasePrice'] = newCashAmount;
          updatedAsset['quantity'] = 1.0;

          await PortfolioService.instance.updateAsset(
            cashAsset['assetId'],
            updatedAsset,
          );
          remainingAmount = 0;
        }
      }
    } catch (e) {
      print('❌ Error deducting cash: $e');
      // Hata durumunda sessizce devam et
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Mevcut Nakit Bilgisi
            _buildCashInfo(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildAssetTypeSelector(),
                    const SizedBox(height: 16),
                    _buildAssetNameField(),
                    const SizedBox(height: 16),
                    _buildQuantityAndPriceFields(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildTotalCostCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onSurfaceDark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Expanded(
            child: Text(
              'Yeni Varlık Ekle',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceDark,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildCashInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: _isLoadingCash
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mevcut Nakit',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppColors.onSurfaceDarkSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${_availableCash.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_totalCost > 0) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kalan',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.onSurfaceDarkSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${(_availableCash - _totalCost).toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (_availableCash - _totalCost) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAssetTypeSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypeButton('Hisse'),
          _buildTypeButton('Altın'),
          _buildTypeButton('Fon'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedAssetType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAssetType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryContainerDark
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              type,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.onSurfaceDark
                    : AppColors.onSurfaceDarkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetNameField() {
    String hintText;
    String labelText;

    switch (_selectedAssetType) {
      case 'Hisse':
        hintText = 'Örn: THYAO, GARAN, ISCTR';
        labelText = 'Hisse Kodu';
        break;
      case 'Altın':
        hintText = 'Gram Altın, Çeyrek Altın, vb.';
        labelText = 'Altın Türü';
        break;
      case 'Fon':
        hintText = 'Örn: YAF, GAF, İAF';
        labelText = 'Fon Kodu';
        break;
      default:
        hintText = 'Varlık Adı';
        labelText = 'Varlık Seçimi';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceDark,
          ),
        ),
        const SizedBox(height: 8),

        // Altın seçiliyse dropdown göster
        if (_selectedAssetType == 'Altın')
          _buildGoldTypeDropdown()
        else
          TextField(
            controller: _assetNameController,
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: AppColors.onSurfaceDark,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.manrope(
                color: AppColors.onSurfaceDarkSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              suffixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceDarkSecondary,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
      ],
    );
  }

  Widget _buildGoldTypeDropdown() {
    final goldTypes = [
      'Gram Altın',
      'Çeyrek Altın',
      'Yarım Altın',
      'Tam Altın',
      'Cumhuriyet Altını',
      'Ata Altın',
      'Reşat Altın',
      'Hamit Altın',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _assetNameController.text.isEmpty
              ? null
              : _assetNameController.text,
          hint: Text(
            'Altın Türü Seçin',
            style: GoogleFonts.manrope(
              color: AppColors.onSurfaceDarkSecondary,
              fontSize: 16,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.onSurfaceDarkSecondary,
          ),
          dropdownColor: AppColors.surfaceDark,
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: AppColors.onSurfaceDark,
          ),
          items: goldTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    Icons.paid_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _assetNameController.text = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuantityAndPriceFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adet / Miktar',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _calculateTotalCost(),
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: AppColors.onSurfaceDark,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.manrope(
                    color: AppColors.onSurfaceDarkSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birim Alış Fiyatı',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _calculateTotalCost(),
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: AppColors.onSurfaceDark,
                ),
                decoration: InputDecoration(
                  hintText: '₺0,00',
                  hintStyle: GoogleFonts.manrope(
                    color: AppColors.onSurfaceDarkSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alış Tarihi',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Tarih Seçin'
                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: _selectedDate == null
                          ? AppColors.onSurfaceDarkSecondary
                          : AppColors.onSurfaceDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.onSurfaceDarkSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toplam Maliyet',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceDarkSecondary,
            ),
          ),
          Text(
            '₺${_totalCost.toStringAsFixed(2)}',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _addAsset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Varlığı Ekle',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

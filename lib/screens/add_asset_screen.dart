import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/portfolio_service.dart';

class AppColors {
  // Primary Color (matching HTML #4b2bee)
  static const primary = Color(0xFF4B2BEE);

  // Background Colors
  static const backgroundDark = Color(0xFF131022);

  // Surface Colors
  static const surfaceDark = Color(0xFF1E293B); // slate-800/60

  // Text Colors
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceDarkSecondary = Color(0xFF9CA3AF); // gray-400

  // Primary Container
  static const primaryContainerDark = Color(0xFF3B1FC5); // darker primary
}

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

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
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
            dialogBackgroundColor: AppColors.surfaceDark,
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
      await PortfolioService.instance.addAsset(userEmail, asset);

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
        Navigator.pop(context, true); // true dönerek veri eklendiğini bildir
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

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

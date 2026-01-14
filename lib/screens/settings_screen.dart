import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/biometric_service.dart';
import '../services/database_service.dart';
import '../services/email_verification_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biyometrik Kimlik';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final biometricService = BiometricService.instance;
    final isAvailable = await biometricService.isBiometricAvailable();
    final isEnabled = await biometricService.isBiometricEnabled();

    if (isAvailable) {
      final types = await biometricService.getAvailableBiometrics();
      final typeName = biometricService.getBiometricTypeName(types);

      if (mounted) {
        setState(() {
          _biometricAvailable = isAvailable;
          _biometricEnabled = isEnabled;
          _biometricType = typeName;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final biometricService = BiometricService.instance;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final email = currentUser['email'] ?? '';

    final success = await biometricService.setBiometricEnabled(value);

    if (success) {
      await biometricService.saveBiometricPreference(email, value);
      if (value) {
        await biometricService.saveEmailForBiometric(email);
      } else {
        await biometricService.clearBiometricData();
      }

      if (mounted) {
        setState(() => _biometricEnabled = value);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '$_biometricType ile giriş aktif edildi'
                  : 'Biyometrik giriş kapatıldı',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Biyometrik kimlik doğrulama başarısız'
                  : 'Biyometrik giriş kapatılamadı',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = authProvider.currentUser;

    String userName = 'Kullanıcı';
    String userEmail = 'user@example.com';

    if (currentUser != null) {
      userEmail = currentUser['email'] ?? 'user@example.com';
      if (currentUser['fullName'] != null &&
          currentUser['fullName']!.isNotEmpty) {
        userName = currentUser['fullName']!;
      } else {
        final emailUsername = userEmail.split('@')[0];
        userName =
            emailUsername.substring(0, 1).toUpperCase() +
            emailUsername.substring(1);
      }
    }

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
          'Ayarlar',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Bilgileri
            _buildProfileSection(userName, userEmail),
            const SizedBox(height: 24),

            // Genel Ayarlar
            _buildSectionTitle('Genel'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.notifications_outlined,
              title: 'Bildirimler',
              subtitle: 'Push bildirimleri al',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                activeThumbColor: AppColors.primary,
              ),
            ),
            _buildSettingItem(
              icon: Icons.dark_mode_outlined,
              title: 'Koyu Tema',
              subtitle: themeProvider.isDarkMode
                  ? 'Karanlık mod aktif'
                  : 'Aydınlık mod aktif',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setTheme(value);
                },
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Güvenlik
            _buildSectionTitle('Güvenlik'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.fingerprint_outlined,
              title: 'Biyometrik Doğrulama',
              subtitle: _biometricAvailable
                  ? '$_biometricType ile giriş'
                  : 'Bu cihazda kullanılamıyor',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _biometricAvailable ? _toggleBiometric : null,
                activeThumbColor: AppColors.primary,
              ),
            ),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Şifre Değiştir',
              subtitle: 'Hesap şifrenizi güncelleyin',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            const SizedBox(height: 24),

            // Portföy Ayarları
            _buildSectionTitle('Portföy'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.currency_lira,
              title: 'Para Birimi',
              subtitle: 'Türk Lirası (₺)',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showCurrencyDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.sync_outlined,
              title: 'Otomatik Senkronizasyon',
              subtitle: 'Fiyatları otomatik güncelle',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showSyncSettingsDialog();
              },
            ),
            const SizedBox(height: 24),

            // Hakkında
            _buildSectionTitle('Hakkında'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Uygulama Hakkında',
              subtitle: 'Versiyon 1.0.0',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showAboutDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik Politikası',
              subtitle: 'Veri kullanımı ve gizlilik',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showPrivacyPolicyDialog();
              },
            ),
            _buildSettingItem(
              icon: Icons.description_outlined,
              title: 'Kullanım Koşulları',
              subtitle: 'Hizmet şartları',
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondaryDark,
                size: 18,
              ),
              onTap: () {
                _showTermsOfServiceDialog();
              },
            ),
            const SizedBox(height: 32),

            // Çıkış Yap
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B2BEE), Color(0xFF7C3AED)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName[0].toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondaryDark,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.grayBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMainDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textSecondaryDark,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
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
              'Çıkış Yap',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Çıkış Yap',
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

        if (confirm == true && mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.logout();
          // Navigator stack'i temizleyip ana ekrana dön
          // AuthWrapper otomatik olarak LoginScreen'e yönlendirecek
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.negativeDark.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.negativeDark.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.negativeDark, size: 22),
            const SizedBox(width: 12),
            Text(
              'Çıkış Yap',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.negativeDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.currentUser?['email'] ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsPasswordResetBottomSheet(
        email: userEmail,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Şifreniz başarıyla değiştirildi!',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showCurrencyDialog() {
    String selectedCurrency = 'TRY';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
          ),
          title: Text(
            'Para Birimi Seçin',
            style: GoogleFonts.manrope(
              color: AppColors.textMainDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyOption('TRY', '₺ Türk Lirası', selectedCurrency, (value) {
                setDialogState(() => selectedCurrency = value);
              }),
              _buildCurrencyOption('USD', '\$ ABD Doları', selectedCurrency, (value) {
                setDialogState(() => selectedCurrency = value);
              }),
              _buildCurrencyOption('EUR', '€ Euro', selectedCurrency, (value) {
                setDialogState(() => selectedCurrency = value);
              }),
              _buildCurrencyOption('GBP', '£ İngiliz Sterlini', selectedCurrency, (value) {
                setDialogState(() => selectedCurrency = value);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Para birimi $selectedCurrency olarak ayarlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Kaydet',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name, String selected, Function(String) onSelect) {
    final isSelected = code == selected;
    return InkWell(
      onTap: () => onSelect(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Text(
              name,
              style: GoogleFonts.manrope(
                color: isSelected ? AppColors.primary : AppColors.textMainDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSyncSettingsDialog() {
    bool autoSync = true;
    String syncInterval = '15';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
          ),
          title: Text(
            'Senkronizasyon Ayarları',
            style: GoogleFonts.manrope(
              color: AppColors.textMainDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Otomatik Senkronizasyon',
                  style: GoogleFonts.manrope(color: AppColors.textMainDark),
                ),
                subtitle: Text(
                  'Fiyatları otomatik güncelle',
                  style: GoogleFonts.manrope(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
                trailing: Switch(
                  value: autoSync,
                  onChanged: (value) => setDialogState(() => autoSync = value),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Güncelleme Sıklığı',
                style: GoogleFonts.manrope(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['5', '15', '30', '60'].map((interval) {
                  final isSelected = interval == syncInterval;
                  return InkWell(
                    onTap: () => setDialogState(() => syncInterval = interval),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderDark,
                        ),
                      ),
                      child: Text(
                        '${interval}dk',
                        style: GoogleFonts.manrope(
                          color: isSelected ? AppColors.primary : AppColors.textMainDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Senkronizasyon her $syncInterval dakikada bir yapılacak'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Kaydet',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Gizlilik Politikası',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPolicySection('Veri Toplama', 
                'Algorist, yalnızca uygulama işlevselliği için gerekli olan verileri toplar. Bu veriler arasında portföy bilgileriniz, kullanıcı tercihleri ve anonim kullanım istatistikleri yer alır.'),
              _buildPolicySection('Veri Kullanımı', 
                'Toplanan veriler, size kişiselleştirilmiş bir deneyim sunmak, uygulama performansını iyileştirmek ve güvenliğinizi sağlamak için kullanılır.'),
              _buildPolicySection('Veri Güvenliği', 
                'Verileriniz, endüstri standardı şifreleme protokolleri ile korunur. Üçüncü taraflarla açık izniniz olmadan paylaşılmaz.'),
              _buildPolicySection('Haklarınız', 
                'Verilerinize erişim, düzeltme veya silme hakkına sahipsiniz. Bu hakları kullanmak için destek ekibimizle iletişime geçebilirsiniz.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Anladım',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Kullanım Koşulları',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPolicySection('Kabul', 
                'Algorist uygulamasını kullanarak bu kullanım koşullarını kabul etmiş olursunuz.'),
              _buildPolicySection('Hizmet Kapsamı', 
                'Algorist, portföy yönetimi ve takibi için araçlar sunar. Uygulama yatırım tavsiyesi vermez ve finansal danışmanlık hizmeti sunmaz.'),
              _buildPolicySection('Kullanıcı Sorumlulukları', 
                'Hesap bilgilerinizin güvenliğinden siz sorumlusunuz. Uygulamayı yasadışı amaçlarla kullanmayacağınızı taahhüt edersiniz.'),
              _buildPolicySection('Sorumluluk Sınırı', 
                'Algorist, uygulamanın kullanımından kaynaklanan doğrudan veya dolaylı zararlardan sorumlu tutulamaz. Tüm yatırım kararları kullanıcının sorumluluğundadır.'),
              _buildPolicySection('Değişiklikler', 
                'Bu koşulları önceden haber vermeksizin değiştirme hakkımız saklıdır. Güncel koşulları düzenli olarak kontrol etmeniz önerilir.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Anladım',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.manrope(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    final nameController = TextEditingController(
      text: currentUser?['fullName'] ?? '',
    );
    final emailController = TextEditingController(
      text: currentUser?['email'] ?? '',
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Profili Düzenle',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.manrope(color: AppColors.textMainDark),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  labelStyle: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: AppColors.textSecondaryDark),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: false,
                style: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.cardDark.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: AppColors.textSecondaryDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'E-posta adresi değiştirilemez',
                style: GoogleFonts.manrope(
                  color: AppColors.textSecondaryDark.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ad Soyad boş olamaz'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              await authProvider.updateUserProfile(
                fullName: nameController.text,
              );
              
              if (mounted) {
                Navigator.pop(context);
                setState(() {}); // Profil bölümünü yenile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil başarıyla güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Kaydet',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderDark.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4B2BEE), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Algorist',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versiyon 1.0.0',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Algorist, portföy yönetimini kolaylaştıran, AI destekli analizler sunan modern bir finans uygulamasıdır.',
              style: GoogleFonts.manrope(
                color: AppColors.textMainDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Algorist. Tüm hakları saklıdır.',
              style: GoogleFonts.manrope(
                color: AppColors.textSecondaryDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Tamam',
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
  }
}

// Şifre Sıfırlama Bottom Sheet Widget (Settings için)
class _SettingsPasswordResetBottomSheet extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const _SettingsPasswordResetBottomSheet({
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_SettingsPasswordResetBottomSheet> createState() =>
      _SettingsPasswordResetBottomSheetState();
}

class _SettingsPasswordResetBottomSheetState extends State<_SettingsPasswordResetBottomSheet> {
  int _currentStep = 0; // 0: Yöntem seç, 1: Kod gir, 2: Yeni şifre
  String _selectedMethod = 'email'; // email veya sms
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_selectedMethod == 'email') {
        final success = await EmailVerificationService.instance
            .sendVerificationCode(widget.email);
        if (!success) {
          throw Exception('Kod gönderilemedi');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedMethod == 'email'
                  ? '📧 Doğrulama kodu email adresinize gönderildi'
                  : '📱 Doğrulama kodu telefonunuza gönderildi',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kod gönderilemedi: $e';
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = 'Lütfen 6 haneli kodu girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await EmailVerificationService.instance.verifyCode(
        widget.email,
        _codeController.text,
      );

      if (isValid) {
        setState(() {
          _isLoading = false;
          _currentStep = 2;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Geçersiz kod. Lütfen tekrar deneyin.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Doğrulama hatası: $e';
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DatabaseService.instance.updateUserPassword(
        widget.email,
        _newPasswordController.text,
      );

      await NotificationService.instance.showSecurityAlert(
        title: 'Şifre Değiştirildi',
        body:
            'Hesabınızın şifresi başarıyla değiştirildi. Bu işlemi siz yapmadıysanız lütfen bizimle iletişime geçin.',
      );

      await NotificationService.instance.sendEmail(
        to: widget.email,
        subject: 'Algorist - Şifreniz Değiştirildi',
        body:
            '''
Merhaba,

Algorist hesabınızın şifresi başarıyla değiştirildi.

Değişiklik Tarihi: ${DateTime.now().toLocal().toString().split('.')[0]}

Bu işlemi siz yapmadıysanız, lütfen hemen bizimle iletişime geçin.

Güvenliğiniz bizim için önemli.

Algorist Ekibi
        ''',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Şifre değiştirilemedi: $e';
        });
      }
    }
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
              // Handle bar
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

              // Title
              Text(
                _currentStep == 0
                    ? 'Şifre Sıfırlama'
                    : _currentStep == 1
                    ? 'Doğrulama Kodu'
                    : 'Yeni Şifre',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentStep == 0
                    ? 'Doğrulama kodunu nasıl almak istersiniz?'
                    : _currentStep == 1
                    ? '${_selectedMethod == 'email' ? widget.email : 'Telefonunuza'} gönderilen 6 haneli kodu girin'
                    : 'Yeni şifrenizi belirleyin',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.manrope(fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Step 0: Method Selection
              if (_currentStep == 0) ...[
                _buildMethodOption(
                  icon: Icons.email_outlined,
                  title: 'Email ile',
                  subtitle: widget.email,
                  value: 'email',
                ),
                const SizedBox(height: 12),
                _buildMethodOption(
                  icon: Icons.phone_android,
                  title: 'SMS ile',
                  subtitle: 'Kayıtlı telefon numaranıza',
                  value: 'sms',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Kod Gönder',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              // Step 1: Code Input
              if (_currentStep == 1) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.2),
                      letterSpacing: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    child: Text(
                      'Kodu Tekrar Gönder',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Doğrula',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              // Step 2: New Password
              if (_currentStep == 2) ...[
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  style: GoogleFonts.manrope(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    labelStyle: GoogleFonts.manrope(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: GoogleFonts.manrope(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    labelStyle: GoogleFonts.manrope(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Şifreyi Değiştir',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
                size: 24,
              ),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

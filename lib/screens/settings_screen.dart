import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/biometric_service.dart';
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
                // Şifre değiştirme
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
                // Para birimi seçimi
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
                // Senkronizasyon ayarları
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
                // Gizlilik politikası
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
                // Kullanım koşulları
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
              // Profil düzenleme
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

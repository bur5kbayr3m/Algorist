import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/email_verification_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'email_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImagePath;
  bool _isEmailVerified = false;

  // Tercihler için state değişkenler
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _darkModeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkEmailVerification();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?['email'];
    if (email != null) {
      final prefs = await DatabaseService.instance.getUserPreferences(email);
      if (mounted && prefs != null) {
        setState(() {
          _pushNotificationsEnabled = prefs['pushNotifications'] ?? true;
          _emailNotificationsEnabled = prefs['emailNotifications'] ?? false;
          _darkModeEnabled = prefs['darkMode'] ?? true;
        });
      }
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?['email'];
    if (email != null) {
      await DatabaseService.instance.saveUserPreference(email, key, value);
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      _emailController.text = currentUser['email'] ?? '';
      _fullNameController.text = currentUser['fullName'] ?? '';
      _phoneController.text = currentUser['phone'] ?? '';
      _profileImagePath = currentUser['profileImage'];
    }
  }

  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?['email'];
    if (email != null) {
      final isVerified = await EmailVerificationService.instance
          .isEmailVerified(email);
      if (mounted) {
        setState(() {
          _isEmailVerified = isVerified;
        });
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.currentUser?['email'];

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email adresi bulunamadı',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await EmailVerificationService.instance
          .sendVerificationCode(email);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // Verification screen'e git
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: email),
          ),
        );

        // Başarılı doğrulama sonrası
        if (result == true) {
          await _checkEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Email başarıyla doğrulandı!',
                  style: GoogleFonts.manrope(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Doğrulama kodu gönderilemedi',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e', style: GoogleFonts.manrope()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Profil Fotoğrafı Seç',
            style: GoogleFonts.manrope(color: AppColors.textMainDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(
                  'Galeriden Seç',
                  style: GoogleFonts.manrope(color: AppColors.textMainDark),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.manrope(color: AppColors.textMainDark),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf seçilirken hata: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fotoğraf çekilirken hata: $e',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.currentUser?['email'];

      if (userEmail != null) {
        await DatabaseService.instance.updateUserProfile(
          userEmail,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          profileImage: _profileImagePath,
        );

        // Auth provider'ı güncelle
        final updatedUser = await DatabaseService.instance.getUserByEmail(
          userEmail,
        );
        if (updatedUser != null) {
          authProvider.updateCurrentUser(updatedUser);
        }
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil başarıyla güncellendi',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e', style: GoogleFonts.manrope()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textMainDark),
          onPressed: () => Navigator.pop(context, 'openDrawer'),
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMainDark,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Kaydet',
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileHeader(userName, userEmail),
              const SizedBox(height: 32),
              _buildInfoSection(),
              const SizedBox(height: 24),
              _buildSecuritySection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.person, color: AppColors.primary, size: 50),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userEmail,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              if (_isEmailVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Doğrulandı',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (!_isEmailVerified) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendVerificationEmail,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.email_outlined, size: 18),
              label: Text(
                'Email Doğrula',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kişisel Bilgiler',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _fullNameController,
            label: 'Ad Soyad',
            icon: Icons.person_outline,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ad soyad boş olamaz';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'E-posta',
            icon: Icons.email_outlined,
            enabled: false, // Email değiştirilemez
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Telefon',
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Güvenlik',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),
          // Şifre Değiştir Butonu
          GestureDetector(
            onTap: _showPasswordResetDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şifre Değiştir',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMainDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email veya SMS ile doğrulama kodu alın',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondaryDark,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PasswordResetBottomSheet(
        email: _emailController.text,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.manrope(
        color: enabled ? AppColors.textMainDark : AppColors.textSecondaryDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(color: AppColors.textSecondaryDark),
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textSecondaryDark,
        ),
        filled: true,
        fillColor: enabled
            ? AppColors.backgroundDark
            : AppColors.backgroundDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {
              'assetCount': 0,
              'totalValue': 0.0,
              'membershipDays': 0,
              'transactionCount': 0,
            };

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İstatistikler',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMainDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Toplam Varlık',
                      '${stats['assetCount'] ?? 0}',
                      Icons.account_balance_wallet,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Toplam Değer',
                      '₺${_formatNumber(stats['totalValue'] ?? 0.0)}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Üyelik',
                      '${stats['membershipDays'] ?? 0} Gün',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'İşlemler',
                      '${stats['transactionCount'] ?? 0}',
                      Icons.swap_horiz,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadUserStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.currentUserEmail;

      if (userEmail == null) {
        return {
          'assetCount': 0,
          'totalValue': 0.0,
          'membershipDays': 0,
          'transactionCount': 0,
        };
      }

      // Get assets
      final assets = await DatabaseService.instance.getUserAssets(userEmail);
      final assetCount = assets.length;
      final totalValue = assets.fold<double>(
        0.0,
        (sum, asset) => sum + ((asset['totalCost'] as num?)?.toDouble() ?? 0.0),
      );

      // Get user creation date
      final user = await DatabaseService.instance.getUserByEmail(userEmail);
      int membershipDays = 0;
      if (user != null && user['createdAt'] != null) {
        final createdAt = DateTime.parse(user['createdAt'] as String);
        membershipDays = DateTime.now().difference(createdAt).inDays;
      }

      // Transaction count = asset count (for now)
      final transactionCount = assetCount;

      return {
        'assetCount': assetCount,
        'totalValue': totalValue,
        'membershipDays': membershipDays,
        'transactionCount': transactionCount,
      };
    } catch (e) {
      print('Error loading user stats: $e');
      return {
        'assetCount': 0,
        'totalValue': 0.0,
        'membershipDays': 0,
        'transactionCount': 0,
      };
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tercihler',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildPreferenceItem(
            'Bildirimler',
            'Push bildirimleri al',
            Icons.notifications_outlined,
            _pushNotificationsEnabled,
            (value) async {
              setState(() => _pushNotificationsEnabled = value);
              await _savePreference('pushNotifications', value);
              if (value) {
                // Bildirim izni iste
                await NotificationService.instance.requestPermissions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Push bildirimleri aktif edildi',
                        style: GoogleFonts.manrope(),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🔕 Push bildirimleri kapatıldı',
                        style: GoogleFonts.manrope(),
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(color: AppColors.borderDark, height: 32),
          _buildPreferenceItem(
            'E-posta Bildirimleri',
            'E-posta ile bildirim al',
            Icons.email_outlined,
            _emailNotificationsEnabled,
            (value) async {
              setState(() => _emailNotificationsEnabled = value);
              await _savePreference('emailNotifications', value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '✅ E-posta bildirimleri aktif edildi'
                          : '📧 E-posta bildirimleri kapatıldı',
                      style: GoogleFonts.manrope(),
                    ),
                    backgroundColor: value ? Colors.green : Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const Divider(color: AppColors.borderDark, height: 32),
          _buildPreferenceItem(
            'Karanlık Mod',
            'Karanlık tema kullan',
            Icons.dark_mode_outlined,
            _darkModeEnabled,
            (value) async {
              setState(() => _darkModeEnabled = value);
              await _savePreference('darkMode', value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '🌙 Karanlık mod aktif'
                          : '☀️ Açık mod için uygulama yeniden başlatılmalı',
                      style: GoogleFonts.manrope(),
                    ),
                    backgroundColor: value ? AppColors.primary : Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
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
                  color: AppColors.textMainDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

// Şifre Sıfırlama Bottom Sheet Widget
class _PasswordResetBottomSheet extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const _PasswordResetBottomSheet({
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_PasswordResetBottomSheet> createState() =>
      _PasswordResetBottomSheetState();
}

class _PasswordResetBottomSheetState extends State<_PasswordResetBottomSheet> {
  int _currentStep = 0; // 0: Yöntem seç, 1: Kod gir, 2: Yeni şifre
  String _selectedMethod = 'email'; // email veya sms
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  // Doğrulama kodu EmailVerificationService tarafından yönetiliyor
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
      // Email ile gönderme simülasyonu
      await Future.delayed(const Duration(seconds: 1));

      if (_selectedMethod == 'email') {
        // EmailVerificationService kullanarak kod gönder
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
      // Kodu doğrula
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
      // Şifreyi güncelle
      await DatabaseService.instance.updateUserPassword(
        widget.email,
        _newPasswordController.text,
      );

      // Güvenlik bildirimi gönder (hem push hem email)
      await NotificationService.instance.showSecurityAlert(
        title: 'Şifre Değiştirildi',
        body:
            'Hesabınızın şifresi başarıyla değiştirildi. Bu işlemi siz yapmadıysanız lütfen bizimle iletişime geçin.',
      );

      // Email ile de bildir
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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.red,
                          ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                    labelStyle: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () => setState(
                        () => _isNewPasswordVisible = !_isNewPasswordVisible,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: GoogleFonts.manrope(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    labelStyle: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
            color: isSelected
                ? AppColors.primary
                : Colors.white.withOpacity(0.1),
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
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.5),
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
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.3),
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

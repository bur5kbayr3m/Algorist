import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_provider.dart';
import '../login_screen.dart';
import '../services/sms_service.dart';
import 'otp_verification_screen.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Telefon numarası şu an kullanılmıyor
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler eşleşmiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen telefon numaranızı girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // SMS gönder
      final smsSent = await SmsService.instance.sendOtp(_completePhoneNumber);

      if (!smsSent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS gönderilemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Debug mode'da OTP'yi göster
      if (mounted) {
        final debugOtp = SmsService.instance.getOtpForTesting(
          _completePhoneNumber,
        );
        if (debugOtp != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DEBUG: SMS Kodu = $debugOtp'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // OTP doğrulama ekranına git
      if (mounted) {
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: _completePhoneNumber,
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
            ),
          ),
        );

        // OTP doğrulandıysa kayıt işlemini tamamla
        if (verified == true && mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          final success = await authProvider.register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _completePhoneNumber,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
                backgroundColor: Colors.green,
              ),
            );
            // Login ekranına dön
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Kayıt başarısız'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = AppColors.backgroundDark;

    final cardColor = isDarkMode
        ? AppColors.slate900.withOpacity(0.5)
        : Colors.white;

    final titleColor = isDarkMode ? Colors.white : AppColors.slate900;
    final subtitleColor = isDarkMode ? AppColors.slate400 : AppColors.slate600;
    final labelColor = isDarkMode ? AppColors.slate200 : AppColors.slate800;
    final inputBgColor = isDarkMode
        ? AppColors.slate800.withOpacity(0.6)
        : AppColors.slate200.withOpacity(0.3);
    final inputBorderColor = isDarkMode
        ? AppColors.slate800
        : AppColors.slate300;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        'Algorist',
                        style: GoogleFonts.manrope(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Kayıt Kartı
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.slate800
                            : AppColors.slate200,
                      ),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Başlık
                          Text(
                            'Hesap Oluştur',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yapay zeka destekli portföy yönetimine başlayın.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ad Soyad
                          _buildLabel('Ad Soyad', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            style: GoogleFonts.manrope(color: titleColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ad soyad gerekli';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              hintText: 'Adınız Soyadınız',
                              fillColor: inputBgColor,
                              borderColor: inputBorderColor,
                              hintColor: isDarkMode
                                  ? AppColors.slate500
                                  : AppColors.slate400,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // E-posta
                          _buildLabel('E-posta', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.manrope(color: titleColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta gerekli';
                              }
                              if (!value.contains('@')) {
                                return 'Geçerli bir e-posta girin';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              hintText: 'eposta@adresiniz.com',
                              fillColor: inputBgColor,
                              borderColor: inputBorderColor,
                              hintColor: isDarkMode
                                  ? AppColors.slate500
                                  : AppColors.slate400,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Telefon Numarası
                          _buildLabel('Telefon Numarası', labelColor),
                          const SizedBox(height: 6),
                          IntlPhoneField(
                            decoration: InputDecoration(
                              hintText: '5XX XXX XX XX',
                              hintStyle: GoogleFonts.manrope(
                                color: isDarkMode
                                    ? AppColors.slate500
                                    : AppColors.slate400,
                              ),
                              filled: true,
                              fillColor: inputBgColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.manrope(color: titleColor),
                            dropdownTextStyle: GoogleFonts.manrope(
                              color: titleColor,
                            ),
                            initialCountryCode: 'TR',
                            onChanged: (phone) {
                              _completePhoneNumber = phone.completeNumber;
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return 'Telefon numarası gerekli';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Şifre
                          _buildLabel('Şifre', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: GoogleFonts.manrope(color: titleColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre gerekli';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalı';
                              }
                              return null;
                            },
                            decoration:
                                _buildInputDecoration(
                                  hintText: '••••••••',
                                  fillColor: inputBgColor,
                                  borderColor: inputBorderColor,
                                  hintColor: isDarkMode
                                      ? AppColors.slate500
                                      : AppColors.slate400,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: isDarkMode
                                          ? AppColors.slate400
                                          : AppColors.slate500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                          ),

                          const SizedBox(height: 16),

                          // Şifre Tekrar
                          _buildLabel('Şifre Tekrar', labelColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: GoogleFonts.manrope(color: titleColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre tekrarı gerekli';
                              }
                              return null;
                            },
                            decoration:
                                _buildInputDecoration(
                                  hintText: '••••••••',
                                  fillColor: inputBgColor,
                                  borderColor: inputBorderColor,
                                  hintColor: isDarkMode
                                      ? AppColors.slate500
                                      : AppColors.slate400,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: isDarkMode
                                          ? AppColors.slate400
                                          : AppColors.slate500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                          ),

                          const SizedBox(height: 24),

                          // Kayıt Ol Butonu
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _handleRegister(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Kayıt Ol'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Giriş Yap Link
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                      children: [
                        const TextSpan(text: 'Zaten hesabın var mı? '),
                        TextSpan(
                          text: 'Giriş Yap',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? AppColors.primary
                                : AppColors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.manrope(color: hintColor),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

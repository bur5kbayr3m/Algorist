import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/portfolio_screen.dart';
import 'screens/register_screen.dart';
import 'theme/app_colors.dart';

// --- GOOGLE ICON SVG ---
const String googleIconSvg =
    '''<svg class="h-5 w-5" fill="none" viewbox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M22.5777 12.2478C22.5777 11.4333 22.5084 10.6377 22.3783 9.87329H12.2045V14.332H18.1793C17.9103 15.9388 17.078 17.3396 15.8239 18.2561V21.094H19.7523C21.5794 19.4262 22.5777 16.9467 22.5777 12.2478Z" fill="#4285F4"></path><path d="M12.2045 22.9999C15.2289 22.9999 17.7493 22.0159 19.7523 20.094L15.8239 18.2561C14.8543 18.892 13.6288 19.2974 12.2045 19.2974C9.37512 19.2974 6.94586 17.4391 6.04834 14.8858H2.00098V17.8189C3.99616 21.313 7.78579 22.9999 12.2045 22.9999Z" fill="#34A853"></path><path d="M6.04846 14.8858C5.83383 14.2498 5.70776 13.5786 5.70776 12.8888C5.70776 12.199 5.83383 11.5278 6.04846 10.8918V7.95874H2.0011C1.25833 9.49522 0.833496 11.1565 0.833496 12.8888C0.833496 14.6211 1.25833 16.2824 2.0011 17.8189L6.04846 14.8858Z" fill="#FBBC05"></path><path d="M12.2045 5.48032C13.7518 5.48032 15.0594 6.01208 15.7766 6.69187L19.8252 2.72302C17.7415 0.963856 15.2211 0 12.2045 0C7.78579 0 3.99616 2.68686 2.00098 6.18114L6.04834 9.11419C6.94586 6.56094 9.37512 5.48032 12.2045 5.48032Z" fill="#EA4335"></path></svg>''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PortfolioScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Giriş başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PortfolioScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google girişi başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema kontrolü (Karanlık/Aydınlık mod tespiti)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Arkaplan Rengi (HTML: bg-background-light dark:bg-background-dark)
    final backgroundColor = AppColors.backgroundDark;

    // Kart Arkaplanı (HTML: bg-white dark:bg-slate-900/50)
    final cardColor = isDarkMode
        ? AppColors.slate900.withOpacity(0.5)
        : Colors.white;

    // Metin Renkleri
    final titleColor = isDarkMode ? Colors.white : AppColors.slate900;
    final subtitleColor = isDarkMode ? AppColors.slate400 : AppColors.slate600;
    final labelColor = isDarkMode ? AppColors.slate200 : AppColors.slate800;
    final inputBgColor = isDarkMode
        ? AppColors.slate800.withOpacity(0.6)
        : Colors.grey[100];
    final inputBorderColor = isDarkMode
        ? AppColors.slate600
        : AppColors.slate300;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // p-4 sm:p-6
          child: ConstrainedBox(
            // HTML: max-w-md (Yaklaşık 448px)
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ALANI ---
                // "Algorist" yazısı gradient efektiyle
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0), // mb-8
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.primary, AppColors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'Algorist',
                      style: GoogleFonts.manrope(
                        fontSize: 48, // text-5xl (yaklaşık)
                        fontWeight: FontWeight.w800, // font-extrabold
                        letterSpacing: -1.5, // tracking-tighter
                        color:
                            Colors.white, // ShaderMask için beyaz zemin gerekir
                      ),
                    ),
                  ),
                ),

                // --- GİRİŞ KARTI ---
                Container(
                  padding: const EdgeInsets.all(24.0), // p-6 sm:p-8
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.0), // rounded-xl
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
                        // Başlıklar
                        Text(
                          'Hesabınıza Giriş Yapın',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 24, // text-2xl
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                            letterSpacing: -0.5, // tracking-tight
                          ),
                        ),
                        const SizedBox(height: 8), // mt-2
                        Text(
                          'Yapay zeka ile portföyünüzü yönetin.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),

                        const SizedBox(height: 24), // space-y-4 boşluğu
                        // --- FORM ALANI ---

                        // E-posta Input
                        _buildLabel('E-posta', labelColor),
                        const SizedBox(height: 6), // mb-1.5
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
                            fillColor: inputBgColor!,
                            borderColor: inputBorderColor,
                            hintColor: isDarkMode
                                ? AppColors.slate500
                                : AppColors.slate400,
                          ),
                        ),

                        const SizedBox(height: 16), // space-y-4
                        // Şifre Input
                        _buildLabel('Şifre', labelColor),
                        const SizedBox(height: 6), // mb-1.5
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
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                        ),

                        const SizedBox(height: 24), // mt-6
                        // --- GİRİŞ BUTONU ---
                        SizedBox(
                          height: 48, // h-12
                          child: ElevatedButton(
                            onPressed: () => _handleLogin(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8.0,
                                ), // rounded-lg
                              ),
                              textStyle: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Giriş Yap'),
                          ),
                        ),

                        const SizedBox(height: 20), // mt-5
                        // Şifremi Unuttum
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Şifreni mi unuttun?',
                              style: GoogleFonts.manrope(
                                color: isDarkMode
                                    ? AppColors.primary
                                    : AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- VEYA AYIRACI ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0), // my-6
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDarkMode
                              ? AppColors.slate800
                              : AppColors.slate200,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Veya',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? AppColors.slate400
                                : AppColors.slate500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDarkMode
                              ? AppColors.slate800
                              : AppColors.slate200,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- GOOGLE BUTONU ---
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: SvgPicture.string(
                      googleIconSvg,
                      height: 20,
                      width: 20,
                    ),
                    label: Text(
                      'Google ile Devam Et',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? AppColors.slate900.withOpacity(0.5)
                          : Colors.white,
                      side: BorderSide(
                        color: isDarkMode
                            ? AppColors.slate800
                            : AppColors.slate300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32), // mt-8
                // --- KAYIT OL LINK ---
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                    children: [
                      const TextSpan(text: 'Hesabın yok mu? '),
                      TextSpan(
                        text: 'Kayıt Ol',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.primary
                              : AppColors.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
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
    );
  }

  // Yardımcı Metot: Label (Etiket) Oluşturucu
  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  // Yardımcı Metot: Input Dekorasyonu
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

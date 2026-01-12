import 'package:algorist/login_screen.dart';
import 'package:algorist/screens/portfolio_screen.dart';
import 'package:algorist/screens/onboarding_screen.dart';
import 'package:algorist/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  // Hızlı başlangıç için binding'i optimize et
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Bildirim servisini arkaplanda başlat (await kullanma!)
  NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Algorist',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const AuthWrapper(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4F46E5),
        surface: Color(0xFFFFFFFF),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0A12),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4F46E5),
        surface: Color(0xFF1E293B),
      ),
      useMaterial3: true,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(Duration.zero);
    if (mounted) {
      context.read<AuthProvider>().checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B0A12),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
                strokeWidth: 3,
              ),
            ),
          );
        }

        return FutureBuilder<bool>(
          future: _checkOnboarding(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B0A12),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4F46E5),
                  ),
                ),
              );
            }

            bool onboardingComplete = snapshot.data ?? false;

            if (authProvider.isLoggedIn) {
              return const PortfolioScreen();
            } else {
              return onboardingComplete ? const LoginScreen() : const OnboardingScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
